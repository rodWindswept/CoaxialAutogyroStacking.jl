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

### Writing discipline

Follow the clarity rules in `AGENTS.md` for all captions, specs, implications,
and code comments: active voice, short sentences, one name per thing, no hedges.
Lint diagram captions with `python3 ste-lint.py <file>` before Round 2 approval
(score must be < 2.0 violations per 100 words).

### Domain docs

Start here: `docs/agents/domain.md` — quick start, repo map, physics TL;DR, current state.

### Source inventory

`SOURCE_INVENTORY.md` — every file in the repo with a one-line purpose.

### Issue tracker

Issues are tracked on GitHub. See `docs/agents/issue-tracker.md`.

### Triage labels

Standard triage labels are used. See `docs/agents/triage-labels.md`.
