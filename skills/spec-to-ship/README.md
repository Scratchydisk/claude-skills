# spec-to-ship

A meta-orchestrator that chains the existing brainstorm → spec → audit → review → plan → review → implement → verify skills into one gated pipeline. Built after observing the same hand-orchestrated pattern recur: "DA-loop the spec; if nothing critical needs me, write the plan; DA-loop that too; if still clean, implement." This skill collapses that into one invocation while keeping the human in the loop exactly where judgement is required.

It doesn't reimplement any stage. It invokes `brainstorming`, `contract-audit`, `devils-advocate-loop`, `writing-plans`, and `subagent-driven-development`, and owns the **gates between them**. It also names `karpathy-guidelines` in each implementing subagent's dispatch prompt — that's an instruction to the subagent, not a stage, because a subagent starts with a fresh context and won't reliably reach for the skill on its own.

## When this beats running the skills by hand

| Situation | Use |
|---|---|
| One-shot review of a finished PR | `/devils-advocate` |
| A single iterative DA pass on one artifact | `/devils-advocate-loop` |
| Idea/spec/plan → implementation with review gates | `/spec-to-ship` |
| Recurring "harden the spec, then the plan, then build it" workflow | `/spec-to-ship` |

## How it decides

- **Entry auto-detection.** Idea only → start at brainstorming. Spec exists → start at the spec contract-audit. Plan exists → start at the plan C9+C10+C11 audit. It states the detected entry point before proceeding.
- **Run mode, asked once.** Final go/no-go before implementation, or fully autonomous through to it. This governs only the pre-implementation gate.
- **A completeness gate before the first review.** `contract-audit` runs on the spec *before* the DA-loop: implementable first, then right. A FAIL in C1, C2, C3, C7, C9, C10 or C11 (data-structure fields, vocabularies and casing, cross-module signatures, ownership and invocation, example conformance, producer/consumer closure, site completeness) blocks — those are the seven that produce silent defects. A second `contract-audit` runs in VERIFY mode against the finished code, because per-task review only ever sees one side of a seam.
- **A C9+C10+C11 audit on the plan too.** The spec audit checks *implementable*; the plan audit checks *transcribable* and *closed*. The plan is what implementers actually read and carries far more literals — task code snippets, test bodies, interface blocks — and a DA-loop reads embedded code as illustration of prose it already agrees with. C10 lands here because the tasks are ordered: a symbol some task consumes and no earlier task produces is a set difference over metadata `writing-plans` already emits. C11 lands here because a task must list the files it edits, and that list is checkable against a grep in a way "rename the heading" never is.
- **One stage that actually runs the thing.** Every other gate reads — the audits grep, the loops argue, per-task review inspects a diff. The last stage exercises one end-to-end path against the real database engine and the real service wiring, because a harness's in-memory substitutes and permissive fakes make a green suite evidence about the harness. If it cannot be run, the report says so instead of claiming it works.
- **Two judgement gates.** Each DA loop runs with `devils-advocate-loop`'s escalation mode enabled: it fixes routine issues inline (auth, validation, error contracts, audit fields, batch limits) and escalates only findings that pass a strict triple-AND gate — materially different reasonable implementations, *and* hard to reverse or user-/business-/legally-visible, *and* not pickable from the artifact. Anything escalated → pause and ask. Nothing escalated → proceed. This pause happens even in fully-autonomous mode.

## Honest pitfalls

- Auto-proceeding past a real decision — autonomous mode governs the pre-implementation gate, not the judgement gates.
- Pausing on routine fixes it could make from the artifact and codebase — that defeats the point.
- Guessing on a blocking item to avoid an interruption — worse than the interruption.
- Fabricating earlier artifacts when entering mid-pipeline.

See `SKILL.md` for the full stage flow and gate semantics.
