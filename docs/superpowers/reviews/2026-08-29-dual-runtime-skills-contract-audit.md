| # | Contract | Status | Where defined / what is missing |
|---|----------|--------|----------------------------------|
| C1 | Data-structure fields | N/A | The specification does not introduce an application data structure. The repository tree and dependency map are inventories, not runtime records. |
| C2 | Vocabularies and casing | PASS | Portability rules are normatively named `P1`–`P7`; skill IDs and OpenCode paths are written with exact casing. OpenCode's current name rule is also stated as lowercase-safe, although the checker should encode the exact regex. |
| C3 | Cross-module signatures | FAIL | `install-opencode.sh` and `check-portability.sh` have responsibilities but no complete CLI contract: supported arguments, stdout/stderr rules, exit codes, and collision/error outcomes are not fully specified. |
| C4 | Shared constants and units | N/A | No shared numeric constants or units are introduced. |
| C5 | Ambiguous field meanings | FAIL | “Existing symlink managed by this repository” is not defined. The implementation would have to guess whether ownership means an exact target, any target below the checkout, or a previously recorded link. |
| C6 | Observable acceptance criteria | FAIL | Several criteria say a skill “loads”, “works unchanged”, or follows a “happy path” without defining a command, observable output, or failure oracle. The cross-runtime testing matrix names scenarios but not the executable harness. |
| C7 | Ownership and invocation | PASS | Repository changes name their owners (`install-opencode.sh`, `check-portability.sh`, each `SKILL.md`, README/docs), and the checker is invoked manually from README or from existing CI. Stage-dependent skills are invoked by `spec-to-ship`. |
| C8 | Toolchain coherence | FAIL | The repository has no current test harness or CI, while the specification requires behavioural execution in Claude Code and OpenCode. It does not define how results are captured or how unavailable runtimes are reported without being mistaken for a pass. |
| C9 | Example conformance | PASS | The proposed OpenCode global path, `SKILL.md` shape, native skill loading, lowercase hyphenated name rule, and `permission.skill` model agree with the current official OpenCode documentation. The symlink examples also point to the canonical `skills/` tree as required. |
| C10 | Producer/consumer closure | FAIL | `brainstorming`, `writing-plans`, and implementation skills are consumed by `spec-to-ship` but are not produced by this repository. The spec requires source discovery and an explicit stop, but does not bind the work to exact upstream revisions or an installation route. Downstream MaximKeep commands are also named without their source repository being in scope. |
| C11 | Site completeness | FAIL | The six current skill directories are countable, but the wording changes are not enumerated by file/site. The downstream `/pm`, `/sa`, `/dev`, `/validate-epic`, and `/maxim-doctor` sites are not present in this checkout, so their counts cannot be verified here. |

C3: Define both scripts' accepted arguments, output channels, and exit-code table before implementation.

C5: Define a managed link as a symlink whose resolved target is the corresponding direct child of this checkout's canonical `skills/` directory; treat every other existing path as a collision.

C6: Give every runtime scenario a command, fixture, expected evidence, and explicit PASS/FAIL/SKIP rule; SKIP must never satisfy dual-runtime acceptance.

C8: Add a repository-local shell test harness for deterministic checks and a recorded manual/CLI smoke protocol for host behaviour, with runtime availability reported separately.

C10: Record each external skill's canonical source URL/revision and installation/discovery route before importing or testing it; move MaximKeep work to a plan in its owning repository.

C11: Generate a checked inventory of runtime-specific references before edits and require the post-change inventory to account for every site.

**5 of 11 contracts defined. This spec is not ready to implement without the six additions above.**
