<#
.SYNOPSIS
Idempotent, collision-safe OpenCode skill installer (Windows/PowerShell).

.DESCRIPTION
Links every direct child of this checkout's skills/ directory into
OpenCode's global skills directory
($env:XDG_CONFIG_HOME/opencode/skills, or $HOME/.config/opencode/skills
when XDG_CONFIG_HOME is unset), creating no copies.

This is the Windows/PowerShell counterpart to scripts/install-opencode.sh.
It prints the same LINK:/KEEP:/WOULD_LINK:/COLLISION: diagnostics (skill ID
plus destination) and exit codes (0 = success, 1 = a collision or link
failure occurred, 2 = usage error). Collisions and link-creation failures go
to stderr, exactly like the bash script.

A managed link is a symlink OR directory junction whose resolved target
exactly equals the corresponding direct child of this checkout's canonical
skills/ directory. A matching link is left unchanged (KEEP); any other
existing path, including a foreign or broken link, is a collision.

Windows note: creating a real symbolic link normally requires Administrator
rights or Developer Mode. This script tries a symbolic link first and,
only if that fails on privilege grounds, falls back to a directory
junction (no elevation required, same no-copy guarantee). Both link types
are treated identically by the KEEP/COLLISION logic above.

.PARAMETER DryRun
Report what would be linked without creating any directories or links.

.EXAMPLE
./install-opencode.ps1

.EXAMPLE
./install-opencode.ps1 -DryRun
#>
[CmdletBinding()]
param(
    [switch]$DryRun,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ArgumentList = @()
)

function Get-ManagedLinkTarget {
    <#
    .SYNOPSIS
    If $Destination is a symlink or junction, resolves and returns its
    target as a canonical absolute path. Returns $null if $Destination
    does not exist, is not a link, or its target cannot be resolved
    (e.g. a broken link) — mirroring the bash installer's
    resolve_link_directory, which also yields an empty/mismatching
    result for a broken link.
    #>
    param(
        [Parameter(Mandatory)][string]$Destination
    )

    $item = Get-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue
    if (-not $item -or -not $item.LinkType) {
        return $null
    }

    $rawTarget = $item.Target | Select-Object -First 1
    if ([string]::IsNullOrEmpty($rawTarget)) {
        return $null
    }

    if (-not [System.IO.Path]::IsPathRooted($rawTarget)) {
        $rawTarget = Join-Path (Split-Path -Parent $Destination) $rawTarget
    }

    try {
        return (Resolve-Path -LiteralPath $rawTarget -ErrorAction Stop).ProviderPath
    }
    catch {
        return $null
    }
}

function New-SkillLink {
    <#
    .SYNOPSIS
    Creates $Destination as a symbolic link to $CanonicalTarget. Falls
    back to a directory junction if symbolic-link creation fails (the
    expected outcome on Windows without Administrator rights or
    Developer Mode). Never falls back silently past a genuine failure:
    if both attempts fail, both errors are reported.
    #>
    param(
        [Parameter(Mandatory)][string]$CanonicalTarget,
        [Parameter(Mandatory)][string]$Destination
    )

    try {
        New-Item -ItemType SymbolicLink -Path $Destination -Target $CanonicalTarget -ErrorAction Stop | Out-Null
        return [pscustomobject]@{ Success = $true; Mechanism = 'SymbolicLink'; Error = $null }
    }
    catch {
        $symlinkError = $_.Exception.Message
        try {
            New-Item -ItemType Junction -Path $Destination -Target $CanonicalTarget -ErrorAction Stop | Out-Null
            return [pscustomobject]@{ Success = $true; Mechanism = 'Junction'; Error = $null }
        }
        catch {
            return [pscustomobject]@{
                Success   = $false
                Mechanism = $null
                Error     = "symlink failed ($symlinkError); junction failed ($($_.Exception.Message))"
            }
        }
    }
}

function Invoke-OpenCodeInstall {
    <#
    .SYNOPSIS
    Links every direct child of $RootDir/skills into $DestinationDir.
    Throws if $RootDir/skills is missing, or if $DestinationDir cannot
    be created when it doesn't yet exist (the caller maps either to
    exit 1). Otherwise returns the full set of diagnostic lines and
    whether any collision or link failure occurred.
    #>
    param(
        [Parameter(Mandatory)][string]$RootDir,
        [Parameter(Mandatory)][string]$DestinationDir,
        [switch]$DryRun
    )

    $skillsDir = Join-Path $RootDir 'skills'
    if (-not (Test-Path -LiteralPath $skillsDir -PathType Container)) {
        throw [System.IO.DirectoryNotFoundException]::new("missing skills directory: $skillsDir")
    }

    $skillDirs = Get-ChildItem -LiteralPath $skillsDir -Directory -Force

    $outputLines = @()
    $errorLines = @()
    $failed = $false

    foreach ($skillDir in $skillDirs) {
        $id = $skillDir.Name
        $canonicalTarget = (Resolve-Path -LiteralPath $skillDir.FullName).ProviderPath
        $destination = Join-Path $DestinationDir $id

        $existingItem = Get-Item -LiteralPath $destination -Force -ErrorAction SilentlyContinue

        if ($existingItem -and $existingItem.LinkType) {
            $resolvedTarget = Get-ManagedLinkTarget -Destination $destination
            if ($resolvedTarget -and ($resolvedTarget -ceq $canonicalTarget)) {
                $outputLines += "KEEP: ${id}: ${destination}"
            }
            else {
                $errorLines += "COLLISION: ${id}: ${destination}"
                $failed = $true
            }
        }
        elseif ($existingItem) {
            $errorLines += "COLLISION: ${id}: ${destination}"
            $failed = $true
        }
        elseif ($DryRun) {
            $outputLines += "WOULD_LINK: ${id}: ${destination}"
        }
        else {
            if (-not (Test-Path -LiteralPath $DestinationDir -PathType Container)) {
                try {
                    New-Item -ItemType Directory -Path $DestinationDir -Force -ErrorAction Stop | Out-Null
                }
                catch {
                    throw [System.IO.IOException]::new("cannot create destination directory: $DestinationDir")
                }
            }
            $linkResult = New-SkillLink -CanonicalTarget $canonicalTarget -Destination $destination
            if ($linkResult.Success) {
                $outputLines += "LINK: ${id}: ${destination}"
            }
            else {
                $errorLines += "ERROR: ${id}: cannot create link: ${destination}"
                $failed = $true
            }
        }
    }

    return [pscustomobject]@{
        OutputLines = $outputLines
        ErrorLines  = $errorLines
        Failed      = $failed
    }
}

# --- CLI entry point ---------------------------------------------------
# Guarded so Pester can dot-source this file (InvocationName -eq '.') and
# call the functions above directly, without also running the CLI.
if ($MyInvocation.InvocationName -ne '.') {
    if ($ArgumentList.Count -gt 0) {
        [Console]::Error.WriteLine("ERROR: unknown argument: $($ArgumentList[0])")
        exit 2
    }

    $scriptDir = Split-Path -Parent $PSCommandPath
    $rootDir = Split-Path -Parent $scriptDir

    $configHome = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME '.config' }
    $destinationDir = Join-Path (Join-Path $configHome 'opencode') 'skills'

    try {
        $result = Invoke-OpenCodeInstall -RootDir $rootDir -DestinationDir $destinationDir -DryRun:$DryRun
    }
    catch {
        [Console]::Error.WriteLine("ERROR: $($_.Exception.Message)")
        exit 1
    }

    foreach ($line in $result.OutputLines) { Write-Output $line }
    foreach ($line in $result.ErrorLines) { [Console]::Error.WriteLine($line) }

    if ($result.Failed) { exit 1 }
    exit 0
}
