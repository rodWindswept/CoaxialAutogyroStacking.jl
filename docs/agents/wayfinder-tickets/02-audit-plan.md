# Ticket 02: Audit PLAN.md for stale file maps and scope

Type: `wayfinder:task` (AFK)

## Question

Is PLAN.md's file map accurate against the current `src/` and `test/`
directories? Are the phase objectives current or stale? Does the scope
in PLAN.md match what the codebase actually does?

Check every file listed in the PLAN.md file map against the actual
files on disk. Flag any file that exists but is not listed, or any
file listed that no longer exists. Flag any phase marked "planned" or
"in progress" that is actually complete.
