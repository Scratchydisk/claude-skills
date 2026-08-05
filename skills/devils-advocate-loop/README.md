# devils-advocate-loop

A meta-skill that runs the `devils-advocate` review process iteratively until a round finds nothing real left to fix. Built after observing that 15 DA rounds across the look-and-feel rollout (Phases 0–3) were all hand-orchestrated — invoke `/devils-advocate`, read the report, apply fixes, commit, invoke again, repeat. This skill collapses that loop into one invocation.

## When this beats raw `/devils-advocate`

| Situation | Use |
|---|---|
| One-shot review of a finished PR | `/devils-advocate` |
| Refining a plan or spec before execution | `/devils-advocate-loop` |
| Pre-implementation hardening of an architectural decision | `/devils-advocate-loop` |
| Code review during PR triage | `/devils-advocate` |
| Multi-phase rollout (one DA-loop per phase plan) | `/devils-advocate-loop` per phase |

## Round economics

- **Min 2, max 5 rounds.** Two-round minimum reflects that round 1 frequently misses things round 2 catches; five-round maximum reflects observed diminishing returns on the cattery rollout.
- **Stop criteria:** a round that finds only Low / cosmetic / nit-pick issues (or finds nothing) AND you've done ≥ 2 rounds. Otherwise continue.
- **Each round = one commit.** `docs(plan): DA round N — <summary>` or equivalent. Makes the trail auditable.

## Escalation mode (optional, off by default)

Standalone, the loop fixes every real issue inline. When a caller enables **escalation mode** (notably [`spec-to-ship`](../spec-to-ship/)), the loop instead surfaces the rare finding that genuinely needs a human decision and fixes the rest. It defaults to fix-inline and escalates only when a finding passes a strict triple-AND gate: materially different reasonable implementations, *and* hard to reverse or user-/business-/legally-visible, *and* not pickable from the artifact or codebase — with an explicit "never chain escalations" rule.

This wording was tuned against a 15-run micro-test. A naïve two-bucket instruction over-escalated badly (escalating ~10 routine findings per round, with wild run-to-run variance); the tuned gate converged to exactly the one genuine decision per round. See `SKILL.md` for the full criteria.

## Honest pitfalls

- Manufactured concerns to fill rounds. If round N finds only nits, stop — do not invent.
- Bundling cosmetic fixes with correctness fixes. Each round focuses on real bugs.
- Reviewing from memory instead of re-reading the artifact each round. Fixes can introduce new issues.
- (Escalation mode) Over-escalating routine gaps. Under-specified ≠ undecidable — fix what has a conventional default; escalate only genuine decisions.
- Treating code embedded in the artifact as illustration. Rounds can agree with a normative table and never notice the example below it violates it — agreeing with prose feels like reviewing. That comparison is `contract-audit` C9's job; the loop's job is to notice when it hasn't run.

## Attribution

The raw devil's advocate skill material (questioning frameworks, blind-spot references) originates from [notmanas/claude-code-skills](https://github.com/notmanas/claude-code-skills).

See `SKILL.md` for the per-round protocol.
