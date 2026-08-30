<#
.SYNOPSIS
Deterministic cross-runtime portability checker for this repository's skills.

.DESCRIPTION
Validates every direct child directory of skills/ (or -Root's skills/
directory): SKILL.md presence, YAML frontmatter (name/description, OpenCode
name rules, name-matches-directory), forbidden runtime paths, bundled
reference closure, and warning-only host-specific wording.

This is the Windows/PowerShell counterpart to scripts/check-portability.sh.
It performs the same checks and prints the same PASS:/WARN:/ERROR: prefixed
diagnostics and exit codes (0 = pass, 1 = check failures, 2 = usage error).
It differs only in CLI surface: an idiomatic -Root parameter and built-in
Get-Help, instead of the bash script's --root/--help flags.

.PARAMETER Root
Repository root to check. Defaults to the parent directory of this script's
own directory (i.e. the repository checkout this script lives in).

.EXAMPLE
./check-portability.ps1

.EXAMPLE
./check-portability.ps1 -Root C:\path\to\checkout
#>
[CmdletBinding()]
param(
    [string]$Root,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ArgumentList = @()
)

function Get-FrontmatterFindings {
    <#
    .SYNOPSIS
    Validates a SKILL.md's YAML frontmatter: closure, name, description,
    OpenCode name rules, and name/directory equality.
    #>
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Path
    )

    $findings = @()
    $lines = Get-Content -LiteralPath $Path -ErrorAction Stop

    $inFrontmatter = $false
    $closedFrontmatter = $false
    $name = ''
    $description = ''
    $firstLine = $true

    foreach ($line in $lines) {
        if ($firstLine) {
            $firstLine = $false
            if ($line -cne '---') { break }
            $inFrontmatter = $true
            continue
        }
        if ($inFrontmatter -and $line -ceq '---') {
            $closedFrontmatter = $true
            break
        }
        if ($line -cmatch '^name:\s*(.*)$') {
            $name = $Matches[1]
        }
        elseif ($line -cmatch '^description:\s*(.*)$') {
            $description = $Matches[1]
        }
    }

    if ($inFrontmatter -and -not $closedFrontmatter) {
        $findings += [pscustomobject]@{ Severity = 'ERROR'; Id = $Id; Message = 'unclosed YAML frontmatter' }
    }
    if ([string]::IsNullOrEmpty($name)) {
        $findings += [pscustomobject]@{ Severity = 'ERROR'; Id = $Id; Message = 'missing name' }
    }
    if ([string]::IsNullOrEmpty($description)) {
        $findings += [pscustomobject]@{ Severity = 'ERROR'; Id = $Id; Message = 'missing description' }
    }
    if (-not [string]::IsNullOrEmpty($name)) {
        if ($name.Length -gt 64 -or $name -cnotmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
            $findings += [pscustomobject]@{ Severity = 'ERROR'; Id = $Id; Message = 'invalid OpenCode name' }
        }
        if ($name -cne $Id) {
            $findings += [pscustomobject]@{ Severity = 'ERROR'; Id = $Id; Message = 'name does not match directory' }
        }
    }

    return $findings
}

function Get-ForbiddenPathFindings {
    <#
    .SYNOPSIS
    Flags occurrences of the six forbidden runtime-specific installation
    paths anywhere in a skill file, including its frontmatter.
    #>
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Path
    )

    $forbiddenPaths = @(
        '.claude/skills/', '~/.claude/skills/', '.codex/skills/',
        '~/.codex/skills/', '.opencode/skills/', '~/.config/opencode/skills/'
    )

    $findings = @()
    $lines = Get-Content -LiteralPath $Path -ErrorAction Stop
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++
        foreach ($forbidden in $forbiddenPaths) {
            if ($line.Contains($forbidden)) {
                $findings += [pscustomobject]@{
                    Severity = 'ERROR'
                    Id       = $Id
                    Message  = "forbidden runtime path $forbidden at ${Path}:${lineNumber}"
                }
            }
        }
    }
    return $findings
}

function Get-ReferenceFindings {
    <#
    .SYNOPSIS
    Checks that every literal references/... or scripts/... token in a
    skill file resolves to a real file inside that skill's directory.
    #>
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$SkillDir,
        [Parameter(Mandatory)][string]$Path
    )

    $findings = @()
    $lines = Get-Content -LiteralPath $Path -ErrorAction Stop
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++
        $tokens = $line -split '[^A-Za-z0-9_./-]+' | Where-Object { $_ -ne '' }
        foreach ($token in $tokens) {
            if ($token -clike 'references/*' -or $token -clike 'scripts/*') {
                $reference = $token.TrimEnd('.')
                $referencePath = Join-Path $SkillDir $reference
                if (-not (Test-Path -LiteralPath $referencePath -PathType Leaf)) {
                    $findings += [pscustomobject]@{
                        Severity = 'ERROR'
                        Id       = $Id
                        Message  = "missing referenced file $reference at ${Path}:${lineNumber}"
                    }
                }
            }
        }
    }
    return $findings
}

function Get-HostWordingFindings {
    <#
    .SYNOPSIS
    Warns (non-blocking) about host-specific tool wording outside
    frontmatter: 'Claude Code tool', 'Read tool', 'Edit tool', 'Glob',
    'Task tool'.
    #>
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Path
    )

    $phrases = @('Claude Code tool', 'Read tool', 'Edit tool', 'Glob', 'Task tool')

    $findings = @()
    $lines = Get-Content -LiteralPath $Path -ErrorAction Stop
    $lineNumber = 0
    $inFrontmatter = $false
    $firstLine = $true
    foreach ($line in $lines) {
        $lineNumber++
        if ($firstLine -and $line -ceq '---') {
            $inFrontmatter = $true
            $firstLine = $false
            continue
        }
        $firstLine = $false
        if ($inFrontmatter) {
            if ($line -ceq '---') { $inFrontmatter = $false }
            continue
        }
        foreach ($phrase in $phrases) {
            if ($line.Contains($phrase)) {
                $findings += [pscustomobject]@{
                    Severity = 'WARN'
                    Id       = $Id
                    Message  = "host-specific wording $phrase at ${Path}:${lineNumber}"
                }
            }
        }
    }
    return $findings
}

function Invoke-PortabilityCheck {
    <#
    .SYNOPSIS
    Runs every check against each direct child of $RootDir/skills, in
    sorted (ordinal) directory-name order. Throws if $RootDir/skills is
    missing (the caller maps this to exit 1).
    #>
    param(
        [Parameter(Mandatory)][string]$RootDir
    )

    $skillsDir = Join-Path $RootDir 'skills'
    if (-not (Test-Path -LiteralPath $skillsDir -PathType Container)) {
        throw [System.IO.DirectoryNotFoundException]::new("missing skills directory: $skillsDir")
    }

    $skillDirs = Get-ChildItem -LiteralPath $skillsDir -Directory -Force |
        Sort-Object -Property Name -CaseSensitive

    $findings = @()
    $skillCount = 0

    foreach ($skillDir in $skillDirs) {
        $skillCount++
        $id = $skillDir.Name
        $skillFile = Join-Path $skillDir.FullName 'SKILL.md'
        if (-not (Test-Path -LiteralPath $skillFile -PathType Leaf)) {
            $findings += [pscustomobject]@{ Severity = 'ERROR'; Id = $id; Message = 'missing SKILL.md' }
            continue
        }
        $findings += Get-FrontmatterFindings -Id $id -Path $skillFile
        $findings += Get-ForbiddenPathFindings -Id $id -Path $skillFile
        $findings += Get-ReferenceFindings -Id $id -SkillDir $skillDir.FullName -Path $skillFile
        $findings += Get-HostWordingFindings -Id $id -Path $skillFile
    }

    return [pscustomobject]@{
        Findings   = $findings
        SkillCount = $skillCount
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

    if ($Root) {
        if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
            [Console]::Error.WriteLine("ERROR: -Root is not a directory: $Root")
            exit 2
        }
        $rootDir = (Resolve-Path -LiteralPath $Root).ProviderPath
    }

    try {
        $result = Invoke-PortabilityCheck -RootDir $rootDir
    }
    catch [System.IO.DirectoryNotFoundException] {
        [Console]::Error.WriteLine("ERROR: $($_.Exception.Message)")
        exit 1
    }

    $hasErrors = $false
    foreach ($finding in $result.Findings) {
        Write-Output "$($finding.Severity): $($finding.Id): $($finding.Message)"
        if ($finding.Severity -eq 'ERROR') { $hasErrors = $true }
    }

    if ($hasErrors) {
        exit 1
    }

    Write-Output "PASS: $($result.SkillCount) skills checked"
    exit 0
}
