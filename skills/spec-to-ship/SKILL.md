---
name: spec-to-ship
description: "Use when you'd otherwise hand-orchestrate the chain from idea to implementation — brainstorm → spec → review → plan → review → implement — and want devil's-advocate review gates between stages to run automatically. Auto-detects whether to start from an idea, an existing spec, or an existing plan. Pauses only for decisions that need your judgement. Not for one-shot review (use /devils-advocate) or a single DA pass on one artifact (use /devils-advocate-loop)."
---

# Spec to Ship

You are orchestrating a written idea, spec, or plan all the way to implementation, hardening each artifact with a devil's-advocate loop between stages. You don't reimplement any stage — you invoke the existing skills in sequence and own the **gates between them**: deciding when to proceed autonomously and when to stop and ask the user.

**Announce at start:** "I'm using the spec-to-ship skill — I'll detect where to start, harden each artifact with a DA loop, and pause only for decisions that need you."

## When to use this skill

- You have an idea, spec, or plan and want it driven through to implementation with review gates, without hand-orchestrating each step.
- You frequently type some variant of "DA-loop the spec, then if nothing critical needs me, write the plan, DA-loop that too, then implement."
- Cross-phase rollouts where each artifact should be hardened before the next stage consumes it.

## When NOT to use this skill

- One-shot review of an already-implemented PR → use `/devils-advocate` and stop after one report.
- A single iterative DA pass on one artifact with no downstream stages → use `/devils-advocate-loop` directly.
- The work is already merged / shipped → that's debugging or a follow-up PR, not this pipeline.

## The pipeline

```
idea ──▶ brainstorm ─┐
                     ├──▶ spec ──▶ contract-audit ──▶ DA-loop ─┐
spec ────────────────┘                                         │
                                                               ├──▶ plan ──▶ contract-audit (C9+C10+C11) ──▶ DA-loop ──▶ [gate] ──▶ implement ──▶ contract-audit: VERIFY ──▶ run it for real
plan ──────────────────────────────────────────────────────────┘
```

You join the pipeline at the detected entry point and run forward. Each `DA-loop` is the `devils-advocate-loop` skill, each `contract-audit` is the `contract-audit` skill. Each arrow between stages is a **gate** you own.

**The spec `contract-audit` runs before the spec DA-loop, not after.** It asks whether the spec is *implementable* — are the data-structure fields, enum casings, cross-module signatures and observable acceptance criteria actually written down. The DA-loop then asks whether it is *right*. That order matters: there is no value in hardening a tick order while the core data structure has no defined fields, and the DA-loop cannot find that gap itself — it is generative, and an omission gives it nothing to argue against.

Treat a FAIL in C1, C2, C3, C7, C9, C10 or C11 as blocking: fix the spec and re-audit before looping. Those seven produce silent defects — code that runs, looks finished, and is wrong at the seams.

**The plan gets its own C9+C10+C11 audit before the plan DA-loop.** The spec audit checks *implementable*; the plan audit checks *transcribable* and *closed*. The plan is what implementers actually read, and it carries far more literals than the spec — per-task code snippets, test bodies, interface blocks. A plan whose test code contradicts its own interfaces block wastes a fix round at best and ships a wrong name at worst. The DA-loop won't catch it: it reads embedded code as illustration of prose it already agrees with. C10 is here because the plan is where provenance is finally checkable — the tasks are ordered, so a symbol consumed by task 9 and produced by nothing is a set difference, and `writing-plans` already emits the `Consumes:` / `Produces:` blocks it needs. C11 is here because the plan is where a change's *sites* are finally enumerated: the spec can say "the heading", but a task has to list the files it edits, and that list is checkable against a grep in a way prose never is.

**The VERIFY pass after implementation** is the cross-cutting check that per-task review cannot do. Each task's review only sees its own side of a seam, so two tasks can disagree about a field name and both reviews pass.

**Every gate up to here reads. None of them run the thing.** That is the pipeline's real ceiling: contract-audit greps, the DA loops argue, per-task review inspects a diff. A feature can pass all of them, hold a full green suite, and not work at all — because the test substrate is not the production substrate and the harness's fakes are more permissive than what they replace. The final stage exists to close that gap, and it is not optional.

## Step 0 — Detect entry point and confirm run mode

Before anything else, do two things and state both to the user:

1. **Detect where to start:**
   - **Only an idea, no written artifact** → start at `brainstorming` (interactive — it produces the spec, then you continue).
   - **A spec exists** (the user points at one, or there's a recent file under `docs/superpowers/specs/` or wherever the project keeps specs) → start at the **spec contract-audit**.
   - **A plan exists** (an implementation plan with tasks) → start at the **plan DA-loop**.

   If it's ambiguous which artifact the user means, ask which one — don't guess.

2. **Ask the run-mode question (once):**

   > "Final go/no-go before I launch implementation, or fully autonomous through to implementation? (Both DA loops still pause if a concern needs your judgement.)"

   Record the answer — it only governs the **pre-implementation gate** in the final step.

State the detected entry point and the chosen run mode, then proceed.

## The two DA gates — the core of this skill

At each DA stage you invoke `devils-advocate-loop` **with escalation mode enabled** (see that skill's "Escalation mode" section). In that mode the loop fixes every routine issue inline — auth, validation, error contracts, audit fields, batch limits, internal contradictions with an obvious resolution — and **escalates only the rare finding that genuinely needs a human decision**, judged by the loop's triple-AND gate: materially different reasonable implementations, *and* hard to reverse or user-/business-/legally-visible, *and* not pickable from the artifact or codebase.

Do **not** restate or loosen those criteria here. Defer to the skill — its wording is deliberately tuned to avoid over-escalating, and broadening it makes the loop escalate routine gaps it should just fix.

**After each DA loop completes:**

- **It escalated one or more decisions** → **PAUSE.** Present each as a question with concrete options and your recommendation, and wait for the user. Apply their answers, then continue.
- **It escalated nothing** → proceed to the next stage automatically. The inline fixes are already committed; say so in one line and move on.

A round that finds only Low / cosmetic / nit issues is not an escalation — note it and proceed.

## Stage flow

1. **(If entering from an idea) Brainstorm.** Invoke `brainstorming`. It's interactive by nature — the user answers its questions and approves the spec. This stage is never "autonomous"; the run mode only affects the pre-implementation gate. Output: a committed spec.
2. **Spec contract-audit.** Invoke `contract-audit` in AUDIT mode on the spec. Fix every FAIL in C1, C2, C3, C7, C9, C10 or C11 in the spec, commit, and re-audit until those seven pass — they are blocking. Remaining FAILs are yours to fix or accept; say which. This runs *before* the DA-loop.
   - You own no contract store, so pass no external contracts unless the user names a document to treat as one.
3. **Spec DA-loop.** Invoke `devils-advocate-loop` on the spec with the two-bucket instruction above. Apply the gate.
4. **Write the plan.** Invoke `writing-plans` to turn the hardened spec into an implementation plan. Output: a committed plan.
5. **Plan contract-audit (C9 + C10 + C11).** Invoke `contract-audit` on the plan, scoped to **C9 — example conformance**, **C10 — producer/consumer closure** and **C11 — site completeness**. For C9: every literal in the plan — URL, query string, JSON key, header, env var, CLI flag, identifier in a code snippet or test body — gets diffed against the definition it exercises, including definitions in the spec and in the code the plan targets. For C10: every symbol in a task's `Consumes:` block must appear in some earlier task's `Produces:` block, and every new persisted field the plan reads must have a task that writes it by a named route. That check is a set difference over metadata the plan already carries — do it mechanically, not by reading. For C11: every string or symbol the plan says it will change gets grepped, and the number of hits gets compared against the number of files the task lists — a task that edits "the label" in one file while three carry it ships a half-applied rename that no reading catches. Fix every mismatch in the plan, commit, then loop. Scoping to three rows is not a licence to sample: within them every literal gets compared, every consumed symbol gets traced, and every changed string gets counted.
6. **Plan DA-loop.** Invoke `devils-advocate-loop` on the plan with the two-bucket instruction. Apply the gate.
7. **Pre-implementation gate.** This is the least-reversible step, so honour the run mode:
   - **Go/no-go mode** → present a tight summary (entry point, contract-audit result, rounds per loop, decisions you escalated, what implementation will do) and wait for explicit "go".
   - **Fully autonomous mode** → proceed without stopping.
8. **Implement.** Invoke `subagent-driven-development` (or `executing-plans` if the user prefers checkpointed execution) to implement the plan. **Put `karpathy-guidelines` in each implementing subagent's instructions** — simplicity over speculation, surgical changes, verify each step. Name it explicitly in the dispatch prompt; a subagent starts with a fresh context, so your knowing about the skill does nothing for the code it writes. Scope one rule: its "stop and ask when unclear" routes to *your* escalation gate, not to the user — a hardened spec and plan should already have answered most of it. **Scoping the destination is not weakening the instruction.** "If the brief conflicts with the code you find, stop and ask" must survive verbatim in the dispatch prompt: a fresh implementer reading the plan literally, with explicit authority to challenge it, is the last gate that catches a wrong literal — and an implementer who assumes the plan is right implements the plan's bug faithfully. A plan-vs-code conflict comes back to you; it is never silently reconciled in either direction. Where it conflicts with the implementer template's "improve code you're touching", karpathy §3 wins: adjacent code stays untouched, unrelated dead code gets mentioned rather than deleted.
9. **Contract-audit: VERIFY.** Invoke `contract-audit` in VERIFY mode against the finished code. Fix violations, or report them if a fix needs a decision. Don't skip this because every task's own review passed — that's exactly the blind spot it covers. If a contract has now failed VERIFY twice in this repo, leave a mechanical checker behind per that skill's instruction, name it in the project's instructions, and run it at each full-suite gate from then on.
10. **Run it for real, once.** Exercise one end-to-end path of what was built against the **real** dependencies the feature needs — the real database engine, the real service registrations, the real wiring — not the test harness's substitutes. One happy path is enough; you are not writing a test suite, you are refuting "it works" with evidence. Use the project's own run/verify skill if it has one.
    - **Name the substitutions the suite makes, then bypass them.** In-memory databases enforce no constraint, key, transaction or concurrency token that the real one does; fakes injected for services are routinely *more permissive* than what they replace. Every assertion downstream of a permissive fake is unfalsifiable, so the green suite is not evidence about production and must not be reported as if it were.
    - **A green suite is not a substitute for this step, and neither is a passing VERIFY.** Both read; this runs. If you cannot run it — no environment, no credentials — say exactly that in the final report, in place of a claim that it works. "N tests passing" alongside "never executed against a real database" is the honest pair, and stating only the first is the failure this stage exists to prevent.

If a stage's artifact doesn't exist yet because you entered later in the pipeline, skip the stages before your entry point — don't fabricate a spec to "complete the set."

## Final report

After implementation (or after the pre-implementation gate if the user stops there), output a concise summary:

- **Entry point:** idea / spec / plan
- **Run mode:** go/no-go / autonomous
- **Spec contract-audit:** N of 11 defined, which FAILs were fixed, which were accepted
- **Spec DA-loop:** N rounds, M decisions escalated
- **Plan contract-audit (C9+C10+C11):** literal mismatches, unproduced symbols and uncounted sites found and fixed, or clean
- **Plan DA-loop:** N rounds, M decisions escalated
- **Implementation:** outcome (tasks completed, tests passing, or where it stopped)
- **Contract VERIFY:** contracts violated / fixed
- **Ran for real:** what was exercised against which real dependencies, and what the run showed — or, if it could not be run, that plainly, with what remains unproven
- **Outstanding:** any Low / deferred items, or decisions still open

## Honest pitfalls to avoid

- **Auto-proceeding past a real decision.** If a DA loop surfaces an ambiguous requirement or a tradeoff, that's a PAUSE — even in "autonomous" mode. Autonomous governs the pre-implementation gate, not the judgement gates.
- **Pausing on everything.** A fix you can make from the artifact and codebase is *not* a blocking decision. Don't kick routine fixes back to the user — that defeats the point.
- **Guessing on a blocking item to keep the pipeline moving.** Inventing an answer to avoid an interruption is worse than the interruption. Surface it.
- **Skipping the run-mode question.** Always ask it once up front; don't assume autonomous.
- **Fabricating earlier artifacts.** Entered at the plan? Don't reverse-engineer a spec to look complete. Start where the artifact actually is.
- **Re-running the brainstorm autonomously.** Brainstorming needs the user. Never try to answer its questions yourself to stay hands-off.
- **Running the contract-audit after the DA-loop, or treating its FAILs as DA concerns to rank.** It's a completeness gate, not a review: it runs first, every row gets answered, and C1/C2/C3/C7/C9/C10 FAILs block regardless of how minor they look.
- **Skipping the plan's C9+C10+C11 pass because the spec already audited clean.** The plan is a fresh transcription of the spec's vocabulary into far more literals. A clean spec is exactly the condition under which a wrong literal in the plan looks authoritative.
- **Skipping the VERIFY pass because implementation went smoothly.** Smooth is what seam drift looks like from inside each task.
- **Declaring done on a green suite.** The suite runs against the harness, and the harness is more permissive than production. Stage 10 is the only stage that produces evidence about the thing you are shipping; every stage before it produces evidence about the documents.
- **Reporting the test count without the substrate.** "1,163 tests, 0 failures" is a true statement that misleads if the feature has never touched a real database. Report both halves or neither.
