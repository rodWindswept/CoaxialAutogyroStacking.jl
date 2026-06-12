# CLAUDE.md

Conventions for this package live in [`AGENTS.md`](AGENTS.md) — read it first.
The implementation roadmap and scope are in [`PLAN.md`](PLAN.md).

Quick reminders:
- Strict TDD: failing test first, then minimal implementation, then refactor.
- Run the suite before committing: `julia --project=. test/runtests.jl`.
- New `src/` file → add `include` + `export` in `src/CoaxialAutogyroStacking.jl`
  and an `include` in `test/runtests.jl`.
- Mirror `KiteTurbineDynamics.jl` conventions; SI units; angles in degrees at
  the API boundary; rotors ordered top → bottom.
- v1 scope: no wake interaction.

## Agent skills

### Issue tracker

Issues are tracked on GitHub. See `docs/agents/issue-tracker.md`.

### Triage labels

Standard triage labels are used. See `docs/agents/triage-labels.md`.

### Domain docs

This repository uses a single-context layout. See `docs/agents/domain.md`.
