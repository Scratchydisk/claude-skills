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

- **Min 2, max 4 rounds.** Two-round minimum reflects that round 1 frequently misses things round 2 catches; four-round maximum reflects observed diminishing returns on the cattery rollout.
- **Stop criteria:** a round that finds only Low / cosmetic / nit-pick issues (or finds nothing) AND you've done ≥ 2 rounds. Otherwise continue.
- **Each round = one commit.** `docs(plan): DA round N — <summary>` or equivalent. Makes the trail auditable.

## Honest pitfalls

- Manufactured concerns to fill rounds. If round N finds only nits, stop — do not invent.
- Bundling cosmetic fixes with correctness fixes. Each round focuses on real bugs.
- Reviewing from memory instead of re-reading the artifact each round. Fixes can introduce new issues.

See `SKILL.md` for the per-round protocol.
