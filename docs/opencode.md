# OpenCode

OpenCode can consume the canonical `skills/` directories in this checkout. It does not need copies of the skill bodies.

## Discovery

OpenCode discovers native project skills at `.opencode/skills/<name>/SKILL.md` and native global skills at `${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills/<name>/SKILL.md`. It also discovers the Claude-compatible and agent-compatible paths `.claude/skills/<name>/SKILL.md`, `.agents/skills/<name>/SKILL.md`, `~/.claude/skills/<name>/SKILL.md`, and `~/.agents/skills/<name>/SKILL.md`.

For project paths, OpenCode walks from the working directory to the Git worktree. It advertises a skill's name and description, then loads its body on demand with its native `skill` tool. Each directory name and `name` frontmatter field must match `^[a-z0-9]+(-[a-z0-9]+)*$`; names are limited to 1–64 characters. See the [official Agent Skills documentation](https://opencode.ai/docs/skills).

## Install this checkout globally

From this repository's root, verify the skill tree and preview the links:

```sh
./scripts/check-portability.sh
./scripts/install-opencode.sh --dry-run
```

Run the installer to create managed symlinks under `${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills`:

```sh
./scripts/install-opencode.sh
```

The installer creates no copies. A second run keeps links that resolve exactly to this checkout; it reports a collision for every other existing destination, including foreign or broken symlinks.

## On Windows

`scripts/check-portability.ps1` and `scripts/install-opencode.ps1` are PowerShell ports of the two scripts above — same checks, same `PASS:`/`WARN:`/`ERROR:` and `LINK:`/`KEEP:`/`WOULD_LINK:`/`COLLISION:` diagnostics, same exit codes. They use an idiomatic PowerShell CLI (`-Root`, `-DryRun`) and `Get-Help` instead of the bash scripts' `--root`/`--dry-run`/`--help` flags. Run them the same way, from the repository root, in PowerShell (Windows PowerShell 5.1 or PowerShell 7+):

```powershell
./scripts/check-portability.ps1
./scripts/install-opencode.ps1 -DryRun
./scripts/install-opencode.ps1
```

Creating a real symbolic link on Windows normally requires Administrator rights or [Developer Mode](https://learn.microsoft.com/windows/apps/get-started/enable-your-device-for-development). `install-opencode.ps1` tries a symbolic link first and, only if that fails on privilege grounds, falls back to a directory junction — no elevation required, and still no copies. The KEEP/COLLISION logic treats both link types identically, so a second run stays idempotent either way.

Uninstalling mirrors the bash snippet above — remove only links this checkout manages, refusing anything else:

```powershell
$checkoutDir = (Resolve-Path .).ProviderPath
$skillsDir = Join-Path $checkoutDir 'skills'
$configHome = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME '.config' }
$destinationDir = Join-Path (Join-Path $configHome 'opencode') 'skills'

Get-ChildItem -LiteralPath $skillsDir -Directory | ForEach-Object {
    $destination = Join-Path $destinationDir $_.Name
    $item = Get-Item -LiteralPath $destination -Force -ErrorAction SilentlyContinue
    if (-not $item) { return }
    if (-not $item.LinkType) { Write-Warning "REFUSE: $destination is not a managed link"; return }

    $target = $item.Target | Select-Object -First 1
    if (-not [System.IO.Path]::IsPathRooted($target)) {
        $target = Join-Path (Split-Path -Parent $destination) $target
    }
    try { $resolvedTarget = (Resolve-Path -LiteralPath $target -ErrorAction Stop).ProviderPath }
    catch { Write-Warning "REFUSE: $destination is broken"; return }

    $expected = (Resolve-Path -LiteralPath $_.FullName).ProviderPath
    if ($resolvedTarget -cne $expected) { Write-Warning "REFUSE: $destination points outside this checkout"; return }

    Remove-Item -LiteralPath $destination -Force
}
```

The Pester suites (`tests/check-portability.Tests.ps1`, `tests/install-opencode.Tests.ps1`) mirror the bash black-box suites' fixture cases, plus unit-level coverage of the symlink→junction fallback (mocked, since forcing a real privilege failure isn't scriptable). Run them with `Invoke-Pester -Path tests/check-portability.Tests.ps1, tests/install-opencode.Tests.ps1`.

## Update and uninstall

Update the checkout, re-check it, and run the installer again:

```sh
git pull
./scripts/check-portability.sh
./scripts/install-opencode.sh
```

Run this from the checkout root to remove only links managed by this checkout. It skips absent destinations and refuses real paths, broken links, and links to another checkout:

```bash
checkout_dir=$(pwd -P)
skills_dir="$checkout_dir/skills"
config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
destination_dir="$config_home/opencode/skills"

for skill_dir in "$skills_dir"/*; do
  [ -d "$skill_dir" ] || continue
  id=${skill_dir##*/}
  destination="$destination_dir/$id"

  [ -e "$destination" ] || [ -L "$destination" ] || continue
  if [ ! -L "$destination" ]; then
    printf 'REFUSE: %s is not a managed symlink\n' "$destination" >&2
    continue
  fi

  target=$(cd -P "$destination" 2>/dev/null && pwd -P) || {
    printf 'REFUSE: %s is broken\n' "$destination" >&2
    continue
  }
  expected=$(cd -P "$skill_dir" && pwd -P)
  if [ "$target" != "$expected" ]; then
    printf 'REFUSE: %s points outside this checkout\n' "$destination" >&2
    continue
  fi

  unlink "$destination"
done
```

## Skill permissions

OpenCode's `permission.skill` rules decide whether an agent can load a skill: `allow` loads it immediately, `ask` asks for approval, and `deny` hides it and rejects loading. Rules can be specific or pattern-based. Choose those rules in your own `opencode.json`; this repository does not modify that file or recommend a provider or model. See [skill permissions](https://opencode.ai/docs/skills#configure-permissions).

## Superpowers dependency

The four Superpowers skills (`brainstorming`, `writing-plans`, `subagent-driven-development`, `executing-plans`) are installed from upstream rather than vendored here. Their provenance and install routes are in [runtime portability](runtime-portability.md#external-dependencies). Do not recreate any of them from this document or from a plan; a missing one is a stop. Earlier versions of this repository vendored `brainstorming`; it is now external like the other three.

Confirm OpenCode discovers `brainstorming` after installing it from upstream:

```sh
opencode debug skill | jq -r '.[] | select(.name=="brainstorming") | "\(.name)\t\(.location)"'
```

That prints one line, naming `brainstorming` and the `SKILL.md` it resolved.
