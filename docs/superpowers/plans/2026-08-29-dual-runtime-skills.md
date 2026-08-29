# Dual-Runtime Skills Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make this repository's canonical skill implementations discoverable and behaviourally usable in Claude Code and OpenCode, while preserving compatibility with Codex, without runtime-specific copies or weakened workflow gates.

**Architecture:** Keep `skills/` as the only implementation tree. Add a deterministic portability checker and a collision-safe symlink installer around it, then make only evidence-backed wording changes to existing skills. Treat upstream Superpowers imports and downstream MaximKeep changes as separate, source-bound workstreams so this repository never fabricates or silently vendors external behaviour.

**Tech Stack:** POSIX shell/Bash, Markdown `SKILL.md` files, Claude Code plugin manifests, OpenCode native Agent Skills, `rg`, `readlink`/`realpath`, Git.

**Spec:** `tmp/dual-runtime-skills-spec.md`

## Global Constraints

- `skills/` remains the single canonical implementation tree; do not create runtime-specific skill copies.
- Cross-skill calls use exact skill IDs, never runtime call syntax or runtime-specific installation paths.
- Preserve all eleven `contract-audit` contracts and its blocking semantics.
- Preserve `devils-advocate-loop` round, escalation, inline-fix, and commit semantics.
- Preserve the full `spec-to-ship` gate order and final run against real dependencies.
- Missing external skills stop explicitly at the relevant stage boundary; no behaviour may be reconstructed from memory.
- OpenCode skill names must match `^[a-z0-9]+(-[a-z0-9]+)*$`, be 1–64 characters, and equal their directory name.
- OpenCode installation targets `${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills` and must only create symlinks.
- A managed link is a symlink whose resolved target exactly equals the corresponding direct child of this checkout's canonical `skills/` directory. Any other existing path is a collision.
- Codex repository-scoped skills use `.agents/skills`; user-scoped skills use `$HOME/.agents/skills`. Prefer `$skill-installer` for installing a skill from an external repository and a Codex plugin for reusable distribution.
- This plan changes only this repository. MaximKeep command changes belong in its owning repository and require a separate plan.

## Baseline inputs

These inputs exist before Task 1 and may appear in `Consumes:` blocks without an earlier task producer:

- `repo.skills`: the six canonical directories currently under `skills/`.
- `repo.manifests`: `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`, both currently version `0.7.0`.
- `spec.dual_runtime`: `tmp/dual-runtime-skills-spec.md`.
- `review.codex_addendum`: `docs/superpowers/reviews/2026-08-29-codex-compatibility-addendum.md`.
- `official.opencode_contracts`: OpenCode Agent Skills, permissions, agents, and CLI documentation cited by the spec.
- `official.codex_contracts`: OpenAI Codex skills documentation cited by the Codex addendum.
- `skill.contract_audit`, `skill.devils_advocate_loop`, `skill.karpathy_guidelines`, and `skill.spec_to_ship`: the existing repository-local skill implementations.

## Counted pre-change sites

The plan review counted the current `README.md` plus every `skills/**/{SKILL.md,README.md}`:

- Host-tool phrases (`Claude Code tool`, `Read tool`, `Edit tool`, `Glob`, `Task tool`): **0 sites**.
- Runtime skill paths (`.claude/skills`, `.codex/skills`, `.opencode/skills`, `.config/opencode/skills`): **0 sites**.
- Cross-skill IDs (`contract-audit`, `devils-advocate-loop`, `karpathy-guidelines`, `brainstorming`, `writing-plans`, `subagent-driven-development`, `executing-plans`): **94 sites across nine files**: root `README.md` (18), `karpathy-guidelines` SKILL/README (1/1), `devils-advocate-loop` SKILL/README (5/5), `contract-audit` SKILL/README (8/11), and `spec-to-ship` SKILL/README (32/13).

Task 4 must re-run the same inventory after adding `docs/` and `scripts/`. Task 6 may alter only sites the inventory classifies as host-bound; the other cross-skill ID sites are expected and must remain accounted for.

---

## File map

- `scripts/check-portability.sh`: deterministic validation of canonical skill metadata, names, forbidden runtime paths, and bundled relative references.
- `scripts/install-opencode.sh`: idempotent global OpenCode symlink installer with collision protection and dry-run support.
- `tests/test-check-portability.sh`: black-box checker tests using temporary fixture repositories.
- `tests/test-install-opencode.sh`: black-box installer tests using temporary config roots and copied fixture checkouts.
- `tests/fixtures/incomplete-spec.md`: behavioural fixture for C1/C2/C7/C10/C11 failures.
- `tests/fixtures/flawed-plan.md`: plan fixture with literal, producer/consumer, and site-count defects.
- `tests/runtime-smoke.md`: exact Claude Code/OpenCode smoke scenarios and evidence-recording rules.
- `docs/opencode.md`: discovery, installation, update, permissions, dependencies, and troubleshooting.
- `docs/codex.md`: Codex discovery, installation, update, enable/disable, external Superpowers dependencies, and troubleshooting.
- `docs/runtime-portability.md`: contributor rules, site inventory, dependency provenance, and test matrix.
- `README.md`: dual-runtime positioning and entry points.
- `skills/*/SKILL.md`: surgical host-neutral edits only where the inventory or smoke tests prove a need.
- `skills/spec-to-ship/SKILL.md`: explicit dependency model and stage-boundary failure semantics.
- `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`: consistent release metadata after behaviour is verified.

### Task 1: Lock the portability contracts with executable fixture tests

**Files:**
- Create: `tests/test-check-portability.sh`
- Create: `tests/fixtures/incomplete-spec.md`
- Create: `tests/fixtures/flawed-plan.md`

**Interfaces:**
- Consumes: `repo.skills`, `spec.dual_runtime`
- Produces: `tests.portability_contracts` (`bash tests/test-check-portability.sh`), `fixtures.audit` (`incomplete-spec.md`, `flawed-plan.md`)

- [ ] **Step 1: Write failing checker tests** covering missing `SKILL.md`, missing `name`, missing `description`, name/directory mismatch, invalid OpenCode names (uppercase, underscore, consecutive/trailing hyphen, 65 characters), every forbidden runtime path, missing relative `references/` target, and a valid skill.
- [ ] **Step 2: Make each case assert both status and diagnostic**: invalid fixtures require non-zero plus `ERROR: <skill-id>: <reason>`; valid fixtures require zero plus `PASS: <count> skills checked`; warning-only host tool phrases require zero plus `WARN:`.
- [ ] **Step 3: Run `bash tests/test-check-portability.sh`** and verify it fails because `scripts/check-portability.sh` does not exist.
- [ ] **Step 4: Add the two behavioural Markdown fixtures** with exact defects named by the spec; keep them independent of any particular host syntax.
- [ ] **Step 5: Commit** with `test: define dual-runtime portability contracts`.

### Task 2: Implement the deterministic portability checker

**Files:**
- Create: `scripts/check-portability.sh`
- Modify: `tests/test-check-portability.sh`

**Interfaces:**
- Consumes: `repo.skills`, `tests.portability_contracts`
- Produces: `script.portability_checker`: `check_portability([--root PATH|--help]) -> exit 0|1|2`; diagnostics use `PASS:`, `WARN:`, and `ERROR:` prefixes

- [ ] **Step 1: Add argument tests** for no arguments, `--root PATH`, `--help`, and unknown arguments; `--help` exits `0`, unknown/missing values exit `2`.
- [ ] **Step 2: Implement root resolution and direct-child enumeration** without following arbitrary nested skill trees.
- [ ] **Step 3: Implement conservative frontmatter extraction** for the first YAML block and exact validation of required `name`/`description`, length, regex, and directory equality.
- [ ] **Step 4: Implement forbidden-path checks** for the six paths listed in the spec, reporting file and line.
- [ ] **Step 5: Implement conservative bundled-reference checks** only for literal `references/...` and `scripts/...` tokens; strip trailing Markdown punctuation and resolve relative to the owning skill directory.
- [ ] **Step 6: Implement warning-only host wording checks** for `Claude Code tool`, `Read tool`, `Edit tool`, `Glob`, and `Task tool`.
- [ ] **Step 7: Run `bash tests/test-check-portability.sh` and `./scripts/check-portability.sh`**; both must exit `0` on the repository.
- [ ] **Step 8: Commit** with `chore: add cross-runtime portability checker`.

### Task 3: Lock and implement collision-safe OpenCode installation

**Files:**
- Create: `tests/test-install-opencode.sh`
- Create: `scripts/install-opencode.sh`

**Interfaces:**
- Consumes: `repo.skills`
- Produces: `script.opencode_installer`: `install_opencode([--dry-run|--help]) -> exit 0|1|2`, and `tests.opencode_installer`; destination `${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills`

- [ ] **Step 1: Write failing black-box tests** using `mktemp -d` and a fixture checkout containing two skills.
- [ ] **Step 2: Cover fresh install, second-run idempotency, stale managed-link refresh, relative and absolute managed links, unrelated symlink collision, real-file collision, real-directory collision, `XDG_CONFIG_HOME`, fallback `HOME/.config`, paths containing spaces, and `--dry-run` with no filesystem mutation.
- [ ] **Step 3: Define output assertions**: `LINK`, `KEEP`, `REFRESH`, `WOULD_LINK`, and `COLLISION` each include skill ID and destination; collisions go to stderr.
- [ ] **Step 4: Implement canonical root/target resolution and exact managed-link ownership** using Bash plus portable `readlink`, `cd -P`, and `pwd -P` operations; do not require GNU-only `realpath`. Never delete or replace a non-managed destination.
- [ ] **Step 5: Run `bash tests/test-install-opencode.sh`** twice and verify both runs pass.
- [ ] **Step 6: Commit** with `chore: add OpenCode skill symlink installer`.

### Task 4: Document Claude Code, Codex, and OpenCode installation and establish a counted change inventory

**Files:**
- Create: `docs/opencode.md`
- Create: `docs/codex.md`
- Create: `docs/runtime-portability.md`
- Modify: `README.md`

**Interfaces:**
- Consumes: `official.opencode_contracts`, `official.codex_contracts`, `script.portability_checker`, `script.opencode_installer`, `review.codex_addendum`
- Produces: `docs.runtime_installation`, `inventory.runtime_sites`, `upstream.provenance`, and `docs.dependency_map`

- [ ] **Step 1: Resolve and record upstream provenance before writing install commands**: canonical repository URL, immutable revision, licence, exact skill subdirectory, and host-specific discovery route for `brainstorming`, `writing-plans`, `subagent-driven-development`, and `executing-plans`. If any source cannot be verified, record it as unavailable and omit its install command.
- [ ] **Step 2: Record the pre-edit inventory** from `rg -n -i 'Claude Code tool|Read tool|Edit tool|Glob|Task tool|\.claude/skills|\.codex/skills|\.opencode/skills|\.config/opencode/skills' skills README.md docs scripts` in `docs/runtime-portability.md`, grouped by intentional documentation, warning candidate, and hard violation.
- [ ] **Step 3: Document OpenCode discovery** including project/global native paths, Claude-compatible discovery, the exact skill-name regex, and native on-demand `skill` loading.
- [ ] **Step 4: Document install/update/uninstall behaviour** using `./scripts/install-opencode.sh`, `git pull`, re-running the installer, and unlinking only destinations that resolve to this checkout.
- [ ] **Step 5: Document `permission.skill`** conceptually with `allow`/`ask`/`deny`; do not prescribe personal provider/model choices or edit `opencode.json` automatically.
- [ ] **Step 6: Add `docs/codex.md`** with the official discovery locations (`.agents/skills`, `$HOME/.agents/skills`, `/etc/codex/skills`), manual `SKILL.md` installation, `$skill-installer` installation from a repository, automatic change detection/restart fallback, `[[skills.config]]` enable/disable configuration, and the preference for plugins when distributing reusable skill collections.
- [ ] **Step 7: Document the Superpowers `brainstorming` dependency from the verified provenance.** For Codex, show `$skill-installer` with the canonical upstream repository and exact `brainstorming` subdirectory. For OpenCode, show how to expose that same canonical directory under `~/.config/opencode/skills/brainstorming`, either through this repository's installer after an authorised import or through a direct symlink to the verified upstream checkout. State that users must not recreate the skill from this plan.
- [ ] **Step 8: Document the dependency map** separating repository-local dependencies from `brainstorming`, `writing-plans`, and implementation skills, including the verified provenance or explicit unavailable status for every external skill.
- [ ] **Step 9: Update README** to describe Claude Code, Codex, and OpenCode as consumers of canonical skill sources and link the host-specific documentation.
- [ ] **Step 10: Run `./scripts/check-portability.sh`** and verify the documented baseline count equals a fresh `rg` count.
- [ ] **Step 11: Commit** with `docs: define cross-runtime skill consumption`.

### Task 5: Make `spec-to-ship` dependency handling runtime-neutral

**Files:**
- Modify: `skills/spec-to-ship/SKILL.md`
- Modify: `skills/spec-to-ship/README.md`
- Create: `tests/runtime-smoke.md`

**Interfaces:**
- Consumes: `skill.contract_audit`, `skill.devils_advocate_loop`, `skill.karpathy_guidelines`, `skill.spec_to_ship`, `fixtures.audit`, `docs.dependency_map`
- Produces: `skill.spec_to_ship.runtime_neutral` and `tests.runtime_smoke`; missing dependency output is `The next pipeline stage requires <skill-id>, which is unavailable.`

- [ ] **Step 1: Add smoke scenarios** for idea/spec/plan entry points, a missing `brainstorming` dependency, a missing implementation dependency, and the full pipeline order.
- [ ] **Step 2: Run the scenarios against the current skill** and record the expected failures before editing.
- [ ] **Step 3: Add the explicit dependency section** and require native skill loading by ID, without encoding `Skill(...)`, `skill({...})`, slash-command, or installation-path syntax.
- [ ] **Step 4: Add stage-boundary preflight** so only dependencies required by the detected path are checked and missing dependencies stop without imitation.
- [ ] **Step 5: Preserve and mechanically compare the ordered gate list**: brainstorm → spec → contract audit → DA loop → plan → C9/C10/C11 plan audit → DA loop → implementation → VERIFY → real-dependency run.
- [ ] **Step 6: Run `./scripts/check-portability.sh`** and execute the smoke scenarios in every locally available host; unavailable hosts are recorded as `NOT RUN`, never PASS.
- [ ] **Step 7: Commit** with `refactor(spec-to-ship): make skill dependencies runtime-neutral`.

### Task 6: Verify the remaining canonical skills unchanged

**Files:**
- Modify: `tests/runtime-smoke.md`

**Interfaces:**
- Consumes: `inventory.runtime_sites`, `skill.spec_to_ship.runtime_neutral`, `tests.runtime_smoke`, `repo.skills`
- Produces: `skills.runtime_neutral` (evidence that unchanged skills need no adaptation) and `inventory.runtime_sites.closed`

- [ ] **Step 1: Add runtime smoke cases** for `contract-audit` C1/C10 failures, `devils-advocate-loop` minimum two rounds plus explicit escalation, and PlantUML render plus visual-inspection requirement.
- [ ] **Step 2: Test `karpathy-guidelines` and `anti-ai-tells` unchanged** in each available host; do not edit them merely for symmetry.
- [ ] **Step 3: If a smoke case proves a semantic incompatibility, stop this task and amend the plan with the exact affected `SKILL.md` and failing primitive before editing it.** Do not turn a conditional finding into an unplanned skill rewrite.
- [ ] **Step 4: Re-run all smoke cases** and compare the current `rg` inventory with Task 4's baseline, accounting for every retained or newly introduced site.
- [ ] **Step 5: Run `./scripts/check-portability.sh`** and verify all eleven `contract-audit` headings and blocking set `C1,C2,C3,C7,C9,C10,C11` remain present.
- [ ] **Step 6: Commit** with `test(skills): verify unchanged cross-runtime behaviour`.

### Task 7: Gate upstream Superpowers skills by provenance and unchanged-host tests

**Files:**
- Modify: `docs/runtime-portability.md`
- Create only after provenance is recorded and licensing permits: `skills/brainstorming/SKILL.md`
- Create matching source attribution/licence files required by the upstream licence

**Interfaces:**
- Consumes: `upstream.provenance`, `tests.runtime_smoke`, `script.portability_checker`
- Produces: `skill.brainstorming.shared` or `upstream.brainstorming.blocked`; never a memory-based recreation

- [ ] **Step 1: Verify Task 4's recorded source URL, immutable revision, licence, exact subdirectory, and Claude Code, Codex, and OpenCode installation routes** for `brainstorming`, `writing-plans`, `subagent-driven-development`, and `executing-plans`; stop with `upstream.brainstorming.blocked` if the record is incomplete.
- [ ] **Step 2: Expose the exact upstream `brainstorming` source to Codex and OpenCode without editing it** and run the idea-entry smoke case in each host.
- [ ] **Step 3: If it passes, import the exact source subject to licence; if it fails, record the exact failed semantic primitive before making the smallest shared adaptation.**
- [ ] **Step 4: Do not vendor the other external skills unless the same provenance, licence, and demonstrated need gates pass; documentation of their external installation is sufficient otherwise.**
- [ ] **Step 5: Run `./scripts/check-portability.sh` and all three host smoke cases**; commit separately as `feat(skills): add shared brainstorming workflow` only if an import actually occurs.

### Task 8: Verify release readiness and update distribution metadata

**Files:**
- Modify: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
- Modify: `docs/runtime-portability.md`

**Interfaces:**
- Consumes: `repo.manifests`, `tests.portability_contracts`, `tests.opencode_installer`, `script.portability_checker`, `tests.runtime_smoke`, `inventory.runtime_sites.closed`, and either `skill.brainstorming.shared` or `upstream.brainstorming.blocked`
- Produces: `release.manifests.synced` and `release.evidence` with `PASS`, `FAIL`, or `NOT RUN`

- [ ] **Step 1: Run `bash tests/test-check-portability.sh`, `bash tests/test-install-opencode.sh`, and `./scripts/check-portability.sh`**; all must pass.
- [ ] **Step 2: Test installer idempotency against a temporary `XDG_CONFIG_HOME`** and verify every destination resolves into this checkout's `skills/` tree.
- [ ] **Step 3: Run Claude Code, Codex, and OpenCode smoke protocols** where the runtimes are available; do not claim cross-runtime compatibility while any required column is `NOT RUN`.
- [ ] **Step 4: Re-run the runtime-specific site inventory** and require zero unaccounted differences from Task 4.
- [ ] **Step 5: Bump both manifests from `0.7.0` to `0.8.0`** and verify equality with `jq -r`.
- [ ] **Step 6: Commit** with `chore: release cross-runtime skill support`.

## Deferred workstream: MaximKeep

The spec's `/pm`, `/sa`, `/dev`, `/validate-epic`, and `/maxim-doctor` changes cannot be planned at file/signature level from this checkout. In the owning repository, first count every runtime-specific path/tool reference, then create a separate plan that changes those exact sites, preserves model-selection ownership in the consuming agent, and re-tests the Design → Build → Review handoff. Do not mix that work into this repository's commits.

## Required Codex compatibility reviews

Before implementation, amend the source spec or bind it to a short Codex addendum covering these four checks:

1. **Discovery and packaging:** verify every canonical skill is discoverable from `.agents/skills` or `$HOME/.agents/skills`, and decide whether this collection remains a set of local skills or gains a Codex-compatible plugin distribution path. OpenCode's symlink layout is not evidence for Codex discovery.
2. **Frontmatter and resource conformance:** validate the complete frontmatter and bundled-resource rules against the open agent skills format used by Codex. The existing checker currently encodes OpenCode's name rule only.
3. **Tool and orchestration semantics:** compare each host-neutral instruction with Codex's actual skill invocation, plan/update, subagent, question, file-edit, and approval capabilities. Pay particular attention to `brainstorming` approval gates and `spec-to-ship` dependency preflight.
4. **Behavioural parity:** add Codex as a required column in the testing matrix for loading, negative `contract-audit` fixtures, DA-loop round/escalation behaviour, missing dependencies, full pipeline order, PlantUML rendering, and final real-dependency execution. Syntax review alone cannot satisfy this gate.

These are focused compatibility reviews, not a request for a Codex-specific fork. Any incompatibility must be demonstrated by a failing smoke case before shared skill wording changes or an adapter is introduced.

## Plan self-review

- Spec coverage: repository-local requirements and the Codex addendum are mapped to Tasks 1–8; upstream and downstream ownership boundaries are explicit.
- Literal consistency: paths, skill IDs, name regex, dependency IDs, and pipeline order match the spec and current OpenCode documentation.
- Producer/consumer closure: each task consumes only outputs from earlier tasks, repository state, or explicitly provenance-gated upstream sources.
- Site completeness: Task 4 establishes the baseline count and Tasks 6/8 require exact closure.
- No runtime test may be inferred from syntax or recorded as passing when its host was unavailable.
