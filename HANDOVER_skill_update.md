# HANDOVER — Diagram Skill Update (2026-07-27)

> For Cameron's agent — the `coaxial-diagram-registry` skill has been
> significantly hardened after the first 3-round HITL review of `bem-pareto`.

## What changed in the skill

The skill at `docs/agents/coaxial-diagram-registry-skill.md` now includes:

### New mandatory SPEC.md format
Every diagram SPEC must have 12 sections: Slug, Title, Data Source,
Aggregation, Variables, Audience, Message, Chart type, Visual encoding,
Annotation strategy, Related SPEC sections, Generation. Target ~1000 words.
See `diagrams/bem-pareto/SPEC.md` for the reference example.

### Hardened Round 2 checks (visual clarity)
Added these checks that were missed in the first attempt:
- Leader lines MUST connect labels to data points — no detached side panels
- Labels MUST be in whitespace, never on top of data clusters
- EVERY visual channel needs an on-chart legend (color, shape, AND size)
- Implications caption must be fully visible — check last character renders
- Use `bbox_extra_artists` + `bbox_inches="tight"` for caption, NOT raw
  `pad_inches` (which doesn't expand for fig.text)
- Fixed `subplots_adjust` for tight portrait crop, not loose `bbox_inches`

### New Round 3 spacing checks
- Minimum 20px clear space between text elements and frame edge
- Caption has whitespace above and below
- Title has breathing room from top plot border
- No element touches the figure edge
- Consistent, generous margins

### Pitfalls section
Six documented pitfalls from the bem-pareto review (side panels,
labels on data, missing size legends, bbox_inches expansion,
implications not on chart, skipping HITL gates).

## What your agent should do

1. **Pull the latest** — the updated skill is at
   `docs/agents/coaxial-diagram-registry-skill.md`. Copy it to
   `~/.hermes/skills/coaxial-diagram-registry/SKILL.md` to install.

2. **Follow the workflow exactly:**
   - Round 1: data integrity → present findings → wait for approval
   - Round 2: visual clarity → present findings → wait for approval
   - Round 3: communication + spacing → present → wait for approval
   - Never advance rounds without explicit human approval.

3. **Reference `diagrams/bem-pareto/`** as the template — it has a
   complete, approved SPEC.md (926 words), working Python script,
   IMPLICATIONS.md, and both .png/.pdf outputs.

## First diagram completed

`bem-pareto` — "No Pareto Trade-off: Anchor Tension and Mass Efficiency
Are Co-linear" — approved through all 3 HITL rounds. Key finding:
tension and N/kg are co-linear, a single config dominates, tilt profile
matters <2%. See `DIAGRAM_REGISTRY.md` for status.
