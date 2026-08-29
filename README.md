# scratchydisk-skills

Personal Claude Code skills library — workflow orchestration helpers I built after observing the patterns I kept hand-orchestrating across long-running projects.

## Skills

### `devils-advocate-loop`

Iterates devil's-advocate review on a plan or spec until a round finds no real bugs. Each round: surface concerns, apply fixes inline, commit, repeat. Min 2 rounds, max 5. Stops when only nits / cosmetic issues remain.

Use it when refining a written artifact (plan, spec, design doc) before execution. For one-shot review of finished code, use the original `devils-advocate` skill instead.

See [`skills/devils-advocate-loop/`](skills/devils-advocate-loop/) for the full definition.

### `contract-audit`

Audits a spec for the contracts an implementer must not have to guess: data-structure fields, enum values and their casing, cross-module signatures, shared constants and units, ambiguous field meanings, observable acceptance criteria, ownership and invocation, toolchain coherence, every literal in the spec's own examples matching both the definition it exercises and the code that binds it, and whether every value something reads has something that writes it. Ten rows, every one answered, no severity ranking and no concern budget — the properties that make adversarial review miss omissions. Also runs in VERIFY mode against finished code to catch seams that drifted anyway.

Use it when a spec will be implemented by someone (or something) that didn't write it, or when work is split across separately-reviewed tasks — per-task review can't catch cross-task drift by construction. It answers "is this implementable"; `devils-advocate-loop` answers "is this right", and runs after.

See [`skills/contract-audit/`](skills/contract-audit/) for the full definition.

### `spec-to-ship`

Orchestrates the full chain from idea to implementation — brainstorm → spec → contract-audit → DA-loop → plan → contract-audit (C9+C10+C11) → DA-loop → implement → contract-audit (VERIFY) → run it for real — with completeness and devil's-advocate gates between stages. Auto-detects where to start (idea, existing spec, or existing plan), hardens each artifact, and pauses only for decisions that need your judgement (ambiguous requirements, scope/architecture tradeoffs, missing info). Asks once up front whether to do a final go/no-go before implementation or run fully autonomous.

Use it when you'd otherwise hand-orchestrate that pipeline. For a single DA pass on one artifact, use `devils-advocate-loop`; for one-shot review of finished code, use `devils-advocate`.

See [`skills/spec-to-ship/`](skills/spec-to-ship/) for the full definition.

### `karpathy-guidelines`

Behavioural guidelines that reduce common LLM coding mistakes — surface assumptions, keep changes surgical, prefer simplicity, define verifiable success criteria. Derived from Andrej Karpathy's observations on LLM coding pitfalls.

Use it when writing, reviewing, or refactoring code and you want the model to push back on ambiguity instead of guessing, and to avoid drive-by refactors and bloated abstractions.

See [`skills/karpathy-guidelines/`](skills/karpathy-guidelines/) for the full definition.

### `anti-ai-tells`

A field guide for stripping the AI-chatbot fingerprint out of prose — puffery, suspicious triplets, "not only X but also Y", trailing -ing analysis, formulaic section structure, em-dash overuse, and the other patterns that signal "this was generated." Thirteen pattern categories plus a twelve-item review checklist.

Use it when drafting or reviewing long-form prose (articles, blog posts, essays, reports, Wikipedia edits, marketing copy, emails, fiction) — anywhere "this was clearly written by ChatGPT" would be a problem. Also useful as a self-review pass after generating any long text.

See [`skills/anti-ai-tells/`](skills/anti-ai-tells/) for the full definition.

### `plantuml-diagrams`

Guidance for creating and refining PlantUML block, architecture, component, deployment, state, and flow diagrams — building from semantics before syntax, applying restrained visual hierarchy, and rendering + inspecting the output rather than trusting `-checkonly` alone.

Use it when a diagram should be diffable, reproducible, and maintained beside code or specs.

See [`skills/plantuml-diagrams/`](skills/plantuml-diagrams/) for the full definition.

## Installing

This repo is a Claude Code plugin marketplace. Run these from inside any Claude Code session:

```
/plugin marketplace add Scratchydisk/claude-skills
/plugin install scratchydisk-skills@scratchydisk-skills
```

After installation, skills are available via the `Skill` tool / `/skill-name` invocations in any Claude Code session, regardless of project.

### Updating

Claude Code refreshes marketplaces and installed plugins at startup when auto-update is enabled for the marketplace. Third-party marketplaces (this one) default to **auto-update off** — enable it once and updates land on the next launch.

To turn auto-update on:

1. Run `/plugin` to open the plugin manager.
2. Select **Marketplaces** → `scratchydisk-skills`.
3. Choose **Enable auto-update**.

When a plugin updates, Claude Code prompts you to run `/reload-plugins` to pick up changes without restarting.

To refresh manually instead of enabling auto-update:

```
/plugin marketplace update scratchydisk-skills
/reload-plugins
```

See [Configure auto-updates](https://code.claude.com/docs/en/discover-plugins#configure-auto-updates) in the official Claude Code docs for details, including how administrators can force auto-update for an org via `extraKnownMarketplaces`.

## Other runtimes

The canonical sources are the directories under `skills/`; Claude Code, Codex, and OpenCode consume those sources through their own discovery and distribution mechanisms. The Claude Code plugin instructions above remain the supported Claude Code route.

- [Codex installation and distribution](docs/codex.md)
- [OpenCode discovery and symlink installation](docs/opencode.md)
- [Portability rules, dependency map, and verified provenance](docs/runtime-portability.md)

## Layout

```
.
├── .claude-plugin/
│   ├── plugin.json        # plugin manifest
│   └── marketplace.json   # marketplace manifest
├── skills/
│   ├── devils-advocate-loop/
│   │   ├── SKILL.md       # skill body — what Claude reads
│   │   ├── README.md      # human-readable docs
│   │   └── references/    # bundled reference material
│   ├── contract-audit/
│   │   ├── SKILL.md
│   │   └── README.md
│   ├── spec-to-ship/
│   │   ├── SKILL.md       # orchestrator skill body
│   │   └── README.md      # human-readable docs
│   ├── karpathy-guidelines/
│   │   ├── SKILL.md
│   │   ├── README.md
│   │   └── references/
│   ├── anti-ai-tells/
│   │   ├── SKILL.md
│   │   └── README.md
│   └── plantuml-diagrams/
│       ├── SKILL.md
│       ├── README.md
│       └── agents/        # non-Claude agent runner config, unused by Claude Code
└── README.md              # this file
```

## Adding new skills

1. Drop a new skill directory under `skills/<skill-name>/` with at minimum a `SKILL.md` containing YAML frontmatter (`name`, `description`) and the skill body.
2. Bump the `version` field in **both** `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`. The `plugin.json` value silently wins if they disagree, so a stale manifest masks the bump and existing users see no update.
3. Commit, tag (`vX.Y.Z`), push the branch and the tag.
4. Users with auto-update enabled get the new version on their next Claude Code launch; others run `/plugin marketplace update scratchydisk-skills` followed by `/reload-plugins`.

## Acknowledgements

The devil's advocate questioning frameworks and blind-spot references were derived from [notmanas/claude-code-skills](https://github.com/notmanas/claude-code-skills).

The `karpathy-guidelines` skill is imported from [Scratchydisk/andrej-karpathy-skills](https://github.com/Scratchydisk/andrej-karpathy-skills) (a fork of [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)), derived from [Andrej Karpathy's observations on LLM coding pitfalls](https://x.com/karpathy/status/2015883857489522876). MIT-licensed.

The `anti-ai-tells` skill was written by [Andy Sheldon](https://github.com/andysheldon-creator) and distilled from [Wikipedia:Signs of AI writing (WP:AISIGNS)](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing). The underlying pattern taxonomy traces to WP:AISIGNS, which is CC BY-SA — credit accordingly if you reuse the material.

The `plantuml-diagrams` skill is imported from a private project.

## Licence

MIT — see [`LICENSE`](LICENSE).
