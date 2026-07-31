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
idea ──▶ brainstorm ──▶ spec ─┐
                              │
spec ─────────────────────────┼──▶ contract-audit ──▶ DA-loop ──▶ plan ─┐
                              │                                          │
plan ─────────────────────────────────────────────────────────────────┼──▶ DA-loop ──▶ [gate] ──▶ implement ──▶ contract-audit: VERIFY
```

You join the pipeline at the detected entry point and run forward. Each `DA-loop` is the `devils-advocate-loop` skill. Each arrow between stages is a **gate** you own.

**The spec `contract-audit` runs before the spec DA-loop, not after.** It asks whether the spec is *implementable* — are the data-structure fields, enum casings, cross-module signatures and observable acceptance criteria actually written down. The DA-loop then asks whether it is *right*. That order matters: there is no value in hardening a tick order while the core data structure has no defined fields, and the DA-loop cannot find that gap itself — it is generative, and an omission gives it nothing to argue against.

Treat a FAIL in C1, C2, C3 or C7 as blocking: fix the spec and re-audit before looping. Those four produce silent defects — code that runs, looks finished, and is wrong at the seams.

**The VERIFY pass after implementation** is the cross-cutting check that per-task review cannot do. Each task's review only sees its own side of a seam, so two tasks can disagree about a field name and both reviews pass.

## Step 0 — Detect entry point and confirm run mode

Before anything else, do two things and state both to the user:

1. **Detect where to start:**
   - **Only an idea, no written artifact** → start at `brainstorming` (interactive — it produces the spec, then you continue).
   - **A spec exists** (the user points at one, or there's a recent file under `docs/superpowers/specs/` or wherever the project keeps specs) → start at the **spec DA-loop**.
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
2. **Spec DA-loop.** Invoke `devils-advocate-loop` on the spec with the two-bucket instruction above. Apply the gate.
3. **Write the plan.** Invoke `writing-plans` to turn the hardened spec into an implementation plan. Output: a committed plan.
4. **Plan DA-loop.** Invoke `devils-advocate-loop` on the plan with the two-bucket instruction. Apply the gate.
5. **Pre-implementation gate.** This is the least-reversible step, so honour the run mode:
   - **Go/no-go mode** → present a tight summary (entry point, rounds per loop, decisions you escalated, what implementation will do) and wait for explicit "go".
   - **Fully autonomous mode** → proceed without stopping.
6. **Implement.** Invoke `subagent-driven-development` (or `executing-plans` if the user prefers checkpointed execution) to implement the plan.

If a stage's artifact doesn't exist yet because you entered later in the pipeline, skip the stages before your entry point — don't fabricate a spec to "complete the set."

## Final report

After implementation (or after the pre-implementation gate if the user stops there), output a concise summary:

- **Entry point:** idea / spec / plan
- **Run mode:** go/no-go / autonomous
- **Spec DA-loop:** N rounds, M decisions escalated
- **Plan DA-loop:** N rounds, M decisions escalated
- **Implementation:** outcome (tasks completed, tests passing, or where it stopped)
- **Outstanding:** any Low / deferred items, or decisions still open

## Honest pitfalls to avoid

- **Auto-proceeding past a real decision.** If a DA loop surfaces an ambiguous requirement or a tradeoff, that's a PAUSE — even in "autonomous" mode. Autonomous governs the pre-implementation gate, not the judgement gates.
- **Pausing on everything.** A fix you can make from the artifact and codebase is *not* a blocking decision. Don't kick routine fixes back to the user — that defeats the point.
- **Guessing on a blocking item to keep the pipeline moving.** Inventing an answer to avoid an interruption is worse than the interruption. Surface it.
- **Skipping the run-mode question.** Always ask it once up front; don't assume autonomous.
- **Fabricating earlier artifacts.** Entered at the plan? Don't reverse-engineer a spec to look complete. Start where the artifact actually is.
- **Re-running the brainstorm autonomously.** Brainstorming needs the user. Never try to answer its questions yourself to stay hands-off.
