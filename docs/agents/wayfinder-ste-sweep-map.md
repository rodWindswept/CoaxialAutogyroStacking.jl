# Wayfinder Map: STE Codebase Clarity Sweep

## Destination

A codebase where any agent reading any file cold (zero context) understands
what the code does, why it does it that way, and what invariants hold. No
ambiguity. No contradictory docs. No stale docstrings. Every comment and
docstring passes `ste-lint.py` at < 2.0 violations per 100 words.

## Notes

- Load `ste-writing` skill for all work on this map.
- Load `domain-modeling` skill when extracting a glossary (ticket 04).
- STE-flavored mode for prose files (AGENTS, PLAN, HANDOVER, SPECs).
- Strict mode for error messages and procedure docs.
- Run `python3 ste-lint.py <file>` after every change.
- Apply the Finding/Config/Values/Check/Source format to all results.

## Wave 1 — Docs audit (parallel AFK)

| # | Ticket | Type | Blocks |
|---|--------|------|--------|
| 01 | [Audit AGENTS.md vs CLAUDE.md](wayfinder-tickets/01-audit-agents-claude.md) | task | — |
| 02 | [Audit PLAN.md for stale file maps](wayfinder-tickets/02-audit-plan.md) | task | — |
| 03 | [Audit HANDOVER.md for clarity](wayfinder-tickets/03-audit-handover.md) | task | — |
| 05 | [Audit diagram SPECs for drift](wayfinder-tickets/05-audit-diagram-specs.md) | task | — |
| 06 | [Lint all docs/ with ste-lint.py](wayfinder-tickets/06-lint-docs.md) | task | — |

## Wave 2 — Glossary (HITL, blocked by 01-03)

| # | Ticket | Type | Blocks |
|---|--------|------|--------|
| 04 | [Build shared vocabulary glossary](wayfinder-tickets/04-build-glossary.md) | grilling | blocked by: 01, 02, 03 |

## Decisions so far

<!-- populated as tickets close -->

## Not yet specified

- Wave 3: Pilot sweep on `rotor.jl` (prove the standard)
- Wave 4: Full `src/` sweep across all 10 modules
- Build a `ste-lint.jl` Julia version for docstring checking
- Auto-lint pre-commit hook

## Out of scope

- Rewriting code itself for clarity (variable names, function signatures)
- Fixing physics bugs discovered during the sweep
- Marketing or non-technical content
