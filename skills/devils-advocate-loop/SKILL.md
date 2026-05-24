---
name: devils-advocate-loop
description: "Iterates devil's-advocate review on a plan or spec until a round finds no real bugs. Each round: surface concerns, apply fixes inline, commit, repeat. Min 2 rounds, max 4. Stops when only nits/cosmetic issues remain. Use when refining a written artifact before execution — not for one-shot review (use /devils-advocate for that)."
---

# Devil's Advocate Loop

You are running iterative devil's-advocate review on a written artifact (plan, spec, design doc) until it's stable. Each round you wear two hats: the reviewer (challenge it) and the implementer (apply fixes). Between rounds you commit the diff. You stop when a round finds nothing real left to fix.

**Announce at start:** "I'm using the devils-advocate-loop skill — running rounds until a clean pass."

## When to use this skill

- A plan or spec is written and you want to harden it before execution.
- You've already done one DA round and want to keep going systematically until clean.
- Cross-phase rollouts where each phase artifact deserves multiple passes before subagents execute it.

## When NOT to use this skill

- One-shot code review of an already-implemented PR — use `/devils-advocate` instead and stop after one report.
- The artifact you'd be reviewing doesn't exist yet — write it first, then loop.
- The target is already merged / shipped — fixing it requires a different workflow (debug, PR).

## Core rules

- **Minimum 2 rounds.** Even if round 1 finds nothing, do round 2 — the framework rewards a second look.
- **Maximum 4 rounds.** After 4, stop regardless. Diminishing returns are real.
- **Stop earlier when a round finds no real bugs.** Critical + High + actionable-Medium issues are "real bugs." Low / cosmetic / nitpick issues are not — they may be noted but do not justify another round.
- **Fix what you find.** Unlike standalone `/devils-advocate`, this skill applies the fixes inline. Read the file, Edit it, commit the result.
- **One commit per round** with message `docs(plan): DA round N — <one-line summary>` (or `docs(spec): DA round N — ...` etc., matching what's being fixed).
- **Don't manufacture concerns.** If a round legitimately finds nothing real, declare it clean and stop. Performative thoroughness is a failure mode, not a success.

## Per-round process

For each round (round numbers are 1-indexed counting from your first round; honour any prior rounds the user mentions):

### 1. Steel-man (one or two sentences)

State briefly what the artifact gets right. If you can't articulate this, your review is probably off-base — read the artifact again before continuing.

### 2. Apply the questioning frameworks

Use the bundled references (relative to this skill's directory):

- `references/questioning-frameworks.md` — pre-mortem, inversion, Socratic probing, Six Thinking Hats, Five Whys
- `references/blind-spots.md` — security, scalability, data lifecycle, integration points, failure modes, concurrency, env gaps, observability, deployment, edge cases, multi-tenancy
- `references/ai-blind-spots.md` — happy path bias, scope acceptance, confidence without correctness, pattern attraction, reactive patching, context rot, library hallucination, security as afterthought, over-abstraction

Load only the references you need; don't dump them into context unnecessarily.

### 3. Surface up to 7 concerns, ranked by severity

Format each concern:

```
Concern: <one-line summary>
Severity: Critical | High | Medium | Low
Framework: <which framework surfaced this>

What I see:
  <specific issue with file:line references where possible>

Why it matters:
  <consequence if not fixed>

What to do:
  <specific, actionable fix>
```

- Critical: data loss, security breach, will not work at all
- High: significant user impact, real technical correctness issue, blocks downstream work
- Medium: worth fixing but won't block shipping; quality / clarity / robustness issues
- Low: cosmetic, style, nice-to-have

Honest severity matters. Don't inflate.

### 4. Apply fixes

For every Critical + High + actionable-Medium concern:
- Edit the file with the fix
- Where the fix is a structural change (e.g. "split this into three components"), describe what you did concretely

You may also surface Low issues but do not fix them — note them in the round's report for the user's awareness.

### 5. Commit

Single commit at the end of the round. Stage the modified artifact(s) only — don't sweep in unrelated changes.

```bash
git add <files modified during this round>
git commit -m "docs(plan): DA round N — <one-line summary of what got fixed>"
```

If you're working in a worktree, the branch is whatever the user is currently on — don't switch.

### 6. Decide: continue or stop

- **If this round found Critical / High / actionable-Medium issues** → continue to the next round, up to the max of 4.
- **If this round found only Low / cosmetic issues OR found nothing** → stop **provided you have done at least 2 rounds**. If this was round 1, do one more round to confirm.
- **After 4 rounds** → stop regardless. Note any remaining Low issues in the final report.

## Final report

After the last round, output a single concise summary (≤ 400 words):

- **Rounds completed:** N
- **Stopped because:** (clean round / hit max)
- **Per-round summary table:**

| Round | Critical | High | Medium | Low | Commit |
|---|---|---|---|---|---|
| 1 | 1 | 2 | 1 | 0 | abc123 |
| ... | | | | | |

- **Remaining Low / unfixed notes** (if any): bullet list
- **Recommendation:** ready for execution / one more round next session / etc.

## Honest pitfalls to avoid

- **Manufacturing concerns to look thorough.** If you find <2 real issues in a round and you're past the minimum, that's the signal to stop. Don't keep going.
- **Bundling cosmetic fixes with real fixes.** Each round should focus on the real bugs; cosmetic cleanup can be separate work.
- **Commit hygiene drift.** Each round = one commit. Don't fix in dribbles.
- **Ignoring the steel-man step.** Skipping it makes the round noisy because you're not anchored on what's right.
- **Not reading the artifact between rounds.** Fixes in round N may have introduced new issues — re-read each time. Don't review from memory.
- **Looping on the same artifact past 4 rounds.** If you're still finding real issues at round 4, the artifact needs a rewrite, not more polish.
