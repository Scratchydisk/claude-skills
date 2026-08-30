# Codex

Codex uses the same `SKILL.md` format, but it has its own discovery and distribution model.

## Discovery and local installation

Codex discovers repository skills in `.agents/skills`, user skills in `$HOME/.agents/skills`, and administrator-managed skills in `/etc/codex/skills`. Install a standalone skill by placing its complete directory, including `SKILL.md`, in one of those locations. For a reusable collection, prefer a Codex plugin rather than relying on this repository's Claude Code marketplace manifest.

Codex normally detects a changed skill automatically. If a new or changed skill does not appear, restart Codex or start a new session.

Use an exact `[[skills.config]]` entry in `~/.codex/config.toml` to enable or disable a local skill:

```toml
[[skills.config]]
path = "/absolute/path/to/skill/SKILL.md"
enabled = false
```

Set `enabled = true` to enable that path. The [official configuration reference](https://developers.openai.com/codex/config-reference/) documents Codex configuration, and the [official skill guide](https://developers.openai.com/codex/skills/) explains why plugins are the distribution mechanism for reusable skills.

## The `brainstorming` skill

`brainstorming` lives in this checkout at `skills/brainstorming/`. It is an unmodified copy of [`obra/superpowers` at `b36e0829`](https://github.com/obra/superpowers/tree/b36e0829c6d0140e93cfef2ca599b1b07d4a7797/skills/brainstorming), vendored under its MIT licence; `skills/brainstorming/LICENSE` and [`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md) carry the attribution and the per-file checksums. Install it the same way as any other skill in this checkout — symlink the directory into a discovery location:

```sh
mkdir -p "$HOME/.agents/skills"
ln -s "$(pwd -P)/skills/brainstorming" "$HOME/.agents/skills/brainstorming"
```

Confirm Codex picked it up without starting a session:

```sh
codex debug prompt-input | grep -o '[a-z:-]*brainstorming: [^(]*'
```

`codex debug prompt-input` renders the model-visible prompt locally and contacts no model provider. One matching line means the skill reached the `### Available skills` block Codex sends to the model.

Codex advertises a symlinked skill under the name of the plugin that owns the link target. Because this checkout carries `.claude-plugin/plugin.json`, a symlink into it appears as `scratchydisk-skills:brainstorming` rather than bare `brainstorming`; a plain copy, or a symlink whose target sits outside a plugin repository, appears as `brainstorming`. Both are discovered and loadable — only the advertised identifier differs. The `SKILL.md` `name` field is `brainstorming` either way.

## Other external skills

`writing-plans`, `subagent-driven-development`, and `executing-plans` are not vendored here. Use `$skill-installer` with an immutable commit URL, for example:

```text
$skill-installer install https://github.com/obra/superpowers/tree/b36e0829c6d0140e93cfef2ca599b1b07d4a7797/skills/writing-plans
```

The installed directory must contain the upstream `SKILL.md` unchanged. The helper accepts a repository, a path, and an explicit ref; this invocation names all three. Do not recreate any of these skills from this document or from a plan. Their provenance and licence are recorded in [runtime portability](runtime-portability.md#external-dependencies).

## This repository

This repository's `skills/` tree is not automatically a Codex discovery root. Symlink the complete skill directories you intend to use into an official discovery location, or package them as a Codex plugin for reusable distribution. Keep the source checkout for updates and run its portability checker before installation.
