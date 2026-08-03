# spec-to-ship

A meta-orchestrator that chains the existing brainstorm → spec → audit → review → plan → review → implement → verify skills into one gated pipeline. Built after observing the same hand-orchestrated pattern recur: "DA-loop the spec; if nothing critical needs me, write the plan; DA-loop that too; if still clean, implement." This skill collapses that into one invocation while keeping the human in the loop exactly where judgement is required.

It doesn't reimplement any stage. It invokes `brainstorming`, `contract-audit`, `devils-advocate-loop`, `writing-plans`, and `subagent-driven-development`, and owns the **gates between them**.

## When this beats running the skills by hand

| Situation | Use |
|---|---|
| One-shot review of a finished PR | `/devils-advocate` |
| A single iterative DA pass on one artifact | `/devils-advocate-loop` |
| Idea/spec/plan → implementation with review gates | `/spec-to-ship` |
| Recurring "harden the spec, then the plan, then build it" workflow | `/spec-to-ship` |

## How it decides

- **Entry auto-detection.** Idea only → start at brainstorming. Spec exists → start at the spec contract-audit. Plan exists → start at the plan DA-loop. It states the detected entry point before proceeding.
- **Run mode, asked once.** Final go/no-go before implementation, or fully autonomous through to it. This governs only the pre-implementation gate.
- **A completeness gate before the first review.** `contract-audit` runs on the spec *before* the DA-loop: implementable first, then right. A FAIL in C1, C2, C3 or C7 (data-structure fields, vocabularies and casing, cross-module signatures, ownership and invocation) blocks — those are the four that produce silent defects. A second `contract-audit` runs in VERIFY mode against the finished code, because per-task review only ever sees one side of a seam.
- **Two judgement gates.** Each DA loop runs with `devils-advocate-loop`'s escalation mode enabled: it fixes routine issues inline (auth, validation, error contracts, audit fields, batch limits) and escalates only findings that pass a strict triple-AND gate — materially different reasonable implementations, *and* hard to reverse or user-/business-/legally-visible, *and* not pickable from the artifact. Anything escalated → pause and ask. Nothing escalated → proceed. This pause happens even in fully-autonomous mode.

## Honest pitfalls

- Auto-proceeding past a real decision — autonomous mode governs the pre-implementation gate, not the judgement gates.
- Pausing on routine fixes it could make from the artifact and codebase — that defeats the point.
- Guessing on a blocking item to avoid an interruption — worse than the interruption.
- Fabricating earlier artifacts when entering mid-pipeline.

See `SKILL.md` for the full stage flow and gate semantics.
