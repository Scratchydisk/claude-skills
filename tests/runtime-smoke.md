# Runtime smoke scenarios — spec-to-ship dependency handling

## Scope and method

`spec-to-ship` (`skills/spec-to-ship/SKILL.md`) is prose orchestration read by an
LLM, not an executable script. These scenarios check that prose mechanically —
each assertion is a `rg`/`grep` command run against the skill body, so a result
is a fact about the committed text (what any host's model will read), not a
simulated multi-hour pipeline run. Where a scenario's stage would, if actually
run, invoke `contract-audit` against a target artifact, the fixture it would use
is named for traceability; the fixture itself is not re-executed here.

Fixtures reused from Task 1 (`tests/fixtures/`):
- `incomplete-spec.md` — target for the spec-entry, 11-row contract audit.
- `flawed-plan.md` — target for the plan-entry, scoped C9/C10/C11 audit.

Every command below is run from the repository root.

## Scenarios

### S1 — Idea entry loads `brainstorming` as the first gate

```sh
rg -n 'start at `brainstorming`' skills/spec-to-ship/SKILL.md
```

Assert: the idea-entry bullet in Step 0 names `brainstorming` as the first
gate, by bare skill ID.

### S2 — Spec entry starts with the eleven-row spec contract audit

```sh
rg -n 'start at the \*\*spec contract-audit\*\*' skills/spec-to-ship/SKILL.md
```

Assert: the spec-entry bullet in Step 0 routes to the spec `contract-audit`
(all eleven rows; C1/C2/C3/C7/C9/C10/C11 blocking) before the spec DA-loop.
If this stage ran for real, its target would be `tests/fixtures/incomplete-spec.md`,
which is built to fail C1, C2, C7, C10, and C11.

### S3 — Plan entry starts with the scoped C9/C10/C11 plan audit, not the DA-loop

```sh
rg -n 'start at the \*\*plan contract-audit' skills/spec-to-ship/SKILL.md
rg -n 'start at the \*\*plan DA-loop\*\*' skills/spec-to-ship/SKILL.md   # must be absent
```

Assert: the plan-entry bullet in Step 0 routes to the plan `contract-audit`
scoped to C9+C10+C11 — never straight to the plan DA-loop, which would let an
existing plan bypass that audit. This is the named plan-entry failure mode:
an existing plan must not be able to skip C9/C10/C11. If this stage ran for
real, its target would be `tests/fixtures/flawed-plan.md`, which is built to
fail C9 (`approvalResult` vs `approval_result`), C10 (`approval-result`
produced, `approval_result` consumed), and C11 (one site claimed, two named).

### S4 — Missing `brainstorming` dependency stops explicitly

```sh
rg -n 'dependency-unavailable message naming `brainstorming`' skills/spec-to-ship/SKILL.md
rg -n 'requires <skill-id>, which is unavailable' skills/spec-to-ship/SKILL.md
```

Assert: the Brainstorm stage (Stage flow item 1) preflights `brainstorming`
before invoking it, and on failure stops with the required output —
`The next pipeline stage requires brainstorming, which is unavailable.` —
substituting `brainstorming` for `<skill-id>`. No fallback, no simulated
brainstorming session.

### S5 — Missing implementation dependency stops explicitly

```sh
rg -n 'dependency-unavailable message naming that skill' skills/spec-to-ship/SKILL.md
```

Assert: the Implement stage (Stage flow item 8) preflights the chosen
implementation skill (`subagent-driven-development`, or `executing-plans` if
the user prefers checkpointed execution) before invoking it, and on failure
stops with the required output naming that skill —
`The next pipeline stage requires subagent-driven-development, which is unavailable.`
(or `executing-plans`, whichever was chosen) — rather than reconstructing an
implementation from memory.

### S6 — Full pipeline gate order is preserved

```sh
rg -n '^[0-9]+\. \*\*' skills/spec-to-ship/SKILL.md
```

Assert: under "## Stage flow" the ten numbered gates appear in ascending order
1–10 with these labels, unchanged: Brainstorm, Spec contract-audit, Spec
DA-loop, Write the plan, Plan contract-audit (C9+C10+C11), Plan DA-loop,
Pre-implementation gate, Implement, Contract-audit: VERIFY, Run it for real.
This is a line-order comparison, not an eyeballed read.

### S7 — Dependencies are named by skill ID, never runtime call syntax

```sh
rg -n '^## Dependencies' skills/spec-to-ship/SKILL.md
rg -n 'Invoke [^`]*(Skill\(|skill\(\{)|invoking[^\n]*(Skill\(|skill\(\{)' skills/spec-to-ship/SKILL.md
rg -n '\.claude/skills|\.codex/skills|\.opencode/skills|\.config/opencode/skills' skills/spec-to-ship/SKILL.md skills/spec-to-ship/README.md
```

Assert: an explicit "## Dependencies" section exists; every actual invocation
site (`Invoke X` / `confirm X loads`) uses a bare backtick skill ID, never
`Skill(...)`, `skill({...})`, a slash-command form at an invocation site, or an
installation path (second and third commands: 0 matches each).

## Results

### RED (before this task's edit, commit `85fd3c8`)

| Scenario | Command | Result |
| --- | --- | --- |
| S1 | idea-entry grep | 1 match — already correct |
| S2 | spec-entry grep | 1 match — already correct |
| S3 | plan-entry `plan contract-audit` grep | **0 matches — FAIL.** Text instead read "start at the **plan DA-loop**", which would let an existing plan skip its C9/C10/C11 audit entirely. |
| S4 | brainstorming missing-dep grep | 0 matches — FAIL (no preflight, no stop text existed) |
| S4 | `<skill-id>` template grep | 0 matches — FAIL (no dependency-unavailable output defined anywhere) |
| S5 | implementation missing-dep grep | 0 matches — FAIL (no preflight, no stop text existed) |
| S6 | stage-order grep | 1–10 present and ordered correctly — already correct |
| S7 | `## Dependencies` section grep | 0 matches — FAIL (section did not exist) |
| S7 | call-syntax / install-path grep | 0 matches — already clean |

### GREEN (after this task's edit)

| Scenario | Command | Result |
| --- | --- | --- |
| S1 | idea-entry grep | 1 match — PASS |
| S2 | spec-entry grep | 1 match — PASS |
| S3 | plan-entry `plan contract-audit` grep | 1 match — PASS; old `plan DA-loop` text: 0 matches — PASS |
| S4 | brainstorming missing-dep grep | 1 match — PASS |
| S4 | `<skill-id>` template grep | 1 match — PASS |
| S5 | implementation missing-dep grep | 1 match — PASS |
| S6 | stage-order grep | 1–10 present, order and labels unchanged — PASS |
| S7 | `## Dependencies` section grep | 1 match — PASS |
| S7 | call-syntax / install-path grep | 0 matches — PASS |

`./scripts/check-portability.sh` after the edit: `PASS: 6 skills checked`.

## Per-host execution

| Host | Result | Notes |
| --- | --- | --- |
| Claude Code | PASS | All S1–S7 commands executed above via this session's shell; all GREEN results confirmed. |
| Codex | NOT RUN | The `codex` CLI (`codex-cli 0.151.0`) is present on this machine, but this repository's skills — including `spec-to-ship` and `brainstorming` — are not installed under Codex's `$HOME/.agents/skills` discovery path in this environment (only `arch-diagram` is present there), so the scenarios cannot be exercised through Codex here. Recorded as `NOT RUN`, not `PASS`. |
| OpenCode | NOT RUN | The `opencode` CLI (`1.18.25`) is present, but this repository's skills are not installed under `${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills` (only `code-review`, `dev`, `maxim-doctor`, `pm`, `sa`, `validate-epic` are present there), so the scenarios cannot be exercised through OpenCode here. Recorded as `NOT RUN`, not `PASS`. |

Task 6 extends this file for other skills; the scoped scenarios above are this
task's slice only.
