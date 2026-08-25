---
name: plantuml-diagrams
description: Use when creating or refining PlantUML block, architecture, component, deployment, state, or flow diagrams where rendered readability and maintainable text sources both matter.
---

# PlantUML Diagrams

Create diagrams that communicate before they decorate. A `.puml` file parsing is necessary but not sufficient: render it and inspect the picture.

## Choose PlantUML deliberately

Prefer PlantUML when the diagram should be diffable, reproducible, and maintained beside code or specifications. Prefer a manual vector editor when exact placement or brand-level composition dominates. Prefer Mermaid when native Markdown embedding matters more than layout control.

## Build from semantics

Before writing syntax, inventory:

- nodes and their responsibilities;
- directed relationships and edge labels;
- boundaries, trust zones, or lifecycle states;
- facts that must remain visible at the intended display size.

Preserve the source architecture. Do not invent components to make the drawing symmetrical.

## Visual hierarchy

Layout tweak mechanisms nudge Graphviz's automatic placement; they are not for exact positioning. Use them sparingly and prefer a flat, well-ordered diagram over layout hacks.

- Default to `left to right direction` for short pipelines and system boundaries.
- Keep the primary path obvious. Use cycles or secondary arrows only when they convey real behaviour.
- Steer direction per edge with `-up->`, `-down->`, `-left->`, `-right->` (or `-u->`/`-d->`/`-l->`/`-r->`). Use `--[hidden]>` to position an element without implying a real relationship, and `--[norank]>` to de-emphasize a connection for layout purposes only.
- Element definition order also affects placement — reorder the source before reaching for a layout hack.
- Avoid deeply nested containers until a flat version has rendered well; Graphviz ranking can distort nested layouts. Use `together` to cluster related elements for layout purposes without adding a semantic boundary.
- Fix cramped or sprawling spacing with `skinparam nodesep` and `skinparam ranksep` rather than guessing at container structure.
- Use restrained semantic fills. Reuse each colour for one meaning.
- Keep edge labels short. Move explanations into nodes or surrounding prose.
- Use typography inside labels: `<b>` for the scan path, `<i>` for supporting context, and `<color:#hex>` for identifiers or state accents.
- Use `\n` for deliberate line breaks. Do not force every line to the same emphasis.
- Avoid shadows, decorative gradients, and large icon libraries unless the user requests them.

Example label:

```plantuml
rectangle "<color:#2F8F5B><b>2  WAKE + MEASURE</b></color>\n\n<b>Read the environment</b>\n<i>SHT40 and other sensors</i>" as measure #EAF8EF
```

For additional text and layout syntax, consult the [PlantUML Hitchhiker's Guide](https://crashedmind.github.io/PlantUMLHitchhikersGuide/) or current official PlantUML documentation rather than guessing.

## Render and iterate

Produce the editable `.puml` and at least one vector export (`.svg`). Add `.png` when previews or visual inspection tools require it.

Use the installed CLI or JAR and enable Java headless mode when no display server is available:

```bash
java -Djava.awt.headless=true -jar plantuml.jar -checkonly diagram.puml
java -Djava.awt.headless=true -jar plantuml.jar -tsvg diagram.puml
java -Djava.awt.headless=true -jar plantuml.jar -tpng diagram.puml
```

Inspect the rendered output at its intended size. Check reading order, clipped text, weak contrast, crossing connectors, ambiguous arrow direction, excess whitespace, and labels that disappear on transparent backgrounds. For crossing connectors, try `skinparam linetype polyline` or `skinparam linetype ortho` before restructuring the diagram — but with `ortho`, re-check that edge labels still sit on their line; they can drift away from it. Correct the source and render again.

## Completion standard

Report the source and rendered files, renderer/version used, validation performed, remaining automatic-layout compromises, and whether the user still needs to approve the visual result. Never claim success from `-checkonly` alone.
