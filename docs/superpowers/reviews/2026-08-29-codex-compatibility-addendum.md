# Codex compatibility addendum

The dual-runtime specification should not claim Codex compatibility from Claude Code or OpenCode results. Codex shares the `SKILL.md` authoring model, but it has its own discovery scopes, installation workflow, configuration, orchestration tools, and plugin distribution path.

## Contracts to add to the specification

### Discovery and installation

- Repository skills are discovered from `.agents/skills` between the working directory and repository root.
- User skills are discovered from `$HOME/.agents/skills`; administrators can use `/etc/codex/skills`.
- External skills such as Superpowers `brainstorming` should be installed with `$skill-installer` from the verified upstream repository, or linked into an official discovery location from a verified checkout.
- Codex detects skill changes automatically; documentation may advise a restart when a new or changed skill does not appear.
- Local skills can be disabled with an exact `[[skills.config]]` entry in `~/.codex/config.toml`.
- If this repository is intended for reusable Codex distribution rather than local development, evaluate a plugin package instead of treating the Claude marketplace manifest as portable.

### Provenance of Superpowers skills

Before documenting installation of `brainstorming`, record:

- canonical upstream repository URL;
- exact subdirectory containing `SKILL.md`;
- immutable revision or release tag;
- licence and attribution requirements;
- whether Codex installation uses `$skill-installer`, a repository `.agents/skills` link, or a plugin;
- whether OpenCode installation uses the same checkout through `~/.config/opencode/skills/brainstorming`.

Do not publish commands containing guessed repository paths. Do not copy the skill into this repository until provenance, licence, and unchanged-host tests pass.

### Compatibility checker

Extend `scripts/check-portability.sh` so its normative rules come from the shared agent-skills contract plus host-specific additions. It must distinguish:

- shared failures that break every host;
- OpenCode-specific failures;
- Codex-specific failures;
- warning-only host terminology.

The checker must not require a runtime-specific installation path inside a reusable skill body.

### Behavioural test matrix

Add a required Codex column for:

- discovery and loading of every canonical skill;
- `contract-audit` C1 and C10 negative fixtures;
- `devils-advocate-loop` round, escalation, and commit behaviour;
- `spec-to-ship` idea/spec/plan entry points;
- missing dependency stops;
- full pipeline ordering;
- `brainstorming` approval gates;
- PlantUML render and visual verification;
- final execution against real dependencies.

Record unavailable runtimes as `NOT RUN`; they do not satisfy compatibility acceptance.

## Review conclusion

Yes, Codex needs an additional focused compatibility review. The review should be added before implementation because it changes checker rules, documentation, the test matrix, and possibly the distribution strategy. It does not justify a Codex-specific skill tree.
