# Ticket 06: Lint all docs/ files with ste-lint.py

Type: `wayfinder:task` (AFK)

## Question

Run `python3 ste-lint.py` on every markdown file in `docs/` and
every agent config file in the repo root. Report the per-file score.
Flag any file above 2.0 violations per 100 words.

List the top 5 violations observed across all files (the most common
anti-patterns in the current documentation). This will inform the
rewrite priority for subsequent tickets.
