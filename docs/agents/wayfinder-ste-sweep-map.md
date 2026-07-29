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

## Wave 1 — Docs audit ✓ DONE

| # | Ticket | Type | Status |
|---|--------|------|--------|
| 01 | [Audit AGENTS.md vs CLAUDE.md](wayfinder-tickets/01-audit-agents-claude.md) | task | ✓ |
| 02 | [Audit PLAN.md for stale file maps](wayfinder-tickets/02-audit-plan.md) | task | ✓ |
| 03 | [Audit HANDOVER.md for clarity](wayfinder-tickets/03-audit-handover.md) | task | ✓ |
| 05 | [Audit diagram SPECs for drift](wayfinder-tickets/05-audit-diagram-specs.md) | task | ✓ |
| 06 | [Lint all docs/ with ste-lint.py](wayfinder-tickets/06-lint-docs.md) | task | ✓ |

## Wave 2 — Glossary (HITL, now unblocked)

| # | Ticket | Type | Status |
|---|--------|------|--------|
| 04 | [Build shared vocabulary glossary](wayfinder-tickets/04-build-glossary.md) | grilling | pending |

## Decisions so far

- [Audit AGENTS.md vs CLAUDE.md](wayfinder-tickets/01-audit-agents-claude-resolution.md) — 7 issues: no contradictions, but stale "v1" scope label, two competing orientation docs (PLAN vs domain), missing cross-refs in AGENTS.md
- [Audit PLAN.md](wayfinder-tickets/02-audit-plan-resolution.md) — 7 issues: stale sweep table (lists PCA-2, not BEM), wrong filename, wrong config count, stale test count (345→348)
- [Audit HANDOVER.md](wayfinder-tickets/03-audit-handover-resolution.md) — 6 issues: 2 critical (stale tension values from pre-bugfix sweep), wrong Re threshold, stale test count
- [Lint all docs/](wayfinder-tickets/06-lint-docs-resolution.md) — all 6 root doc files fail threshold; worst is CLAUDE.md (4.67), best is PLAN.md (1.96). Top violations: em dashes (107), long sentences, passive voice
- [Audit diagram SPECs](wayfinder-tickets/05-audit-diagram-specs-resolution.md) — 10 of 12 pass; bem-tension-accum (2.80) and pca-clusters (3.64) fail

## Not yet specified

- Wave 3: Pilot sweep on `rotor.jl` (prove the standard)
- Wave 4: Full `src/` sweep across all 10 modules
- Build a `ste-lint.jl` Julia version for docstring checking
- Auto-lint pre-commit hook

## Out of scope

- Rewriting code itself for clarity (variable names, function signatures)
- Fixing physics bugs discovered during the sweep
- Marketing or non-technical content
