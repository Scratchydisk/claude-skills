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

## Install external skills

Use `$skill-installer` to request installation from a repository path. For the verified Superpowers `brainstorming` dependency, give it this immutable source URL:

```text
$skill-installer install https://github.com/obra/superpowers/tree/v6.3.0/skills/brainstorming
```

The installed directory must contain the upstream `SKILL.md` unchanged. The corresponding helper accepts a GitHub repository, a path, and an explicit ref; this invocation identifies all three. Do not recreate the skill from this document or from a plan.

For a manually verified checkout, a symlink to `skills/brainstorming` under `$HOME/.agents/skills/brainstorming` is the equivalent user-scope route. The canonical source, immutable revision, licence, and the status of related dependencies are recorded in [runtime portability](runtime-portability.md#external-dependencies).

## This repository

This repository's `skills/` tree is not automatically a Codex discovery root. Link or copy only the complete skill directories you intend to use into an official discovery location, or package them as a Codex plugin for reusable distribution. Keep the source checkout for updates and run its portability checker before installation.
