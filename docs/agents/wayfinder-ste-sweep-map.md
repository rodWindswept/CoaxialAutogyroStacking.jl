# Wayfinder Map: STE Codebase Clarity Sweep — COMPLETE

## Destination

A codebase where any agent reading any file cold (zero context) understands
what the code does, why it does it that way, and what invariants hold.

**Status:** Map complete. 6 tickets resolved. The way to the destination
is now clear. Waves 3-4 (src/ sweep) are specifiable.

## Wave 1 — Docs audit ✓ DONE

| # | Ticket | Status |
|---|--------|--------|
| 01 | Audit AGENTS.md vs CLAUDE.md | ✓ |
| 02 | Audit PLAN.md for stale file maps | ✓ |
| 03 | Audit HANDOVER.md for clarity | ✓ |
| 05 | Audit diagram SPECs for drift | ✓ |
| 06 | Lint all docs/ with ste-lint.py | ✓ |

## Wave 2 — Glossary ✓ DONE

| # | Ticket | Status |
|---|--------|--------|
| 04 | Build shared vocabulary glossary | ✓ |

## Decisions so far

- [Audit AGENTS vs CLAUDE](wayfinder-tickets/01-audit-agents-claude-resolution.md) — 7 issues: stale "v1" label, competing orientation docs, missing cross-refs
- [Audit PLAN.md](wayfinder-tickets/02-audit-plan-resolution.md) — 7 issues: stale sweep table, wrong filename, wrong config count, stale test count
- [Audit HANDOVER.md](wayfinder-tickets/03-audit-handover-resolution.md) — 6 issues: 2 critical (stale tension values from pre-bugfix sweep), wrong Re threshold
- [Lint all docs/](wayfinder-tickets/06-lint-docs-resolution.md) — all 6 root docs fail threshold; worst CLAUDE.md (4.67), best PLAN.md (1.96)
- [Audit diagram SPECs](wayfinder-tickets/05-audit-diagram-specs-resolution.md) — 10 of 12 pass; bem-tension-accum (2.80) and pca-clusters (3.64) fail
- [Build glossary](wayfinder-tickets/04-build-glossary-resolution.md) — 6 new terms: Tension, Along-line force, Anchor, Ground station, Rotor ordering, PCA vs PCA-2

## Not yet specified (fog — now specifiable)

- Wave 3: Pilot sweep on `rotor.jl` — prove the STE standard on one module
- Wave 4: Full `src/` sweep across all 10 modules
- Fix the files that fail ste-lint.py (CLAUDE.md 4.67 → <2.0, etc.)
- Add BEM v2.1 terms to CONTEXT.md (stall delay, polygon line, viability gates)
- Build a `ste-lint.jl` Julia version for docstring checking
- Auto-lint pre-commit hook

## Out of scope

- Rewriting code itself for clarity (variable names, function signatures)
- Fixing physics bugs discovered during the sweep
- Marketing or non-technical content
