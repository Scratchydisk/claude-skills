# Runtime portability

The seven directories under `skills/` are this repository's only canonical implementations; there is no per-runtime copy of any skill. Six are written here. The seventh, `brainstorming`, is an unmodified upstream copy kept under its own licence — see [external dependencies](#external-dependencies). Runtime documentation may name a host's discovery path; reusable skill bodies must not contain one.

## External dependencies

Provenance was re-verified against a fresh fetch of the upstream repository, not against a cached copy.

- Canonical repository: `https://github.com/obra/superpowers.git`
- Immutable revision: `b36e0829c6d0140e93cfef2ca599b1b07d4a7797`. The annotated tag `v6.3.0` dereferences to this commit (`git ls-remote https://github.com/obra/superpowers.git refs/tags/v6.3.0^{}`), so the commit, not the tag name, is what every command here pins.
- Licence: MIT, copyright 2025 Jesse Vincent. The notice travels with any copy.

| Skill | Exact upstream directory | Status here | Claude Code route | Codex discovery route | OpenCode discovery route |
| --- | --- | --- | --- | --- | --- |
| `brainstorming` | `skills/brainstorming/` | vendored unmodified at `skills/brainstorming/` | official Superpowers plugin marketplace, or this repository's own plugin | `$HOME/.agents/skills/brainstorming` symlinked to `skills/brainstorming` | `./scripts/install-opencode.sh` links it with the other canonical skills |
| `writing-plans` | `skills/writing-plans/` | verified; not vendored | official Superpowers plugin marketplace | `$HOME/.agents/skills/writing-plans`, or `$skill-installer` from the immutable URL | `${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills/writing-plans` |
| `subagent-driven-development` | `skills/subagent-driven-development/` | verified; not vendored | official Superpowers plugin marketplace | `$HOME/.agents/skills/subagent-driven-development` | `${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills/subagent-driven-development` |
| `executing-plans` | `skills/executing-plans/` | verified; not vendored | official Superpowers plugin marketplace | `$HOME/.agents/skills/executing-plans` | `${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills/executing-plans` |

For Claude Code, the verified source records this official marketplace route for all four skills:

```text
/plugin install superpowers@claude-plugins-official
```

### Why `brainstorming` is vendored and the other three are not

`brainstorming` is the first gate of `spec-to-ship`'s idea entry, so this repository's own workflow stops without it. It cleared three gates before import: provenance re-verified against a fresh fetch at the pinned commit; MIT licence permitting redistribution with notice; and the unedited upstream source discovered and loaded by all three hosts. The complete upstream directory was copied — all eight files, never `SKILL.md` alone — plus the upstream `LICENSE`. [`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md) records the per-file checksums and the command that re-verifies the copy against upstream.

The other three are named by `spec-to-ship` but none of their files is read by anything in this repository, so there is nothing here to vendor them for. Documenting their installation is enough. They would need the same three gates to clear before any future import.

A missing external dependency stops the dependent workflow. It must not be reconstructed from memory.

## Dependency map

```text
repository-local: contract-audit, devils-advocate-loop,
                  spec-to-ship, karpathy-guidelines, anti-ai-tells,
                  plantuml-diagrams

vendored upstream (MIT, unmodified): brainstorming

external (verified, not vendored): writing-plans,
                                   subagent-driven-development,
                                   executing-plans
```

`spec-to-ship` depends on `brainstorming` for idea work, `writing-plans` for plan creation, and an implementation skill for the implementation stage. `subagent-driven-development` and `executing-plans` are alternative implementation skills. The repository-local and vendored skills are sourced from this checkout; the three remaining external skills are sourced from the upstream revision above.

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

Refresh the inventory with the command above whenever this scope changes. Its current count is **21** matching lines, and `./scripts/check-portability.sh` reports `PASS: 7 skills checked`. Every path mention in these runtime documents is intentional documentation; it is not a reusable skill-body exception.

This line read **23** until now. That figure was written during the first documentation pass and was already stale when the same task's follow-up commit `41de057` rewrote two `docs/opencode.md` lines so the literal path they contained no longer appeared contiguously — a two-line drop to 21, recorded in `tests/runtime-smoke.md` but not corrected here until this edit. Vendoring `brainstorming` added nothing: the upstream files contain none of these terms, which is one of the reasons the import passed the portability gate unmodified.

## Host verification

`brainstorming` was imported only after the unedited upstream source was shown to load on every host. Each check runs locally and contacts no model provider:

```sh
# OpenCode — lists what it actually discovers
opencode debug skill | jq -r '.[] | select(.name=="brainstorming") | .location'

# Codex — renders the model-visible prompt, including its skill registry
codex debug prompt-input | grep -o '[a-z:-]*brainstorming: [^(]*'
```

Claude Code needs no such command here: the official `superpowers` plugin at this same commit is installed in the environment where the import was made, and its `brainstorming` directory is byte-identical to the fetched upstream source. `tests/runtime-smoke.md` records the per-host results and the exact commands.
