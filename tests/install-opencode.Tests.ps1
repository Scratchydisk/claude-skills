<#
.SYNOPSIS
Pester black-box + unit tests for scripts/install-opencode.ps1 — the
Windows/PowerShell counterpart to tests/test-install-opencode.sh.

Black-box cases (spawned as a real child process, exercising real
filesystem symlinks — this works unprivileged on Linux/macOS and is how
these tests were actually run and verified) mirror the bash suite's fresh
install, idempotent KEEP, managed relative/absolute links, all four
collision kinds, the HOME/XDG_CONFIG_HOME fallback with spaces in paths,
and dry-run non-mutation.

The bash suite's "link creation failure" case works by shadowing the `ln`
binary on PATH — this script calls New-Item directly rather than shelling
out, so there is no external binary to shadow. The equivalent coverage
here is function-level: Pester Mock on New-Item, which also lets us
exercise the Windows-specific symlink-fails/junction-succeeds fallback
path that cannot be forced for real on this (non-Windows) dev machine.

Run with:
    Invoke-Pester -Path tests/install-opencode.Tests.ps1
#>

BeforeAll {
    $script:ScriptPath = (Resolve-Path (Join-Path $PSScriptRoot '..' 'scripts' 'install-opencode.ps1')).ProviderPath
    . $script:ScriptPath
    $script:PwshExe = (Get-Process -Id $PID).Path

    function New-FixtureCheckout {
        # Mirrors the bash suite's make_checkout: a self-contained fake
        # repository, including its OWN copy of the script under test, so
        # the script's $PSCommandPath-derived root is the fixture, never
        # this real repository.
        param([string]$Checkout)
        New-Item -ItemType Directory -Path (Join-Path $Checkout 'skills/alpha') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $Checkout 'skills/beta') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $Checkout 'skills/alpha/SKILL.md') -Value 'alpha'
        Set-Content -LiteralPath (Join-Path $Checkout 'skills/beta/SKILL.md') -Value 'beta'
        New-Item -ItemType Directory -Path (Join-Path $Checkout 'scripts') -Force | Out-Null
        Copy-Item -LiteralPath $script:ScriptPath -Destination (Join-Path $Checkout 'scripts/install-opencode.ps1')
    }

    function Invoke-InstallerProcess {
        param(
            [string]$Checkout,
            [string]$ConfigHome,
            [string[]]$ScriptArgs = @(),
            [switch]$UseHomeFallback,
            [string[]]$PathPrepend = @()
        )
        $checkoutScript = Join-Path $Checkout 'scripts/install-opencode.ps1'
        $psi = [System.Diagnostics.ProcessStartInfo]::new()
        $psi.FileName = $script:PwshExe
        foreach ($a in @('-NoProfile', '-NonInteractive', '-File', $checkoutScript) + $ScriptArgs) {
            $psi.ArgumentList.Add($a)
        }
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.UseShellExecute = $false
        $psi.WorkingDirectory = $Checkout

        if ($UseHomeFallback) {
            $psi.Environment.Remove('XDG_CONFIG_HOME') | Out-Null
            $psi.Environment['HOME'] = $ConfigHome
        }
        else {
            $psi.Environment['XDG_CONFIG_HOME'] = $ConfigHome
        }
        if ($PathPrepend.Count -gt 0) {
            $sep = [System.IO.Path]::PathSeparator
            $psi.Environment['PATH'] = ($PathPrepend -join $sep) + $sep + $psi.Environment['PATH']
        }

        $proc = [System.Diagnostics.Process]::Start($psi)
        $stdout = $proc.StandardOutput.ReadToEnd()
        $stderr = $proc.StandardError.ReadToEnd()
        $proc.WaitForExit()
        return [pscustomobject]@{ ExitCode = $proc.ExitCode; Stdout = $stdout; Stderr = $stderr }
    }

    function Get-DestinationDir {
        param([string]$ConfigHome, [switch]$UseHomeFallback)
        if ($UseHomeFallback) {
            return Join-Path (Join-Path (Join-Path $ConfigHome '.config') 'opencode') 'skills'
        }
        return Join-Path (Join-Path $ConfigHome 'opencode') 'skills'
    }
}

Describe 'install-opencode.ps1 (CLI contract, real filesystem)' {

    It 'links every skill on a fresh install, then keeps them on a second run' {
        $checkout = Join-Path $TestDrive 'fresh/checkout'
        $config = Join-Path $TestDrive 'fresh/config'
        New-FixtureCheckout -Checkout $checkout

        $first = Invoke-InstallerProcess -Checkout $checkout -ConfigHome $config
        $first.ExitCode | Should -Be 0
        $destDir = Get-DestinationDir -ConfigHome $config
        foreach ($id in 'alpha', 'beta') {
            $destination = Join-Path $destDir $id
            $first.Stdout | Should -Match "LINK: ${id}: $([regex]::Escape($destination))"
            $linkItem = Get-Item -LiteralPath $destination -Force
            $linkItem.LinkType | Should -Be 'SymbolicLink'
            # Resolve-Path normalizes path syntax but does not dereference a
            # symlink (unlike bash's readlink -f) — read the reparse point's
            # own recorded target instead, which the installer always sets
            # to an already-canonical absolute path.
            $resolved = $linkItem.Target | Select-Object -First 1
            $expected = (Resolve-Path -LiteralPath (Join-Path $checkout "skills/$id")).ProviderPath
            $resolved | Should -Be $expected
        }

        $second = Invoke-InstallerProcess -Checkout $checkout -ConfigHome $config
        $second.ExitCode | Should -Be 0
        foreach ($id in 'alpha', 'beta') {
            $second.Stdout | Should -Match "KEEP: ${id}: "
        }
    }

    It 'keeps pre-existing managed relative and absolute links' {
        $checkout = Join-Path $TestDrive 'managed/checkout'
        $config = Join-Path $TestDrive 'managed/config'
        New-FixtureCheckout -Checkout $checkout
        $destDir = Get-DestinationDir -ConfigHome $config
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null

        $canonicalAlpha = (Resolve-Path -LiteralPath (Join-Path $checkout 'skills/alpha')).ProviderPath
        $canonicalBeta = (Resolve-Path -LiteralPath (Join-Path $checkout 'skills/beta')).ProviderPath
        New-Item -ItemType SymbolicLink -Path (Join-Path $destDir 'alpha') -Target $canonicalAlpha | Out-Null
        New-Item -ItemType SymbolicLink -Path (Join-Path $destDir 'beta') -Target $canonicalBeta | Out-Null

        $result = Invoke-InstallerProcess -Checkout $checkout -ConfigHome $config
        $result.ExitCode | Should -Be 0
        $result.Stdout | Should -Match 'KEEP: alpha: '
        $result.Stdout | Should -Match 'KEEP: beta: '
    }

    It 'reports a <_> collision on stderr, exits 1, and preserves the original path' -ForEach @('foreign-link', 'broken-link', 'file', 'directory') {
        $collision = $_
        $checkout = Join-Path $TestDrive "collision-$collision/checkout"
        $config = Join-Path $TestDrive "collision-$collision/config"
        New-FixtureCheckout -Checkout $checkout
        $destDir = Get-DestinationDir -ConfigHome $config
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        $alphaDestination = Join-Path $destDir 'alpha'

        switch ($collision) {
            'foreign-link' { New-Item -ItemType SymbolicLink -Path $alphaDestination -Target (Resolve-Path (Join-Path $checkout 'skills/beta')).ProviderPath | Out-Null }
            'broken-link' { New-Item -ItemType SymbolicLink -Path $alphaDestination -Target (Join-Path $checkout 'does-not-exist') | Out-Null }
            'file' { New-Item -ItemType File -Path $alphaDestination | Out-Null }
            'directory' { New-Item -ItemType Directory -Path $alphaDestination | Out-Null }
        }

        $result = Invoke-InstallerProcess -Checkout $checkout -ConfigHome $config
        $result.ExitCode | Should -Be 1
        $result.Stderr | Should -Match "COLLISION: alpha: $([regex]::Escape($alphaDestination))"
        $result.Stdout | Should -Not -Match 'COLLISION: alpha:'

        $item = Get-Item -LiteralPath $alphaDestination -Force
        switch ($collision) {
            { $_ -in 'foreign-link', 'broken-link' } { $item.LinkType | Should -Be 'SymbolicLink' }
            'file' { $item.LinkType | Should -BeNullOrEmpty; $item.PSIsContainer | Should -BeFalse }
            'directory' { $item.LinkType | Should -BeNullOrEmpty; $item.PSIsContainer | Should -BeTrue }
        }
    }

    It 'falls back to HOME\.config with spaces in the path when XDG_CONFIG_HOME is unset' {
        $checkout = Join-Path $TestDrive 'home fallback/checkout with spaces'
        $homeDir = Join-Path $TestDrive 'home fallback/home with spaces'
        New-FixtureCheckout -Checkout $checkout

        $result = Invoke-InstallerProcess -Checkout $checkout -ConfigHome $homeDir -UseHomeFallback
        $result.ExitCode | Should -Be 0
        $destDir = Get-DestinationDir -ConfigHome $homeDir -UseHomeFallback
        $expectedLine = [regex]::Escape("LINK: alpha: $(Join-Path $destDir 'alpha')")
        $result.Stdout | Should -Match $expectedLine
        $resolved = (Get-Item -LiteralPath (Join-Path $destDir 'alpha') -Force).Target | Select-Object -First 1
        $expected = (Resolve-Path -LiteralPath (Join-Path $checkout 'skills/alpha')).ProviderPath
        $resolved | Should -Be $expected
    }

    It 'reports WOULD_LINK and creates nothing on a dry run' {
        $checkout = Join-Path $TestDrive 'dry-run/checkout'
        $config = Join-Path $TestDrive 'dry-run/config'
        New-FixtureCheckout -Checkout $checkout

        $result = Invoke-InstallerProcess -Checkout $checkout -ConfigHome $config -ScriptArgs @('-DryRun')
        $result.ExitCode | Should -Be 0
        foreach ($id in 'alpha', 'beta') {
            $result.Stdout | Should -Match "WOULD_LINK: ${id}: "
        }
        Test-Path -LiteralPath $config | Should -BeFalse
    }

    It 'exits 2 on an unknown extra argument' {
        $checkout = Join-Path $TestDrive 'usage/checkout'
        $config = Join-Path $TestDrive 'usage/config'
        New-FixtureCheckout -Checkout $checkout
        $result = Invoke-InstallerProcess -Checkout $checkout -ConfigHome $config -ScriptArgs @('extra-garbage')
        $result.ExitCode | Should -Be 2
        $result.Stderr | Should -Match 'ERROR: unknown argument'
    }

    It 'documents usage via Get-Help (not just the auto-generated syntax line)' {
        $help = Get-Help $script:ScriptPath
        # A missing/broken comment-based help block makes Get-Help fall back
        # to an auto-generated syntax line as the "Synopsis" — assert on
        # real prose, not just non-empty, so that regression is caught.
        $help.Synopsis | Should -Match 'OpenCode skill installer'
    }
}

Describe 'New-SkillLink and Get-ManagedLinkTarget (unit-level, mocked failure/fallback)' {

    It 'reports success with the SymbolicLink mechanism when creation succeeds' {
        $canonical = Join-Path $TestDrive 'unit-success/target'
        New-Item -ItemType Directory -Path $canonical -Force | Out-Null
        $destination = Join-Path $TestDrive 'unit-success/link'
        $result = New-SkillLink -CanonicalTarget $canonical -Destination $destination
        $result.Success | Should -BeTrue
        $result.Mechanism | Should -Be 'SymbolicLink'
    }

    It 'falls back to Junction when SymbolicLink creation fails, without touching a real elevation state' {
        Mock -CommandName New-Item -ParameterFilter { $ItemType -eq 'SymbolicLink' } -MockWith {
            throw 'Access is denied (simulated: no Developer Mode / not elevated)'
        }
        Mock -CommandName New-Item -ParameterFilter { $ItemType -eq 'Junction' } -MockWith {
            [pscustomobject]@{ FullName = $Path }
        }
        $result = New-SkillLink -CanonicalTarget 'C:\fixture\target' -Destination 'C:\fixture\link'
        $result.Success | Should -BeTrue
        $result.Mechanism | Should -Be 'Junction'
        Should -Invoke -CommandName New-Item -ParameterFilter { $ItemType -eq 'SymbolicLink' } -Times 1 -Exactly
        Should -Invoke -CommandName New-Item -ParameterFilter { $ItemType -eq 'Junction' } -Times 1 -Exactly
    }

    It 'reports failure with both underlying errors when symlink and junction both fail' {
        Mock -CommandName New-Item -ParameterFilter { $ItemType -eq 'SymbolicLink' } -MockWith { throw 'symlink denied' }
        Mock -CommandName New-Item -ParameterFilter { $ItemType -eq 'Junction' } -MockWith { throw 'junction denied' }
        $result = New-SkillLink -CanonicalTarget 'C:\fixture\target' -Destination 'C:\fixture\link'
        $result.Success | Should -BeFalse
        $result.Error | Should -Match 'symlink denied'
        $result.Error | Should -Match 'junction denied'
    }

    It 'resolves a relative symlink target relative to the link''s own directory' {
        $root = Join-Path $TestDrive 'unit-relative'
        New-Item -ItemType Directory -Path (Join-Path $root 'target-dir') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root 'links') -Force | Out-Null
        New-Item -ItemType SymbolicLink -Path (Join-Path $root 'links/rel') -Target '../target-dir' | Out-Null
        $resolved = Get-ManagedLinkTarget -Destination (Join-Path $root 'links/rel')
        $resolved | Should -Be (Resolve-Path -LiteralPath (Join-Path $root 'target-dir')).ProviderPath
    }

    It 'returns $null for a broken link' {
        $root = Join-Path $TestDrive 'unit-broken'
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        New-Item -ItemType SymbolicLink -Path (Join-Path $root 'broken') -Target (Join-Path $root 'nope') | Out-Null
        Get-ManagedLinkTarget -Destination (Join-Path $root 'broken') | Should -BeNullOrEmpty
    }

    It 'returns $null for a plain directory (not a link at all)' {
        $root = Join-Path $TestDrive 'unit-plain'
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        Get-ManagedLinkTarget -Destination $root | Should -BeNullOrEmpty
    }
}
