# Handover — Standards and Methods (2026-08-20)

**From:** Rod + the Windswept & Interesting bot team (Hermes leads)
**To:** Cameron

## What changed

1. **The STE linter now fires live.** `ste-lint.py` emits fix-guidance for
   each violation as a `[HOOK:ste]` line. A pre-commit hook blocks any commit
   that breaches 2.0 violations per 100 words. The same linter and hook now
   run in KiteTurbineDynamics.jl and here.

2. **Require provenance.** Campaign result CSVs must carry a provenance
   header: git hash + physics era + geometry fingerprint. A `[HOOK:provenance]`
   sensor blocks commits that add a CSV without it.

3. **Habit hooks encode the standards.** Three playbooks now hold the rules:
   `physics-convention`, `provenance`, `hardcoded-numbers`. Each fires on a
   trigger and tells you the fix.

4. **Version the standards.** Each standard carries version, author, and
   date. Treat a standard like code. Bump the version when you change it.

## What this means for you

- Your commits now pass the STE and provenance checks. Bypass with
  `git commit --no-verify` only when you mean it.
- The bot team (software, aero, science workers and their validators) works in
  KTD. Coordination stays the same: committed repo files and handover notes.
- Your aero work still flows through this repo. Nothing about the autogyro
  physics or the TDD loop changed.

## Questions

Reply here or in a handover note.
