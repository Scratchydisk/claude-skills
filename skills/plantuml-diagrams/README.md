# plantuml-diagrams

Guidance for creating and refining PlantUML block, architecture, component, deployment, state, and flow diagrams — where both the rendered picture and the maintainable text source matter.

The skill body Claude reads is [`SKILL.md`](SKILL.md). This file is human-facing context.

## What it covers

- **When to reach for PlantUML** versus a manual vector editor (exact placement, brand-level composition) or Mermaid (native Markdown embedding).
- **Building from semantics first** — inventory nodes, relationships, boundaries, and lifecycle states before writing syntax, and preserve the source architecture instead of inventing components for symmetry.
- **Visual hierarchy rules** — layout direction, restrained semantic fills, short edge labels, and typography inside labels (`<b>`, `<i>`, `<color:#hex>`).
- **Render-and-iterate workflow** — produce the editable `.puml` plus at least one vector export, run the PlantUML CLI/JAR in headless mode, and inspect the rendered output rather than trusting `-checkonly` alone.
- **A completion standard** — report source and rendered files, renderer/version, validation performed, and any remaining automatic-layout compromises.

## When to use it

Use it whenever a diagram should be diffable, reproducible, and maintained beside code or specs — architecture diagrams, component/deployment views, state machines, or pipeline flows.

## Source

Imported from a private project, where it was written for that project's own diagramming needs. The `agents/openai.yaml` file is carried over unchanged; it configures the skill for non-Claude agent runners and isn't read by Claude Code.
