# scratchydisk-skills

Personal Claude Code skills library — workflow orchestration helpers I built after observing the patterns I kept hand-orchestrating across long-running projects.

## Skills

### `devils-advocate-loop`

Iterates devil's-advocate review on a plan or spec until a round finds no real bugs. Each round: surface concerns, apply fixes inline, commit, repeat. Min 2 rounds, max 4. Stops when only nits / cosmetic issues remain.

Use it when refining a written artifact (plan, spec, design doc) before execution. For one-shot review of finished code, use the original `devils-advocate` skill instead.

See [`skills/devils-advocate-loop/`](skills/devils-advocate-loop/) for the full definition.

## Installing

This repo is a Claude Code plugin marketplace.

```bash
# Add the marketplace (one-time per machine)
claude plugins marketplace add Scratchydisk/claude-skills

# Install the plugin
claude plugins install scratchydisk-skills
```

After installation, skills are available via the `Skill` tool / `/skill-name` invocations in any Claude Code session, regardless of project.

To update later:

```bash
claude plugins update scratchydisk-skills
```

## Layout

```
.
├── .claude-plugin/
│   ├── plugin.json        # plugin manifest
│   └── marketplace.json   # marketplace manifest
├── skills/
│   └── devils-advocate-loop/
│       ├── SKILL.md       # skill body — what Claude reads
│       ├── README.md      # human-readable docs
│       └── references/    # bundled reference material
└── README.md              # this file
```

## Adding new skills

1. Drop a new skill directory under `skills/<skill-name>/` with at minimum a `SKILL.md` containing YAML frontmatter (`name`, `description`) and the skill body.
2. Bump `plugin.json` and `marketplace.json` versions.
3. Tag a release.
4. Run `claude plugins update scratchydisk-skills` on every machine.

## Acknowledgements

The devil's advocate questioning frameworks and blind-spot references were derived from [notmanas/claude-code-skills](https://github.com/notmanas/claude-code-skills).

## Licence

MIT — see [`LICENSE`](LICENSE).
