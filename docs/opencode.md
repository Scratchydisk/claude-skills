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

`brainstorming` is not recreated or vendored by this repository. Its verified source is [`obra/superpowers` at `v6.3.0`](https://github.com/obra/superpowers/tree/v6.3.0/skills/brainstorming). To expose a verified checkout to OpenCode, create a direct link to the exact directory:

```sh
source_dir=/path/to/superpowers/skills/brainstorming
config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
destination="$config_home/opencode/skills/brainstorming"

[ -d "$source_dir" ] || { printf 'ERROR: missing source: %s\n' "$source_dir" >&2; exit 1; }
if [ -e "$destination" ] || [ -L "$destination" ]; then
  printf 'COLLISION: %s\n' "$destination" >&2
  exit 1
fi

mkdir -p "$(dirname "$destination")"
ln -s "$source_dir" "$destination"
```

Replace `/path/to/superpowers` only with a checkout you have independently verified at the recorded revision. If an authorised future change imports the complete upstream directory into this repository, its installer can manage that imported copy instead. Do not recreate the skill from this document or from a plan.

The complete provenance and the status of the other Superpowers dependencies are in [runtime portability](runtime-portability.md#external-dependencies).
