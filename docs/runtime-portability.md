# Runtime portability

The six directories under `skills/` are this repository's only canonical implementations. Runtime documentation may name a host's discovery path; reusable skill bodies must not contain one.

## External dependencies

The following provenance was verified from the local Superpowers checkout before any installation guidance was written.

- Canonical repository: `https://github.com/obra/superpowers.git`
- Immutable release: `v6.3.0`, commit `b36e0829c6d0140e93cfef2ca599b1b07d4a7797`
- Licence: MIT, copyright 2025 Jesse Vincent; retain the licence notice when copying substantial portions.

| Skill | Exact upstream directory | Provenance status | Codex discovery route | OpenCode discovery route |
| --- | --- | --- | --- | --- |
| `brainstorming` | `skills/brainstorming/` | verified | `$HOME/.agents/skills/brainstorming` or `$skill-installer` from the immutable URL | `${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills/brainstorming` |
| `writing-plans` | `skills/writing-plans/` | verified; not installed by this repository | `$HOME/.agents/skills/writing-plans` | `${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills/writing-plans` |
| `subagent-driven-development` | `skills/subagent-driven-development/` | verified; not installed by this repository | `$HOME/.agents/skills/subagent-driven-development` | `${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills/subagent-driven-development` |
| `executing-plans` | `skills/executing-plans/` | verified; not installed by this repository | `$HOME/.agents/skills/executing-plans` | `${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills/executing-plans` |

The verified checkout was locally modified only by a deleted `AGENTS.md`; the tag and commit above, rather than its working-tree state, define the source. No external dependency has been copied into this repository. A missing external dependency stops the dependent workflow; it must not be reconstructed from memory.

## Dependency map

```text
repository-local: contract-audit, devils-advocate-loop,
                  spec-to-ship, karpathy-guidelines, anti-ai-tells,
                  plantuml-diagrams

external (verified, not vendored): brainstorming, writing-plans,
                                   subagent-driven-development,
                                   executing-plans
```

`spec-to-ship` depends on `brainstorming` for idea work, `writing-plans` for plan creation, and an implementation skill for the implementation stage. `subagent-driven-development` and `executing-plans` are alternative implementation skills. The repository-local skills remain sourced from this checkout; the four external skills remain sourced from the verified upstream release above.

## Pre-edit inventory

Before these runtime documents were added, the required inventory command returned 17 matching lines:

```sh
rg -n -i 'Claude Code tool|Read tool|Edit tool|Glob|Task tool|\.claude/skills|\.codex/skills|\.opencode/skills|\.config/opencode/skills' skills README.md docs scripts
```

| Classification | Pre-edit sites | Reason |
| --- | ---: | --- |
| Intentional documentation and enforcement | 13 | Two review documents, the implementation plan, and the checker enumerate host terms or paths deliberately. |
| Warning candidates | 4 | `Glob` matched ordinary uses of “global” in bundled reference material; the checker does not flag those as host wording. |
| Hard violations | 0 | No reusable `skills/*/SKILL.md` contains a runtime installation path. |

The checker treats runtime paths in reusable skill bodies as failures and host-tool terminology there as warnings:

```sh
./scripts/check-portability.sh
```

## Post-edit verification baseline

The final inventory is recorded after the documentation edit and must be refreshed with the command above whenever this scope changes. Its current count is **23** matching lines. Every new path mention in these runtime documents is intentional documentation; it is not a reusable skill-body exception.
