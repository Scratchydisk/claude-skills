<#
.SYNOPSIS
Pester black-box + unit tests for scripts/check-portability.ps1 — the
Windows/PowerShell counterpart to tests/test-check-portability.sh.

Mirrors the same fixture-based contract cases as the bash suite. Run with:
    Invoke-Pester -Path tests/check-portability.Tests.ps1
#>

BeforeAll {
    $script:ScriptPath = (Resolve-Path (Join-Path $PSScriptRoot '..' 'scripts' 'check-portability.ps1')).ProviderPath
    . $script:ScriptPath
    $script:PwshExe = (Get-Process -Id $PID).Path

    function New-FixtureRoot {
        $root = Join-Path $TestDrive ([System.Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $root 'skills') -Force | Out-Null
        return $root
    }

    function New-FixtureSkill {
        param([string]$Root, [string]$Id, [string]$Body = '')
        $dir = Join-Path $Root "skills/$Id"
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        $lines = @('---', "name: $Id", 'description: A fixture skill.', '---', $Body)
        Set-Content -LiteralPath (Join-Path $dir 'SKILL.md') -Value $lines
    }

    function Invoke-ScriptProcess {
        param(
            [string[]]$ScriptArgs = @(),
            [hashtable]$EnvironmentOverrides = @{},
            [string[]]$EnvironmentRemovals = @()
        )
        $psi = [System.Diagnostics.ProcessStartInfo]::new()
        $psi.FileName = $script:PwshExe
        foreach ($a in @('-NoProfile', '-NonInteractive', '-File', $script:ScriptPath) + $ScriptArgs) {
            $psi.ArgumentList.Add($a)
        }
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.UseShellExecute = $false
        foreach ($key in $EnvironmentOverrides.Keys) { $psi.Environment[$key] = $EnvironmentOverrides[$key] }
        foreach ($key in $EnvironmentRemovals) { $psi.Environment.Remove($key) | Out-Null }
        $proc = [System.Diagnostics.Process]::Start($psi)
        $stdout = $proc.StandardOutput.ReadToEnd()
        $stderr = $proc.StandardError.ReadToEnd()
        $proc.WaitForExit()
        return [pscustomobject]@{ ExitCode = $proc.ExitCode; Stdout = $stdout; Stderr = $stderr }
    }
}

Describe 'Invoke-PortabilityCheck (function-level fixture contracts)' {

    It 'passes a valid skill' {
        $root = New-FixtureRoot
        New-FixtureSkill -Root $root -Id 'valid-skill' -Body 'Use the relevant project command.'
        $result = Invoke-PortabilityCheck -RootDir $root
        $result.SkillCount | Should -Be 1
        $result.Findings | Should -BeNullOrEmpty
    }

    It 'errors on a missing SKILL.md' {
        $root = New-FixtureRoot
        New-Item -ItemType Directory -Path (Join-Path $root 'skills/missing-file') -Force | Out-Null
        $result = Invoke-PortabilityCheck -RootDir $root
        $result.Findings | Where-Object { $_.Severity -eq 'ERROR' -and $_.Id -eq 'missing-file' -and $_.Message -eq 'missing SKILL.md' } |
            Should -Not -BeNullOrEmpty
    }

    It 'errors on missing name' {
        $root = New-FixtureRoot
        New-Item -ItemType Directory -Path (Join-Path $root 'skills/missing-name') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $root 'skills/missing-name/SKILL.md') -Value @('---', 'description: A fixture skill.', '---')
        $result = Invoke-PortabilityCheck -RootDir $root
        $result.Findings | Where-Object { $_.Severity -eq 'ERROR' -and $_.Id -eq 'missing-name' -and $_.Message -eq 'missing name' } |
            Should -Not -BeNullOrEmpty
    }

    It 'errors on missing description' {
        $root = New-FixtureRoot
        New-Item -ItemType Directory -Path (Join-Path $root 'skills/missing-description') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $root 'skills/missing-description/SKILL.md') -Value @('---', 'name: missing-description', '---')
        $result = Invoke-PortabilityCheck -RootDir $root
        $result.Findings | Where-Object { $_.Severity -eq 'ERROR' -and $_.Id -eq 'missing-description' -and $_.Message -eq 'missing description' } |
            Should -Not -BeNullOrEmpty
    }

    It 'errors when name does not match directory' {
        $root = New-FixtureRoot
        New-FixtureSkill -Root $root -Id 'wrong-name'
        $content = Get-Content -LiteralPath (Join-Path $root 'skills/wrong-name/SKILL.md') -Raw
        $content = $content -replace 'name: wrong-name', 'name: other-name'
        Set-Content -LiteralPath (Join-Path $root 'skills/wrong-name/SKILL.md') -Value $content -NoNewline
        $result = Invoke-PortabilityCheck -RootDir $root
        $result.Findings | Where-Object { $_.Severity -eq 'ERROR' -and $_.Id -eq 'wrong-name' -and $_.Message -eq 'name does not match directory' } |
            Should -Not -BeNullOrEmpty
    }

    It 'errors on invalid OpenCode name: <_>' -ForEach @('Uppercase', 'has_under', 'two--parts', 'trailing-') {
        $root = New-FixtureRoot
        New-FixtureSkill -Root $root -Id $_
        $result = Invoke-PortabilityCheck -RootDir $root
        $result.Findings | Where-Object { $_.Severity -eq 'ERROR' -and $_.Message -eq 'invalid OpenCode name' } |
            Should -Not -BeNullOrEmpty
    }

    It 'errors on a 65-character name' {
        $root = New-FixtureRoot
        $longId = 'a' * 65
        New-FixtureSkill -Root $root -Id $longId
        $result = Invoke-PortabilityCheck -RootDir $root
        $result.Findings | Where-Object { $_.Severity -eq 'ERROR' -and $_.Message -eq 'invalid OpenCode name' } |
            Should -Not -BeNullOrEmpty
    }

    It 'errors on forbidden runtime path: <_>' -ForEach @('.claude/skills/', '~/.claude/skills/', '.codex/skills/', '~/.codex/skills/', '.opencode/skills/', '~/.config/opencode/skills/') {
        $root = New-FixtureRoot
        New-FixtureSkill -Root $root -Id 'forbidden' -Body "refer to $_ in this body"
        $result = Invoke-PortabilityCheck -RootDir $root
        $result.Findings | Where-Object { $_.Severity -eq 'ERROR' -and $_.Id -eq 'forbidden' -and $_.Message -like 'forbidden runtime path*' } |
            Should -Not -BeNullOrEmpty
    }

    It 'errors on a forbidden runtime path in frontmatter' {
        $root = New-FixtureRoot
        New-FixtureSkill -Root $root -Id 'forbidden-frontmatter'
        $content = Get-Content -LiteralPath (Join-Path $root 'skills/forbidden-frontmatter/SKILL.md') -Raw
        $content = $content -replace 'description: A fixture skill\.', 'description: Refer to .claude/skills/ for this fixture.'
        Set-Content -LiteralPath (Join-Path $root 'skills/forbidden-frontmatter/SKILL.md') -Value $content -NoNewline
        $result = Invoke-PortabilityCheck -RootDir $root
        $result.Findings | Where-Object { $_.Severity -eq 'ERROR' -and $_.Id -eq 'forbidden-frontmatter' -and $_.Message -like 'forbidden runtime path*' } |
            Should -Not -BeNullOrEmpty
    }

    It 'errors on unclosed YAML frontmatter' {
        $root = New-FixtureRoot
        New-Item -ItemType Directory -Path (Join-Path $root 'skills/unclosed-frontmatter') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $root 'skills/unclosed-frontmatter/SKILL.md') -Value @(
            '---', 'name: unclosed-frontmatter', 'description: A fixture skill.', 'See references/not-there.md for details.'
        )
        $result = Invoke-PortabilityCheck -RootDir $root
        $result.Findings | Where-Object { $_.Severity -eq 'ERROR' -and $_.Id -eq 'unclosed-frontmatter' -and $_.Message -eq 'unclosed YAML frontmatter' } |
            Should -Not -BeNullOrEmpty
    }

    It 'errors on a missing relative references target' {
        $root = New-FixtureRoot
        New-FixtureSkill -Root $root -Id 'missing-reference' -Body 'See references/not-there.md for details.'
        $result = Invoke-PortabilityCheck -RootDir $root
        $result.Findings | Where-Object { $_.Severity -eq 'ERROR' -and $_.Id -eq 'missing-reference' -and $_.Message -like 'missing referenced file*' } |
            Should -Not -BeNullOrEmpty
    }

    It 'strips trailing punctuation from a references/ token' {
        $root = New-FixtureRoot
        New-FixtureSkill -Root $root -Id 'reference-punctuation' -Body 'See references/exists.md. '
        New-Item -ItemType Directory -Path (Join-Path $root 'skills/reference-punctuation/references') -Force | Out-Null
        New-Item -ItemType File -Path (Join-Path $root 'skills/reference-punctuation/references/exists.md') -Force | Out-Null
        $result = Invoke-PortabilityCheck -RootDir $root
        $result.Findings | Should -BeNullOrEmpty
        $result.SkillCount | Should -Be 1
    }

    It 'strips trailing punctuation from a scripts/ token' {
        $root = New-FixtureRoot
        New-FixtureSkill -Root $root -Id 'script-punctuation' -Body 'Run scripts/check.sh. '
        New-Item -ItemType Directory -Path (Join-Path $root 'skills/script-punctuation/scripts') -Force | Out-Null
        New-Item -ItemType File -Path (Join-Path $root 'skills/script-punctuation/scripts/check.sh') -Force | Out-Null
        $result = Invoke-PortabilityCheck -RootDir $root
        $result.Findings | Should -BeNullOrEmpty
        $result.SkillCount | Should -Be 1
    }

    It 'warns (does not error) on host-specific tool wording' {
        $root = New-FixtureRoot
        New-FixtureSkill -Root $root -Id 'warning-only' -Body 'Use the Claude Code tool, Read tool, Edit tool, Glob, and Task tool when exploring.'
        $result = Invoke-PortabilityCheck -RootDir $root
        ($result.Findings | Where-Object { $_.Severity -eq 'ERROR' }) | Should -BeNullOrEmpty
        ($result.Findings | Where-Object { $_.Severity -eq 'WARN' }) | Should -Not -BeNullOrEmpty
    }

    It 'throws when the skills directory is missing' {
        $root = Join-Path $TestDrive ([System.Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        { Invoke-PortabilityCheck -RootDir $root } | Should -Throw
    }
}

Describe 'check-portability.ps1 (CLI contract)' {

    It 'uses the repository root and passes with no arguments' {
        $result = Invoke-ScriptProcess
        $result.ExitCode | Should -Be 0
        $result.Stdout | Should -Match 'PASS:'
    }

    It 'accepts -Root and reports the count for that root' {
        $root = New-FixtureRoot
        New-FixtureSkill -Root $root -Id 'cli-skill'
        $result = Invoke-ScriptProcess -ScriptArgs @('-Root', $root)
        $result.ExitCode | Should -Be 0
        $result.Stdout | Should -Match 'PASS: 1 skills checked'
    }

    It 'exits 2 on an unknown extra argument' {
        $result = Invoke-ScriptProcess -ScriptArgs @('-Root', (New-FixtureRoot), 'extra-garbage')
        $result.ExitCode | Should -Be 2
        $result.Stderr | Should -Match 'ERROR: unknown argument'
    }

    It 'exits 2 when -Root is not a directory' {
        $result = Invoke-ScriptProcess -ScriptArgs @('-Root', (Join-Path $TestDrive 'does-not-exist'))
        $result.ExitCode | Should -Be 2
        $result.Stderr | Should -Match 'ERROR: -Root is not a directory'
    }

    It 'exits 1 with all diagnostics on stdout for a failing skill' {
        $root = New-FixtureRoot
        New-Item -ItemType Directory -Path (Join-Path $root 'skills/missing-file') -Force | Out-Null
        $result = Invoke-ScriptProcess -ScriptArgs @('-Root', $root)
        $result.ExitCode | Should -Be 1
        $result.Stdout | Should -Match 'ERROR: missing-file: missing SKILL.md'
    }

    It 'documents usage via Get-Help (not just the auto-generated syntax line)' {
        $help = Get-Help $script:ScriptPath
        # A missing/broken comment-based help block makes Get-Help fall back
        # to an auto-generated syntax line as the "Synopsis" — assert on
        # real prose, not just non-empty, so that regression is caught.
        $help.Synopsis | Should -Match 'portability checker'
    }
}
