# contract-audit

An enumerative completeness gate for specs, run before `devils-advocate-loop`. Built after a post-mortem on a web app where a spec passed a brainstorm and a full devil's-advocate loop, and the implementation still could not be played: it rendered a uniform grey field, clicking the map did nothing, every statistic read zero and all five view modes drew identically.

Roughly **eight of ten defects were licensed by the spec, not committed against it.** The spec described structure thoroughly — file tree, tick order, save JSON, a controls table, performance notes — and defined almost no contracts. No data-structure fields, no signatures, one incidental mention of an enum inside a JSON example, and success criteria of the form "visual modes functional".

## Why the DA loop did not catch it

It structurally cannot, and that is not a defect in it.

| Property | devils-advocate-loop | contract-audit |
|---|---|---|
| Mode | generative — reasons outward from what is written | enumerative — walks a fixed list |
| Budget | up to 7 concerns | every row, always |
| Ranking | by severity | none; every gap is a gap |
| Finds | bad answers | missing questions |
| Question | "is this right?" | "is this implementable?" |

An omission offers nothing to argue against. A severity-ranked list of seven will always drop "this structure has no field list" below "no security model" — and in the case that prompted this skill, the dropped row was the fatal one.

Its reference library confirms the gap by construction: across `blind-spots.md`, `ai-blind-spots.md` and `questioning-frameworks.md`, the terms `field name`, `signature` and `identifier` appear zero times. Its "Integration Points" section is about external systems being flaky or slow, not about two of your own modules disagreeing on a field name.

## When this beats the alternatives

| Situation | Use |
|---|---|
| Spec about to be handed to an implementer who did not write it | `contract-audit` |
| Spec is implementable and you want to harden the decisions | `devils-advocate-loop` |
| Work split across separately-reviewed tasks | `contract-audit` — per-task review cannot see cross-task drift |
| Finished code, want to know whether seams held | `contract-audit` VERIFY mode |
| One-shot review of a finished PR | `/devils-advocate` |

## The ten contracts

C1 data-structure fields · C2 vocabularies and casing · C3 cross-module signatures · C4 shared constants and units · C5 ambiguous field meanings · C6 observable acceptance criteria · C7 ownership and invocation · C8 toolchain coherence · C9 example conformance · C10 producer/consumer closure

Each is derived from a specific defect that shipped. A FAIL in C1, C2, C3, C7, C9 or C10 blocks implementation — those six produce silent defects rather than loud ones.

The **silence test** is why those six block, and the question to ask of any new row: *if the two sides disagreed, would anything fail loudly?* If not — a param silently ignored, a null quietly defaulted, a field `undefined` rather than absent — the contract needs a mechanical conformance check, not a definition and a review.

C9 exists because C2 can pass on a spec that then violates its own table in an example. Implementers copy the example, not the table. It compares literals two ways: against the definition inside the artifact, and against the code that actually binds the name — the DTO property, route handler, arg parser or env reader. An example can be internally consistent and still wrong at the receiver.

C10 exists because C7 is one-directional. C7 asks what invokes a behaviour; a consumer that *has* an invoker passes it, even when the value it reads has no writer anywhere in the system. Orphan writers show up in a call-site grep, but a broken chain does not — the consumer looks wired, and only the provenance is missing. C10 asks the other direction: for every value read, name what writes it and by what route. Registration counts as a write, so a type absent from the list its reader enumerates fails too.

## Pipeline position

```
brainstorm → spec → [contract-audit] → [DA-loop] → plan → [contract-audit: C9+C10] → [DA-loop] → implement → [contract-audit: VERIFY]
```

The spec audit checks *implementable*. The plan audit checks *transcribable* and *closed* — the plan is what implementers read, it carries far more literals than the spec, and its ordered `Consumes:` / `Produces:` blocks make provenance a set difference rather than a judgement.

Implementable first, then right.

## Storage-agnostic by design

The skill owns one thing: **what makes a spec implementable.** It does not know or care where the spec lives, or where contracts are stored — a file, a governed knowledge base, a standards library, a shared types package.

Contracts established elsewhere still count. A caller that owns a contract store gathers them and passes them in; the skill marks those rows `PASS (external)` provided they are citable, actively *served* to the implementer rather than merely discoverable, and bound to the work in hand. It never reaches for a store itself.

That inversion is deliberate: the checklist is defined once, here, and workflow skills that know about storage call into it. Duplicating the checklist into each workflow is how the two copies drift.
