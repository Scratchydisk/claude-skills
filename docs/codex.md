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

## External Superpowers skills

`brainstorming`, `writing-plans`, `subagent-driven-development`, and `executing-plans` are not vendored here. Use `$skill-installer` with an immutable commit URL, for example:

```text
$skill-installer install https://github.com/obra/superpowers/tree/b36e0829c6d0140e93cfef2ca599b1b07d4a7797/skills/brainstorming
$skill-installer install https://github.com/obra/superpowers/tree/b36e0829c6d0140e93cfef2ca599b1b07d4a7797/skills/writing-plans
```

The installed directory must contain the upstream `SKILL.md` unchanged. The helper accepts a repository, a path, and an explicit ref; this invocation names all three. Do not recreate any of these skills from this document or from a plan. Their provenance and licence are recorded in [runtime portability](runtime-portability.md#external-dependencies).

Confirm Codex picked up `brainstorming` without starting a session:

```sh
codex debug prompt-input | grep -o '[a-z:-]*brainstorming: [^(]*'
```

`codex debug prompt-input` renders the model-visible prompt locally and contacts no model provider. One matching line means the skill reached the `### Available skills` block Codex sends to the model.

## This repository

This repository's `skills/` tree is not automatically a Codex discovery root. Symlink the complete skill directories you intend to use into an official discovery location, or package them as a Codex plugin for reusable distribution. Keep the source checkout for updates and run its portability checker before installation.

### Skill names under Codex

Codex resolves a symlinked skill directory and, when the target sits inside a plugin repository, advertises the skill under that plugin's name. This checkout carries `.claude-plugin/plugin.json` with `name: scratchydisk-skills`, so **every** repository-local skill symlinked from here — `spec-to-ship`, `contract-audit`, `devils-advocate-loop`, `karpathy-guidelines`, `anti-ai-tells`, `plantuml-diagrams` — is advertised as `scratchydisk-skills:<id>` rather than bare `<id>`. External Superpowers skills installed outside this checkout are advertised as bare `<id>`. Copying a directory instead of symlinking it, or symlinking a target that sits outside a plugin repository, also gives the bare `<id>`.

| Installation | Advertised as |
| --- | --- |
| plain copy into a discovery location | `<id>` |
| symlink to a directory in this checkout | `scratchydisk-skills:<id>` |
| symlink to a target outside a plugin repository | `<id>` |

Every variant is discovered and loadable, and the `SKILL.md` `name` field is the bare `<id>` in all of them — only the identifier Codex advertises differs. This matters when one skill names another as a dependency: treat `scratchydisk-skills:<id>` as satisfying a requirement for `<id>`, so a skill that is present is not mistaken for a missing one.

Check what Codex actually advertises without starting a session:

```sh
codex debug prompt-input | grep -o '[a-z:-]*<id>: [^(]*'
```
