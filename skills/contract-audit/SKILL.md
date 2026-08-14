---
name: contract-audit
description: "Audits a spec for the contracts an implementer actually needs — data-structure fields, vocabularies and their casing, cross-module signatures, shared constants, observable acceptance criteria, and whether every value something reads has something that writes it. Enumerative: you fill a fixed checklist, with no severity ranking and no concern budget. Run BEFORE devils-advocate-loop — implementable first, then right. Also runs in VERIFY mode against finished code to catch seams that drifted anyway. Use when a spec will be implemented by someone (or something) that did not write it."
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

Work through all ten contracts. For each: state PASS or FAIL, and cite where it is defined or say precisely what is absent.

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
**In VERIFY mode, ask it of the test, not the criterion: could this test fail?** A test that asserts the behaviour of something the harness fakes is not evidence — it measures the fake. Where a stub is *more permissive* than the real implementation (a validator hardcoded true, an in-memory database that enforces no constraint the real one does), every assertion downstream of it is unfalsifiable, and a green suite is a measurement of the harness. Either construct the real implementation or move the assertion to a unit test with an explicit stub whose limits you state.
**Seen in the wild:** "Visual modes functional" was satisfied by five modes that rendered pixel-identically. "Tests passing" was satisfied by `assertEqual(true, true)`. A `FakeLookupCache.IsValidCode<T>()` returning a hardcoded `true` made a whole class of validation test incapable of failing; its `GetValues<T>()` read the database generically, so it resolved types the real cache never loaded and the feature's twelve lookups were never registered anywhere.
**Rewrite test:** "each of the five modes must produce a different canvas fingerprint from the same input" — that you can check. "Visual modes functional" you cannot.

### C7 — Ownership and invocation

**Check:** for every behaviour the spec promises, it names the module that implements it **and what calls it**.
**FAIL when:** the spec says the system will do something but never says what triggers it.
**Seen in the wild:** `handleBuildClick()` was written and wired to no event — clicking the map did nothing at all. `addResident()` was never called by anything, pinning population and every employment figure at zero. Both existed, both looked complete, neither ran.

### C8 — Toolchain coherence

**Check:** the stated build, test and run strategy is actually executable in the stated architecture.
**FAIL when:** the two sections contradict each other.
**Seen in the wild:** a spec mandating ES modules also said "tests run in the browser via `<script>` tags, no test runner required". The result was 21 script tags in one HTML file and eight of nine test suites that were never executed by anything.

### C9 — Example conformance

**Check:** every literal in the spec — URL, query string, JSON key, header, CLI flag, env var, code snippet, test body — matches the normative definition it exercises. A spec that defines a vocabulary and then violates it in its own example is a **FAIL**, not a PASS: implementers copy the example, not the table.
**FAIL when:** a code block's identifiers, casing or wire names disagree with the section that defines them.
**Method:** extract each literal and diff it against its definition. Do not read for plausibility — compare strings.
**Check against the *receiving* side, not the artifact's prose.** A literal's definition is whatever code binds it — the DTO property, the route handler, the arg parser, the env reader. Where the artifact and the receiver disagree, the artifact is wrong even if it is internally consistent. This does not conflict with the pitfall against reconstructing contracts from the codebase: that bars using your repo knowledge to mark a row PASS, and this can only ever produce a FAIL.
**Where a project maps display names to wire names, quote the mapping beside each literal.** A literal that survives a translation layer is unverifiable on its own — the reader cannot tell a correct pretty name from an incorrect wire name. The fix for a C9 FAIL of this kind is the literal *plus* its mapping, not the corrected literal alone.
**Seen in the wild:** a spec defined a normative pretty→DTO query-param mapping table, then shipped an integration-test snippet that GET'd the pretty name. The param was silently ignored, the assertion failed on unfiltered results, and it read like a broken filter rather than a wrong URL. C2 passed — the table existed — and four review gates read the example as illustration.

### C10 — Producer/consumer closure

**Check:** every value a promised behaviour *reads* has a named producer and a named route — which endpoint, import, migration, seed, sync job or admin screen writes it. Trace provenance, not call sites.
**FAIL when:** the spec names something that consumes a value and never says what puts the value there.
**Why C7 does not catch this:** C7 is one-directional. It asks what invokes a behaviour, and a consumer *with* an invoker passes — even when its own input has no writer anywhere. Call-site greps come back clean; the chain is broken one link upstream. This is the flavour that survives every reading gate.
**Registration is a write.** A type absent from the list its reader enumerates is an unproduced value, even though the reader exists, is called, and the type is defined.
**On a plan this is mechanical:** every symbol in a task's `Consumes:` block must appear in some earlier task's `Produces:` block. A set difference, not a judgement — and the metadata is usually already there, unchecked.
**Seen in the wild:** `ApproveAsync` set `system_owner_id` from `business_owner_person_id`, and the Approve endpoint called it — C7 passed 8 of 8. Nothing in the system ever wrote `business_owner_person_id`: no DTO field, no import, no admin screen. Approval materialised a null owner, and two sibling columns had the same defect. Separately, twelve new lookup types were defined, migrated and consumed, but never added to the cache's load list — so the feature had never worked at all against a real database, behind 1,163 passing tests.

### The silence test

For each contract ask: *if the two sides disagreed, would anything fail loudly?* If the answer is no — a param silently ignored, a null quietly defaulted, a field `undefined` rather than absent — the contract needs a mechanical conformance check, not a definition and a review. All six blocking rows — C1, C2, C3, C7, C9, C10 — block for precisely this reason. C9 is the same instinct turned on the document's own literals: the definition and the receiver can disagree indefinitely without either one complaining. C10 is it turned on the data's origin: an absent producer is the quietest disagreement there is, because there is no second side to disagree with.

### Output

One table. Nothing else before it.

```
| # | Contract | Status | Where defined / what is missing |
|---|----------|--------|----------------------------------|
| C1 | Data-structure fields | FAIL | `Cell` named in the file tree; no fields anywhere |
| C2 | Vocabularies and casing | FAIL | `"RESIDENTIAL"` only inside the save-format example |
| ... |
| C10 | Producer/consumer closure | FAIL | `business_owner_person_id` read by `ApproveAsync`; no writer named |
```

Then, for each FAIL, one line stating the smallest addition that would make it PASS. Do not write the contract yourself unless asked — the author may know something you do not.

Close with: **`N of 10 contracts defined. This spec is / is not ready to implement.`** Any FAIL in C1, C2, C3, C7, C9 or C10 means not ready — those are the six that produce silent, invisible defects rather than loud ones.

## Mode B — VERIFY (finished code)

Same ten contracts, asked backwards: does the code honour them? This is the cross-cutting pass that per-task review structurally cannot perform, because each task's review only ever sees its own side of the seam.

The method is retrieval, not recall. For every identifier read from another module, prove it exists:

```bash
grep -rn "\.someField" src/          # is it ever written, or only read?   (C10)
grep -rn "functionName" src/ | wc -l # 1 hit means defined and never called (C7)
```

For C10, ask it of each *new* persisted column and each *new* type: does anything in `src/` assign it, and does it appear in every list that must enumerate it? A column no code writes is the signature of the defect, and it is a one-line query.

Report as a table of contract → holds / violated → evidence. Where the repo has a mechanical checker, run that instead and only inspect what it cannot express — a script is cheaper and more reliable than a model for anything deterministic.

**Leave a checker behind.** If a contract fails VERIFY twice in the same repo, the finding is not the violation — it is that a model is being asked to do a machine's job. Write the check as a script the repo can run, name it in the project's instructions, and run it at every full-suite gate rather than only at the end. The full audit stays where it is; the script is what moves earlier, because it costs seconds and the per-task reviews structurally cannot see what it sees.

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
brainstorm → spec → [contract-audit] → [DA-loop] → plan → [contract-audit: C9+C10] → [DA-loop] → implement → [contract-audit: VERIFY]
```

The gate before the loop, in that order deliberately: *implementable*, then *right*. There is no value in arguing about tick ordering while the core data structure has no defined fields.

**The plan gets a C9+C10 pass.** The spec audit checks *implementable*; the plan audit checks *transcribable* and *closed*. A plan carries far more literals than the spec that produced it — task-by-task code snippets, test bodies, interface blocks — and it is the artifact implementers actually read. A plan whose test code contradicts its own interfaces block wastes a fix round at best and ships a wrong name at worst.

C10 belongs here because a plan is where provenance becomes checkable: the tasks are ordered, so "nothing produces this before something consumes it" is a set difference over the `Consumes:` / `Produces:` blocks the plan already carries. A plan can be perfectly transcribed and still have no task that ever writes a field every later task reads.

A caller may scope the audit to those two rows for a downstream artifact like this. That is not triage and does not licence a budget: within the scope you are given, every literal gets compared and every consumed symbol gets traced.

## Honest pitfalls to avoid

- **Reconstructing the contract from the codebase and marking it PASS.** You have the repo; the implementer may not, and a local model certainly will not go looking. Judge the spec, not your own knowledge.
- **Accepting a diagram as a signature.** Boxes and arrows show topology. They define nothing.
- **Accepting one incidental mention as normative.** A value inside an example is illustration. C2 wants a statement.
- **Reading a code block for plausibility instead of diffing it.** C9 fails when the example *looks* right against prose you already believe. Compare strings, character by character, against the definition — not against your reading of the intent.
- **Counting a schema as a producer.** A migration that creates a column, a type that implements the interface, a field on a DTO nobody populates — these make a value *possible*, not *present*. C10 wants the write, and the route a real user or job takes to reach it.
- **Marking C10 PASS because the consumer has callers.** That is C7, and it passes on precisely the case C10 exists to catch.
- **Triaging.** The moment you start deciding which gaps matter, you have turned this back into a review and reintroduced exactly the bias that loses the fatal ones.
- **Drifting into design critique.** "This enum should have a sixth value" is out of scope. Note it for the DA loop and move on.
- **Marking C6 PASS because criteria exist.** Criteria almost always exist. The question is whether any of them could fail.
