# Resolution: Ticket 06 — ste-lint.py across all docs/

## Finding

All 6 root-level doc files fail the 2.0 violations/100 words threshold.

## Scores

| Rank | File | Score | Main violations |
|------|------|-------|-----------------|
| 6 | CLAUDE.md | 4.67 | em dashes, long sentences |
| 5 | HANDOVER.md | 3.86 | passive voice, long sentences |
| 4 | CONTEXT.md | 3.51 | em dashes, banned words |
| 3 | AGENTS.md | 3.41 | em dashes, long sentences |
| 2 | SPEC.md | 2.25 | em dashes (44), long sentences |
| 1 | PLAN.md | 1.96 | em dashes (37) — just under |

## Top 5 anti-patterns across all files

1. **Em dashes (107 total):** Every file overuses em dashes. The linter
   counts them as a slop marker. Replace with periods or commas.
2. **Long sentences (>20 words):** Technical prose packs too many ideas
   into single sentences. Split them.
3. **Passive voice:** "is computed by" instead of "computes."
4. **Banned words:** "utilize," "ensure," "subsequent" appear in
   CONTEXT.md and SPEC.md.
5. **Phrasal verbs / hedges:** Less common but present in HANDOVER.md.
