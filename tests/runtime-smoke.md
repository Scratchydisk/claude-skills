# Runtime smoke scenarios — canonical skills

## Scope and method

Every canonical skill under `skills/` (`contract-audit`, `devils-advocate-loop`,
`karpathy-guidelines`, `plantuml-diagrams`, `spec-to-ship`, `anti-ai-tells`) is
prose read by an LLM, not an executable script (`plantuml-diagrams` names an
external renderer CLI, but the skill body itself is still prose instruction).
These scenarios check that prose mechanically — each assertion is a `rg`/`grep`
command run against the skill body, so a result is a fact about the committed
text (what any host's model will read), not a simulated multi-hour pipeline
run. Where a scenario's stage would, if actually run, invoke `contract-audit`
against a target artifact, the fixture it would use is named for traceability;
the fixture itself is not re-executed here.

S1–S7 below (Task 5) cover `spec-to-ship`'s dependency handling. S8 onward
(Task 6) cover the remaining canonical skills: `contract-audit`'s C1/C10
failure detection, `devils-advocate-loop`'s minimum-round and escalation
semantics, `plantuml-diagrams`'s render-plus-visual-inspection requirement,
and `karpathy-guidelines`/`anti-ai-tells` unchanged across hosts. Task 6 edits
no skill body — every S8+ assertion is evidence about text that already
existed unmodified.

Fixtures reused from Task 1 (`tests/fixtures/`):
- `incomplete-spec.md` — target for the spec-entry, 11-row contract audit;
  built to fail C1 (`Cell` named, no fields), C2, C7, C10 (`business_owner_person_id`
  consumed, no producer), and C11.
- `flawed-plan.md` — target for the plan-entry, scoped C9/C10/C11 audit; built
  to fail C9, C10 (`approval_result` consumed by Task 3, only `approval-result`
  produced by Task 2), and C11.

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

### S8 — `contract-audit` C1 detects a data structure named without fields

```sh
rg -n '^### C1 — Data-structure fields' skills/contract-audit/SKILL.md
rg -n 'FAIL when:\*\* a structure is named in a diagram or file tree with only a prose gloss' skills/contract-audit/SKILL.md
```

Assert: C1's heading and FAIL condition are defined exactly as committed. If
this row ran for real against `tests/fixtures/incomplete-spec.md`, it names a
`Cell` structure ("The map contains a `Cell`") and never lists a field, which
is precisely the documented FAIL shape — not an N/A, per the skill's own core
rule that "a component named but never defined is a FAIL, not an N/A."

### S9 — `contract-audit` C10 detects a consumed value with no named producer, and the blocking set is exact

```sh
rg -n '^### C10 — Producer/consumer closure' skills/contract-audit/SKILL.md
rg -n 'FAIL when:\*\* the spec names something that consumes a value and never says what puts the value there' skills/contract-audit/SKILL.md
rg -n '^### C(1[01]|[1-9]) — ' skills/contract-audit/SKILL.md
rg -n 'All seven blocking rows — C1, C2, C3, C7, C9, C10, C11 — block' skills/contract-audit/SKILL.md
rg -n 'Any FAIL in C1, C2, C3, C7, C9, C10 or C11 means not ready' skills/contract-audit/SKILL.md
```

Assert: C10's heading and FAIL condition are defined exactly as committed; all
eleven `### C<n> — <name>` headings (C1–C11) are present in ascending order;
and the blocking set is asserted in both the silence-test paragraph and the
Mode A closing line, each naming the same seven contracts — `C1, C2, C3, C7,
C9, C10, C11` (comma-joined) and `C1, C2, C3, C7, C9, C10 or C11`
(comma-joined with a trailing "or") respectively — C4, C5, C6, C8 are the
remaining four, non-blocking/informational rows. If C10 ran for real against
`incomplete-spec.md`, it reads
`business_owner_person_id` consumed with no producer named anywhere in the
fixture, which is the documented FAIL shape; against `flawed-plan.md`, Task 3
consumes `approval_result` while Task 2 only produces `approval-result` — a
set difference over `Consumes:`/`Produces:` blocks, not a judgement call, per
the skill's own "on a plan this is mechanical" method note.

### S10 — `devils-advocate-loop` enforces a minimum of two rounds regardless of round-1 outcome

```sh
rg -n '\*\*Minimum 2 rounds\.\*\* Even if round 1 finds nothing, do round 2' skills/devils-advocate-loop/SKILL.md
rg -n '\*\*Maximum 5 rounds\.\*\* After 5, stop regardless' skills/devils-advocate-loop/SKILL.md
rg -n 'If this was round 1, do one more round to confirm' skills/devils-advocate-loop/SKILL.md
```

Assert: the minimum-2/maximum-5 bounds are stated verbatim in Core rules, and
the per-round stop decision (step 6) restates the floor — a clean round 1 does
not end the loop early. This is host-independent: nothing in the bound depends
on which tool invoked the skill.

### S11 — `devils-advocate-loop` escalation is off by default and gated by an explicit triple-AND test

```sh
rg -n '^## Escalation mode \(optional — off by default\)' skills/devils-advocate-loop/SKILL.md
rg -n 'Default is fix-inline\. Escalation is the rare exception' skills/devils-advocate-loop/SKILL.md
rg -n 'Escalate ONLY when all three hold:' skills/devils-advocate-loop/SKILL.md
rg -n 'Never chain escalations\.' skills/devils-advocate-loop/SKILL.md
```

Assert: escalation mode is explicitly optional and off unless a caller (e.g.
`spec-to-ship`) enables it; the three-condition AND test for what qualifies as
an escalation is stated, along with the no-chaining rule. None of this
prose names or depends on a host tool.

### S12 — `plantuml-diagrams` requires render plus visual inspection, never `-checkonly` alone

```sh
rg -n 'render it and inspect the picture' skills/plantuml-diagrams/SKILL.md
rg -n 'Inspect the rendered output at its intended size' skills/plantuml-diagrams/SKILL.md
rg -n 'Never claim success from `-checkonly` alone' skills/plantuml-diagrams/SKILL.md
rg -n -i 'Claude Code tool|Read tool|Edit tool|Glob|Task tool|\.claude/skills|\.codex/skills|\.opencode/skills|\.config/opencode/skills' skills/plantuml-diagrams/SKILL.md
```

Assert: the skill states up front that parsing is necessary but not
sufficient ("render it and inspect the picture"), repeats the same requirement
under "Render and iterate" ("Inspect the rendered output at its intended
size"), and closes with an explicit ban on treating `-checkonly` as a
completion standard. The renderer invocation (`java -jar plantuml.jar ...`) is
a generic external CLI, not a Claude Code tool call, and the fourth command
confirms zero host-tool-phrase or runtime-install-path matches anywhere in the
skill body.

### S13 — `karpathy-guidelines` is unchanged and host-neutral

```sh
rg -n -i 'Claude Code tool|Read tool|Edit tool|Glob|Task tool|\.claude/skills|\.codex/skills|\.opencode/skills|\.config/opencode/skills' skills/karpathy-guidelines/SKILL.md
rg -n '^name: karpathy-guidelines$' skills/karpathy-guidelines/SKILL.md
rg -n '^description:' skills/karpathy-guidelines/SKILL.md
```

Assert: this behavioural-guideline skill (consulted during other work, not a
staged pipeline) contains zero host-tool phrases or runtime install paths, and
its frontmatter loads (`name`/`description` present, `name` matching the
directory per `check_frontmatter` in `scripts/check-portability.sh`). No edit
was made to this file for this task; the smoke case is that it needs none —
`./scripts/check-portability.sh` (S15 below) confirms it independently.

### S14 — `anti-ai-tells` is unchanged and host-neutral

```sh
rg -n -i 'Claude Code tool|Read tool|Edit tool|Glob|Task tool|\.claude/skills|\.codex/skills|\.opencode/skills|\.config/opencode/skills' skills/anti-ai-tells/SKILL.md
rg -n '^name: anti-ai-tells$' skills/anti-ai-tells/SKILL.md
rg -n '^description:' skills/anti-ai-tells/SKILL.md
```

Assert: same as S13 — zero host-tool phrases or runtime install paths, valid
loadable frontmatter, no edit needed. `anti-ai-tells` has no `## Dependencies`
section and names no other skill, consistent with it being a standalone
self-review pass rather than a pipeline stage.

### S15 — Structural portability checker passes for all six skills

```sh
./scripts/check-portability.sh
```

Assert: exit 0 and `PASS: <n> skills checked`, where `<n>` is every skill
directory under `skills/` — each has valid frontmatter, no runtime install path
in its body, and only warning-level (not blocking) host-tool-phrase matches, if
any. This read `6` when Task 6 recorded it (`contract-audit`,
`devils-advocate-loop`, `karpathy-guidelines`, `plantuml-diagrams`,
`spec-to-ship`, `anti-ai-tells`) and reads `7` from Task 7 onward, once
`brainstorming` was vendored.

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

### Task 6 re-run of S1–S7 (unchanged since Task 5)

| Scenario | Command | Result |
| --- | --- | --- |
| S1 | idea-entry grep | 1 match — PASS |
| S2 | spec-entry grep | 1 match — PASS |
| S3 | plan-entry grep (both halves) | 1 match / 0 matches — PASS |
| S4 | brainstorming missing-dep + template grep | 1 match / 1 match — PASS |
| S5 | implementation missing-dep grep | 1 match — PASS |
| S6 | stage-order grep | 1–10 present, order and labels unchanged — PASS |
| S7 | `## Dependencies` + call-syntax/install-path grep | 1 match / 0 matches / 0 matches — PASS |

No regression: Task 6 makes no edit to `skills/spec-to-ship/SKILL.md`, and the
re-run above confirms the text these assertions read is unchanged since
commit `19b1b4a`.

### Task 6 direct assertions (S8–S15) — no skill body edited, no RED state

These scenarios have no before/after: Task 6 does not edit `contract-audit`,
`devils-advocate-loop`, `plantuml-diagrams`, `karpathy-guidelines`, or
`anti-ai-tells`. Each row is a direct assertion against the committed text
that already existed before this task started.

| Scenario | Command | Result |
| --- | --- | --- |
| S8 | C1 heading grep | 1 match — PASS |
| S8 | C1 FAIL-condition grep | 1 match — PASS |
| S9 | C10 heading grep | 1 match — PASS |
| S9 | C10 FAIL-condition grep | 1 match — PASS |
| S9 | all-eleven-headings grep | 11 matches, C1–C11 ascending — PASS |
| S9 | blocking-set grep (silence-test paragraph) | 1 match, `C1, C2, C3, C7, C9, C10, C11` — PASS |
| S9 | blocking-set grep (Mode A closing line) | 1 match, same seven — PASS |
| S10 | minimum-2-rounds grep | 1 match — PASS |
| S10 | maximum-5-rounds grep | 1 match — PASS |
| S10 | round-1-confirm grep | 1 match — PASS |
| S11 | escalation-mode-heading grep | 1 match — PASS |
| S11 | default-fix-inline grep | 1 match — PASS |
| S11 | triple-AND-test grep | 1 match — PASS |
| S11 | no-chaining grep | 1 match — PASS |
| S12 | render-and-inspect grep | 1 match — PASS |
| S12 | inspect-rendered-output grep | 1 match — PASS |
| S12 | never-checkonly-alone grep | 1 match — PASS |
| S12 | host-tool-phrase/install-path grep | 0 matches — PASS |
| S13 | host-tool-phrase/install-path grep | 0 matches — PASS |
| S13 | `name:` frontmatter grep | 1 match — PASS |
| S13 | `description:` frontmatter grep | 1 match — PASS |
| S14 | host-tool-phrase/install-path grep | 0 matches — PASS |
| S14 | `name:` frontmatter grep | 1 match — PASS |
| S14 | `description:` frontmatter grep | 1 match — PASS |
| S15 | `./scripts/check-portability.sh` | exit 0, `PASS: 6 skills checked` — PASS |

### Step 3 hard-stop check

None of S8–S15 revealed a semantic incompatibility. `plantuml-diagrams` names
a generic external CLI (`java -jar plantuml.jar`), not a Claude-Code-specific
primitive — a missing `java`/PlantUML JAR here is a missing host binary
(`NOT RUN`), not a semantic incompatibility, exactly like Codex/OpenCode not
having this repo's skills installed under their discovery paths (S1–S7's
existing `NOT RUN` precedent). No skill body needed editing; Step 3's stop
condition was not triggered.

### Inventory reconciliation against Task 4's baseline

```sh
rg -n -i 'Claude Code tool|Read tool|Edit tool|Glob|Task tool|\.claude/skills|\.codex/skills|\.opencode/skills|\.config/opencode/skills' skills README.md docs scripts | wc -l
```

This command currently returns **21**, not the 23 recorded as Task 4's
"current count" in `docs/runtime-portability.md`. The drift is fully
accounted for and predates both Task 5 and this task:

- At commit `542ec70` (Task 4's original documentation commit, where the 23
  baseline was recorded), the count was 23.
- At commit `41de057` (Task 4's own **fix round 1**, applied in the same task
  but after the baseline line in `docs/runtime-portability.md` was written),
  the count dropped to **21** and has stayed there since. The fix replaced
  `docs/opencode.md`'s two manual-uninstall/manual-symlink lines that
  literally contained `.config/opencode/skills` —
  `mkdir -p "$HOME/.config/opencode/skills"` and
  `ln -s /path/to/superpowers/skills/brainstorming "$HOME/.config/opencode/skills/brainstorming"`
  — with a collision-checked script whose destination path is built from
  `config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}` and
  `destination_dir="$config_home/opencode/skills"` on separate lines, so the
  literal substring `.config/opencode/skills` no longer appears contiguously
  anywhere in the file. This is a two-line decrease (23 → 21), confirmed by
  per-file `rg -c` counts at both commits: `docs/opencode.md` drops from 4
  matches to 2; every other matched file's count is unchanged between the two
  commits.
- Commit `19b1b4a` (Task 5) made no edit to `docs/` and did not change the
  count: still 21.
- This task (Task 6) edits only `tests/runtime-smoke.md`, which is not one of
  the five scanned trees (`skills README.md docs scripts`), so it cannot
  change the count either: still 21 after this task's commit.

`docs/runtime-portability.md`'s "Post-edit verification baseline" line (currently
reading "23") is stale relative to Task 4's own later fix-round commit — this
predates Task 5 and Task 6 and is out of this task's scope to edit (Task 6's
brief modifies only `tests/runtime-smoke.md`), so it is recorded here rather
than corrected in place.

The four pre-existing `Glob`-matches-"global" warning candidates remain
present and are unrelated to the count change above: two in
`skills/devils-advocate-loop/references/blind-spots.md` (lines 286–287) and
two in `skills/devils-advocate-loop/references/ai-blind-spots.md` (lines 191,
323) — all four are ordinary uses of the English word "global" inside bundled
reference material, matched case-insensitively by the `Glob` alternative in
the inventory regex, exactly as `docs/runtime-portability.md` already
documents for a different set of four lines. `./scripts/check-portability.sh`
treats these as warnings, not errors, and the script exits 0 regardless (see
S15).

### C1–C11 heading and blocking-set verification (Step 5)

```sh
rg -n '^### C(1[01]|[1-9]) — ' skills/contract-audit/SKILL.md
```

Returns 11 lines, `### C1 — Data-structure fields` through
`### C11 — Site completeness`, in ascending order — every contract heading is
present and unrenumbered.

```sh
rg -n 'C1, C2, C3, C7, C9, C10, C11' skills/contract-audit/SKILL.md
```

Returns 1 match — the silence-test paragraph, which states the blocking set
as the literal comma-joined string `C1, C2, C3, C7, C9, C10, C11`. The Mode A
closing line states the same seven-member set using "or" before the last
member (`C1, C2, C3, C7, C9, C10 or C11`) rather than a final comma, so it is
a second, differently-punctuated citation of the identical set, not a second
match of this exact string — confirmed independently by S9's two separate
exact-string greps above (`All seven blocking rows — ...` and `Any FAIL in
C1, C2, C3, C7, C9, C10 or C11 means not ready`, each 1 match). Both
citations agree on the same seven contracts. C4 (shared constants), C5
(ambiguous field meanings), C6 (observable acceptance criteria), and C8
(toolchain coherence) are confirmed as the remaining four,
non-blocking/informational rows — present as headings but absent from both
blocking-set citations above.

## Per-host execution

| Host | Result | Notes |
| --- | --- | --- |
| Claude Code | PASS | All S1–S15 commands executed above via this session's shell; all results confirmed as tabulated. |
| Codex | PASS | Closed by S17 below (Task 8). Was `NOT RUN` through Task 6 because this repository's skills were not installed under any Codex discovery path in this environment. S17 installs them into a sandboxed repo-scoped `.agents/skills` and confirms via `codex debug prompt-input` that Codex advertises all seven, each pointing at a file byte-identical to the committed `SKILL.md` these assertions read. |
| OpenCode | PASS | Closed by S17 below (Task 8). Was `NOT RUN` through Task 6 for the same reason. S17 installs them into a sandboxed `${XDG_CONFIG_HOME}/opencode/skills` via this repository's own installer and re-runs every S1–S15 assertion against the bodies OpenCode actually loaded, not against the repository files. |

All S1–S15 scenarios are `rg`/script commands run directly against committed
text or the repository's own checker, so the Claude Code row above is this
session's shell, not a claim about Claude Code's runtime behaviour
specifically — the same commands would produce the same results in any shell
with `rg` and `git` on `PATH`, on any host. What S17 adds for the other two
hosts is the missing half: that each host's own discovery machinery finds
these skills and hands its model the same text these assertions read.

## S16 (Task 7) — hosts load the unedited upstream `brainstorming`

Unlike S1–S15, this scenario is not a grep over committed text. It runs each
host's own discovery machinery against the unedited upstream source and asks
whether the host actually loads it, because Task 7 imports that source into
this repository only if it does. Every command below is non-interactive and
contacts no model provider, so no row costs provider credits.

### Sandboxing

No check writes to this machine's real `$HOME/.agents/skills` or its real
`${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills`. OpenCode is pointed at a
temporary config tree with `XDG_CONFIG_HOME`; Codex is run from a temporary
git repository whose `.agents/skills` holds the skill, with `HOME` and
`CODEX_HOME` both redirected to temporary paths.

### Provenance the scenario depends on

```sh
git ls-remote https://github.com/obra/superpowers.git HEAD refs/tags/v6.3.0^{}
```

Both refs return `b36e0829c6d0140e93cfef2ca599b1b07d4a7797`, so the annotated
tag `v6.3.0` and current `HEAD` agree on the pinned commit. The source used
below is a fresh fetch of that commit, not a cached copy. `skills/brainstorming/`
at that commit holds exactly eight files, and all eight were imported together.

### Controls

Each host was measured twice: once with no `brainstorming` installed, once with
it installed. A row counts as PASS only if the skill is absent in the first
measurement and present in the second, which is what rules out the host having
found some pre-existing copy elsewhere on the machine.

| Host | Result | Command and evidence |
| --- | --- | --- |
| Claude Code | PASS | The official `superpowers` plugin (`6.3.0`, same commit) is installed and live in the environment where this import was made; its `brainstorming` skill loads by ID. `diff -r` between the plugin's `skills/brainstorming/` and the fresh upstream fetch reports no differences, so the live, loadable skill and the imported source are the same bytes. No installation or sandboxing was needed. |
| OpenCode | PASS | `opencode` `1.18.25`. `XDG_CONFIG_HOME=<sandbox> opencode debug skill` lists `brainstorming` at the sandboxed `SKILL.md`, with its upstream description and a 15,120-byte body. The control run against an empty sandbox config lists only `customize-opencode` and `arch-diagram` — no `brainstorming` — and neither run shows the six skills in the real config, confirming the sandbox held. The discovered name is bare `brainstorming`, matching its directory and its `name` frontmatter field, and satisfying `^[a-z0-9]+(-[a-z0-9]+)*$`. |
| Codex | PASS | `codex-cli` `0.151.0`. This version has no "list discovered skills" subcommand, but `codex debug prompt-input` renders the model-visible prompt locally, and that prompt contains Codex's own skill registry. With the skill at `.agents/skills/brainstorming`, the rendered `### Available skills` block gains the line `- brainstorming: You MUST use this before any creative work … (file: r1/brainstorming/SKILL.md)`, and a new skill root `r1` pointing at the sandboxed `.agents/skills`. The control run without the skill contains zero occurrences of `brainstorm`. |

### Codex names a symlinked skill after the plugin that owns its target

Worth recording because it surprises: Codex resolves a symlinked skill
directory and, if the resolved target sits inside a plugin repository, prefixes
the advertised name with that plugin's name. Three variants, same skill body:

| Installation | Advertised as |
| --- | --- |
| plain copy into `.agents/skills/` | `brainstorming` |
| symlink to `skills/brainstorming` in this checkout | `scratchydisk-skills:brainstorming` |
| symlink to a copy outside any plugin repository | `brainstorming` |

This checkout carries `.claude-plugin/plugin.json` with `name: scratchydisk-skills`,
which is where the prefix comes from. All three are discovered and loadable, and
the `SKILL.md` `name` field is `brainstorming` in every case — only the
identifier Codex advertises differs.

The behaviour is not specific to `brainstorming`. `docs/codex.md` recommends
symlinking this repository's skill directories into a Codex discovery location,
so every skill installed that way is advertised as `scratchydisk-skills:<id>`.
Confirmed rather than assumed: all seven `skills/` directories were symlinked
into one sandboxed `.agents/skills` and `codex debug prompt-input` advertised
every one of them prefixed — `scratchydisk-skills:anti-ai-tells`,
`…:brainstorming`, `…:contract-audit`, `…:devils-advocate-loop`,
`…:karpathy-guidelines`, `…:plantuml-diagrams`, `…:spec-to-ship`.
It is documented repo-wide under "Skill names under Codex" in `docs/codex.md`,
and `skills/spec-to-ship/SKILL.md` now tells its dependency preflight to accept
`<anything>:<id>` for a bare `<id>`, so a present skill is not misreported as
the hard unavailable stop.

### Post-import verification

Run after the import, from the repository root:

| Check | Result |
| --- | --- |
| `./scripts/check-portability.sh` | exit 0, `PASS: 7 skills checked` |
| `bash tests/test-check-portability.sh` | exit 0, all portability contract tests passed |
| `bash tests/test-install-opencode.sh` | exit 0, all OpenCode installer contract tests passed |
| `./scripts/install-opencode.sh --dry-run` | 7 `WOULD_LINK` lines, now including `brainstorming` |
| inventory `rg … \| wc -l` | 21, unchanged by the import — the upstream files contain none of the scanned terms |

The imported skill passed the portability checker with no edit: its frontmatter
`name` is `brainstorming`, matching its directory; a `description` is present;
and it contains none of the forbidden runtime paths or host-tool phrases. Step 3's
adaptation branch was therefore not taken, and no upstream file was modified.

## S17 (Task 8) — Codex and OpenCode load every canonical skill

S1–S15 recorded `NOT RUN` for Codex and OpenCode because this repository's
skills were not installed under either host's discovery path in this
environment. That was a missing installation, not a missing capability: S16
proved the sandboxed host-testing technique works here. S17 applies the same
technique to all seven skills and closes those two columns.

What S17 does and does not claim: it establishes that each host's own discovery
machinery finds every skill and hands its model the same committed text S1–S15
assert over. It is not a live model conversation through each pipeline — no row
here contacts a model provider, exactly as no S1–S15 row did.

### Sandboxing

Binding, and verified each time. Nothing here writes to this machine's real
`/home/stewart/.agents/skills` or its real
`${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills`. OpenCode is pointed at a
temporary tree with `XDG_CONFIG_HOME`; Codex runs from a temporary git
repository whose `.agents/skills` holds the symlinks, with `HOME` and
`CODEX_HOME` both redirected to temporary paths.

Both real directories were listed and hashed before and after every run:

```sh
find "$HOME/.agents" "${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills" -maxdepth 3 | sort | sha256sum
```

Identical before and after — `2d7b061c…` both times. The real
`~/.agents/skills` still holds only `arch-diagram`; the real OpenCode skills
directory still holds only `code-review`, `dev`, `maxim-doctor`, `pm`, `sa`,
`validate-epic`. Neither set appears in any sandboxed run, which is the second,
independent confirmation that the sandbox held.

### S17a — OpenCode discovers all seven, and the bodies it loads are the asserted text

Installed with this repository's own installer, against a temporary config root
(the same sandbox as the Step 2 idempotency check):

```sh
XDG_CONFIG_HOME=<sandbox> ./scripts/install-opencode.sh
XDG_CONFIG_HOME=<sandbox> opencode debug skill | jq -r '.[] | "\(.name)\t\(.content|length)\t\(.location)"'
```

Control first, against an empty config root: `opencode debug skill` lists only
`customize-opencode` (built-in) and `arch-diagram`. `arch-diagram` comes from
OpenCode's external-skill scan of the real `~/.claude/skills` and
`~/.agents/skills`, which `XDG_CONFIG_HOME` does not govern — it is reported
from whichever of the two the scan reaches first, and both runs are read-only.
None of this repository's skills appear. After installing, the same command
returns nine entries — those two plus all seven, each located under the
sandbox:

| Skill | Advertised name | Loaded body |
| --- | --- | ---: |
| `anti-ai-tells` | `anti-ai-tells` | 13,792 B |
| `brainstorming` | `brainstorming` | 15,120 B |
| `contract-audit` | `contract-audit` | 22,219 B |
| `devils-advocate-loop` | `devils-advocate-loop` | 9,724 B |
| `karpathy-guidelines` | `karpathy-guidelines` | 2,226 B |
| `plantuml-diagrams` | `plantuml-diagrams` | 3,977 B |
| `spec-to-ship` | `spec-to-ship` | 17,898 B |

Every name is bare — no host prefix — matching its directory and its `name`
frontmatter field, and satisfying `^[a-z0-9]+(-[a-z0-9]+)*$`. That OpenCode
reports a `name` and `description` at all is itself the host-side confirmation
of S13's and S14's frontmatter assertions, which cannot be re-run against a
body with its frontmatter already consumed.

`opencode debug skill` returns each skill's full `content`, so the S1–S15
assertions were re-run against what OpenCode loaded rather than against the
repository files. Each loaded body is byte-identical to its committed
`SKILL.md` with frontmatter stripped, and every assertion returns the same
count as the Claude Code column:

| Scenario | Assertion re-run against the OpenCode-loaded body | Count | Result |
| --- | --- | ---: | --- |
| S1 | idea-entry names `brainstorming` | 1 | PASS |
| S2 | spec-entry spec contract-audit | 1 | PASS |
| S3 | plan-entry plan contract-audit | 1 | PASS |
| S3 | old `plan DA-loop` text (must be 0) | 0 | PASS |
| S4 | `brainstorming` dependency-unavailable | 1 | PASS |
| S4 | `<skill-id>` stop template | 1 | PASS |
| S5 | implementation dependency-unavailable | 1 | PASS |
| S6 | stage flow 1–10, labels and order | 10 under `## Stage flow` (12 whole-body, incl. Step 0's two) | PASS |
| S7 | `## Dependencies` section | 1 | PASS |
| S7 | call syntax / install paths (must be 0) | 0 / 0 | PASS |
| S8 | C1 heading, C1 FAIL condition | 1 / 1 | PASS |
| S9 | C10 heading; C1–C11 headings; both blocking-set citations | 1 / 11 / 1 / 1 | PASS |
| S10 | minimum-2 and maximum-5 round bounds | 1 / 1 | PASS |
| S11 | escalation off by default; triple-AND test; no chaining | 1 / 1 / 1 | PASS |
| S12 | render-and-inspect; never `-checkonly` alone; host phrases (0) | 1 / 1 / 0 | PASS |
| S13 | `karpathy-guidelines` host phrases / install paths (must be 0) | 0 | PASS |
| S14 | `anti-ai-tells` host phrases / install paths (must be 0) | 0 | PASS |

S6's stage flow reads, in order: Brainstorm, Spec contract-audit, Spec DA-loop,
Write the plan, Plan contract-audit (C9 + C10 + C11), Plan DA-loop,
Pre-implementation gate, Implement, Contract-audit: VERIFY, Run it for real —
unchanged, in the copy OpenCode loaded.

The S12/S13/S14 host-phrase rows use the full inventory regex including the
`Glob` alternative, case-insensitively, and return 0 for all seven loaded
bodies — not just the three skills those scenarios name. The four known
`Glob`-matches-"global" warning candidates live in
`skills/devils-advocate-loop/references/`, which is bundled reference material
rather than a `SKILL.md` body, so they are outside what a host loads up front
and outside these counts.

**OpenCode: PASS.**

### S17b — Codex advertises all seven from its own discovery path

```sh
# from a temporary git repository with the seven skills symlinked into .agents/skills
HOME=<sandbox> CODEX_HOME=<sandbox> codex debug prompt-input
```

Control first, from the same temporary repository with an empty
`.agents/skills`: the rendered `<skills_instructions>` block declares one skill
root (`r0`, Codex's own `.system` directory) and advertises only Codex's five
built-ins — `imagegen`, `openai-docs`, `plugin-creator`, `skill-creator`,
`skill-installer`. Zero occurrences of `scratchydisk-skills`.

After symlinking, the same block gains a second root, `r1`, pointing at the
sandboxed `.agents/skills`, and advertises all seven with their committed
descriptions:

| Advertised name | Path in the rendered prompt |
| --- | --- |
| `scratchydisk-skills:anti-ai-tells` | `r1/anti-ai-tells/SKILL.md` |
| `scratchydisk-skills:brainstorming` | `r1/brainstorming/SKILL.md` |
| `scratchydisk-skills:contract-audit` | `r1/contract-audit/SKILL.md` |
| `scratchydisk-skills:devils-advocate-loop` | `r1/devils-advocate-loop/SKILL.md` |
| `scratchydisk-skills:karpathy-guidelines` | `r1/karpathy-guidelines/SKILL.md` |
| `scratchydisk-skills:plantuml-diagrams` | `r1/plantuml-diagrams/SKILL.md` |
| `scratchydisk-skills:spec-to-ship` | `r1/spec-to-ship/SKILL.md` |

The `scratchydisk-skills:` prefix is the documented, expected behaviour recorded
above and under "Skill names under Codex" in `docs/codex.md`: Codex resolves a
symlinked skill directory and prefixes the advertised name with the owning
plugin's name, which `.claude-plugin/plugin.json` sets to `scratchydisk-skills`.
It is not a failure, and `skills/spec-to-ship/SKILL.md` already instructs its
dependency preflight to treat any `<anything>:<id>` as satisfying bare `<id>`,
so a present skill is not misreported as the hard unavailable stop.

Each advertised description is the committed `description` frontmatter for that
skill. Every `r1/<id>/SKILL.md` resolves through the symlink to this checkout's
`skills/<id>/SKILL.md` and compares byte-identical under `cmp`, so the file
Codex hands its model is the same text every S1–S15 assertion reads.

Scope of this row, stated precisely: `codex-cli 0.151.0` has no subcommand that
expands a skill body — Codex uses progressive disclosure, and the model reads
`SKILL.md` on demand at run time. So the Codex evidence is discovery,
advertisement with the correct description, and byte-identical path resolution;
the body-content half is a filesystem fact about the file Codex named, not a
Codex-rendered body. This is the same class of evidence S16 accepted for
`brainstorming`, applied to all seven.

**Codex: PASS.**

### S17 outcome

| Host | S1–S15 coverage | Result |
| --- | --- | --- |
| Claude Code | all assertions run in this session's shell | PASS |
| OpenCode | all assertions re-run against host-loaded bodies | PASS |
| Codex | all seven advertised, descriptions and paths verified byte-identical | PASS |

No required column remains `NOT RUN`. No host revealed a semantic
incompatibility, and no skill body was edited for this scenario.
