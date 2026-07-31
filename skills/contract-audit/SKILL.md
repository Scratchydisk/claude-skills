---
name: contract-audit
description: "Audits a spec for the contracts an implementer actually needs — data-structure fields, vocabularies and their casing, cross-module signatures, shared constants, observable acceptance criteria. Enumerative: you fill a fixed checklist, with no severity ranking and no concern budget. Run BEFORE devils-advocate-loop — implementable first, then right. Also runs in VERIFY mode against finished code to catch seams that drifted anyway. Use when a spec will be implemented by someone (or something) that did not write it."
---

# Contract Audit

You are checking whether a spec defines the things an implementer must not have to guess. This is a **completeness audit, not a review.** You are not judging whether the design is good — that is `devils-advocate-loop`'s job, and it runs after this one.

**Announce at start:** "I'm using the contract-audit skill — filling the contract checklist before review."

## Why this is a separate skill

Adversarial review finds bad answers. It does not find missing questions.

Pre-mortem, inversion, Socratic probing and Five Whys all reason *outward from what is written*. An absent field list gives them nothing to seed on — you can pre-mortem "the city dies at tick 375", but you cannot pre-mortem a definition nobody wrote. Worse, a "surface up to 7 concerns, ranked by severity" budget systematically drops completeness gaps, because the consequence of an omission is invisible until implementation. "This data structure has no field list" reads as Low next to data loss, loses the slot, and later turns out to have been the fatal defect.

So this skill inverts every one of those properties. Fixed list. Every row answered. No ranking. No budget.

## When to use this skill

- A spec or design doc is about to be handed to an implementer — a subagent, a teammate, a local model, or you in two weeks.
- Work will be split across tasks that are reviewed separately. Per-task review cannot catch cross-task drift by construction; this can.
- Code is finished and you want to know whether it honours the contracts (VERIFY mode).

## When NOT to use this skill

- The artifact is prose with no implementation to follow — nothing to contract.
- You want to know whether a decision is *correct or risky* — that is `devils-advocate-loop`.
- One-shot code review of a PR — use `/devils-advocate`.

## Core rules

- **Answer every row.** No budget, no "up to N", no triage. A checklist you are allowed to skip is a checklist that gets skipped.
- **PASS requires a citation.** Quote the file, section or line where the contract is defined. "Implied", "obvious", "standard practice" and "the diagram shows it" are all **FAIL**.
- **Do not rank by severity.** Every FAIL is a gap. Which to fix is the author's call, not yours.
- **Do not argue with the design.** If the spec defines a bad enum, that is a PASS for this skill. Correctness is the next gate's problem.
- **A component named but never defined is a FAIL, not an N/A.** "Cell.js — individual cell data" names a thing and defines nothing.
- **Silence is never PASS.** If you cannot find it, it is missing. Do not reconstruct it from the codebase and then mark it defined — the point is whether the *implementer* would have to guess.

## Mode A — AUDIT (a spec, before implementation)

Work through all eight contracts. For each: state PASS or FAIL, and cite where it is defined or say precisely what is absent.

### C1 — Data-structure fields

**Check:** every data structure named anywhere in the spec has an explicit list of its fields.
**FAIL when:** a structure is named in a diagram or file tree with only a prose gloss.
**Seen in the wild:** a spec listed `Cell.js — Individual cell data` and never named a field. The renderer read `cell.buildingType`; the model defined `kind`. Being `undefined`, it passed both the `!== 'road'` and `!== null` guards, so all 4096 cells drew as generic buildings and the city was invisible.

### C2 — Vocabularies and casing

**Check:** every enum, status, kind or type has its exact literal values written once, normatively, including casing.
**FAIL when:** the values only ever appear incidentally — inside a JSON example, a code snippet, or one module's constants.
**Seen in the wild:** `"kind": "RESIDENTIAL"` appeared exactly once, inside a save-format example. The implementation used lowercase in `constants.js` and uppercase everywhere else, so cost lookups and factory switches silently fell through to their defaults.

### C3 — Cross-module signatures

**Check:** every call that crosses a module boundary has a name, parameters, return type and failure cases.
**FAIL when:** the architecture is boxes and arrows. An arrow is not a signature.
**Seen in the wild:** `TaxPolicy.levy()` read `building.value` and `building.maintenanceCost`. Neither property existed on any building class, so tax income was exactly zero for the life of the project.

### C4 — Shared constants and units

**Check:** every constant used by more than one module is defined once, with its unit, and named as the single source.
**FAIL when:** a number appears in two places, or appears without a unit.
**Seen in the wild:** hit-testing used a 20px cell against a renderer drawing at 16px, so clicks landed on the wrong tile.

### C5 — Ambiguous field meanings

**Check:** any field whose name admits two readings is disambiguated — condition vs cost, id vs index, count vs capacity, rate vs amount, local vs UTC.
**FAIL when:** the name is the only definition.
**Seen in the wild:** `maintenance` was a 0..1 condition *and* was summed as a currency cost. Unclamped, it went negative, and derelict buildings paid the treasury ~1650 per tick.

### C6 — Observable acceptance criteria

**Check:** every success criterion names something you could mechanically verify. A criterion must be falsifiable by running the thing.
**FAIL when:** the criterion names an artifact rather than an outcome — "X functional", "X working", "tests passing", "X implemented".
**Seen in the wild:** "Visual modes functional" was satisfied by five modes that rendered pixel-identically. "Tests passing" was satisfied by `assertEqual(true, true)`.
**Rewrite test:** "each of the five modes must produce a different canvas fingerprint from the same input" — that you can check. "Visual modes functional" you cannot.

### C7 — Ownership and invocation

**Check:** for every behaviour the spec promises, it names the module that implements it **and what calls it**.
**FAIL when:** the spec says the system will do something but never says what triggers it.
**Seen in the wild:** `handleBuildClick()` was written and wired to no event — clicking the map did nothing at all. `addResident()` was never called by anything, pinning population and every employment figure at zero. Both existed, both looked complete, neither ran.

### C8 — Toolchain coherence

**Check:** the stated build, test and run strategy is actually executable in the stated architecture.
**FAIL when:** the two sections contradict each other.
**Seen in the wild:** a spec mandating ES modules also said "tests run in the browser via `<script>` tags, no test runner required". The result was 21 script tags in one HTML file and eight of nine test suites that were never executed by anything.

### Output

One table. Nothing else before it.

```
| # | Contract | Status | Where defined / what is missing |
|---|----------|--------|----------------------------------|
| C1 | Data-structure fields | FAIL | `Cell` named in the file tree; no fields anywhere |
| C2 | Vocabularies and casing | FAIL | `"RESIDENTIAL"` only inside the save-format example |
| ... |
```

Then, for each FAIL, one line stating the smallest addition that would make it PASS. Do not write the contract yourself unless asked — the author may know something you do not.

Close with: **`N of 8 contracts defined. This spec is / is not ready to implement.`** Any FAIL in C1, C2, C3 or C7 means not ready — those are the four that produce silent, invisible defects rather than loud ones.

## Mode B — VERIFY (finished code)

Same eight contracts, asked backwards: does the code honour them? This is the cross-cutting pass that per-task review structurally cannot perform, because each task's review only ever sees its own side of the seam.

The method is retrieval, not recall. For every identifier read from another module, prove it exists:

```bash
grep -rn "\.someField" src/          # is it ever written, or only read?
grep -rn "functionName" src/ | wc -l # 1 hit means defined and never called
```

Report as a table of contract → holds / violated → evidence. Where the repo has a mechanical checker, run that instead and only inspect what it cannot express — a script is cheaper and more reliable than a model for anything deterministic.

## Contracts established outside this spec

A contract does not have to be written *in the spec* to PASS. It has to be somewhere the implementer will reliably be handed before they write code. This skill is agnostic about where that is — a standards library, a linked ADR, a house style guide, a governed knowledge base, a shared types package.

**If the caller supplies a set of already-established contracts, treat them as part of the artifact.** A workflow skill that owns a contract store is expected to gather them and pass them in; that is its job, not yours. You never go looking for a store yourself, and you never name one.

To count, an external contract must meet all three:

1. **Citable** — you can point at the specific document or definition, not at "our conventions".
2. **Served, not merely available** — the implementer is *given* it before coding. Discoverable-if-you-think-to-look is a FAIL; the whole defect class comes from implementers who did not know to look.
3. **Bound to this work** — it actually applies to the modules in this spec, and something ties the two together.

Mark such rows `PASS (external)` and cite the source. If any of the three fails, the row fails.

**Fix external gaps at the source.** When a FAIL is not specific to this one spec — a vocabulary, a serialisation convention, a naming rule — say so, and say it should be added to whatever store the caller is using rather than patched into this document. A contract written into a single spec is a contract the next project will get wrong.

**Do not count "it is already in the codebase."** See the pitfalls: you have the repo, the implementer may not, and a fresh context certainly will not go looking.

## Stack-specific checklists

Mature teams accumulate contract checklists the hard way — one production bug per row. Serialisation casing, pagination envelope shapes, `status` vs `state`, middleware registration order. These are valuable and you should credit them: where such a checklist exists and the spec fills it in, mark the row PASS and cite it.

Two cautions when auditing alongside one:

- **They are usually organised by technology, not by contract class**, so they protect the stack they grew up in and nothing else. C1–C5 are the stack-agnostic form of the same instinct. Apply them wherever this system's seams actually are, which may be nothing like HTTP.
- **They usually cover one seam type.** A checklist grown from frontend↔backend bugs will say nothing about module A reading a field from module B inside a single codebase — and that seam produces the silent defects, because nothing crosses a wire where you might have noticed.

## Where this sits in spec-to-ship

```
brainstorm → spec → [contract-audit] → [DA-loop] → plan → [DA-loop] → implement → [contract-audit: VERIFY]
```

The gate before the loop, in that order deliberately: *implementable*, then *right*. There is no value in arguing about tick ordering while the core data structure has no defined fields.

## Honest pitfalls to avoid

- **Reconstructing the contract from the codebase and marking it PASS.** You have the repo; the implementer may not, and a local model certainly will not go looking. Judge the spec, not your own knowledge.
- **Accepting a diagram as a signature.** Boxes and arrows show topology. They define nothing.
- **Accepting one incidental mention as normative.** A value inside an example is illustration. C2 wants a statement.
- **Triaging.** The moment you start deciding which gaps matter, you have turned this back into a review and reintroduced exactly the bias that loses the fatal ones.
- **Drifting into design critique.** "This enum should have a sixth value" is out of scope. Note it for the DA loop and move on.
- **Marking C6 PASS because criteria exist.** Criteria almost always exist. The question is whether any of them could fail.
