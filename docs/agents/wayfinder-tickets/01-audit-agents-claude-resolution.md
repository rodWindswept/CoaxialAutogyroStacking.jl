# Resolution: Ticket 01 — Audit AGENTS.md vs CLAUDE.md

## Finding

Seven issues found. None are critical — no contradictions that would cause
an agent to take the wrong action. The main problems are stale scope
language and missing cross-references.

## Contradictions

1. **Scope language mismatch.** CLAUDE.md says "v1 scope: no wake interaction."
   AGENTS.md says nothing about scope limits. An agent reading only AGENTS.md
   would not know wake interaction is excluded. Fix: add scope statement to
   AGENTS.md, and update "v1" to match current version.

2. **Two orientation docs.** AGENTS.md says PLAN.md is "source of truth for
   scope, task order, and key decisions." CLAUDE.md says domain.md is "quick
   start, repo map, physics TL;DR." These overlap. An agent reading both gets
   two competing entry points. Decision needed: keep one as primary.

## Missing cross-references

3. AGENTS.md does not reference domain.md, SOURCE_INVENTORY.md, or the
   issue tracker — all of which CLAUDE.md considers essential agent context.
   These should be listed in AGENTS.md since it describes itself as
   "Guidance for any developer or AI agent."

## Stale / redundant

4. "v1 scope" label is stale. The codebase uses BEM v2.0. The scope limit
   (no wake interaction) is still true, but the version tag misleads.
   Change to "Scope limit: no wake interaction (BEM v2.0 single-rotor model)."

5. CLAUDE.md Quick Reminders restate conventions from AGENTS.md. Any change
   to TDD rules, SI conventions, or rotor ordering requires editing both files.
   Reduce CLAUDE.md to pointers, not restatements.

6. stall_delay.jl in AGENTS.md file map but not referenced anywhere else.
   OK — it's a source file, not a doc.

7. All referenced files exist — no broken links to fix.
