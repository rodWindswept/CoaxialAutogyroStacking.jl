# Resolution: Ticket 03 — Audit HANDOVER.md

## Finding

Six issues. Two are critical — stale performance numbers from the pre-bugfix
sweep would mislead any agent. Four are low-impact but contribute to drift.

## Critical

1. **Wrong tension.** "649 N at 8 m/s for top_draggy" is from the sweep
   before the polygon force-projection bug was fixed (commit 473a316).
   The correct value for the best config post-fix is graded at 839 N
   (mean across elevations and wind speeds). Update all tension numbers.

2. **Wrong profile winner.** "top_draggy wins by +12.7% over uniform"
   was from the buggy sweep. After the polygon fix, graded wins and the
   margin is much smaller (~3.5% across all profiles at R=3.0m, N=4).

## High

3. **Wrong Re threshold.** Section 2B says "Re > 5×10^5" for PCA-2
   data validity. The BEM sweep uses Re > 5×10^4 (transitional flow
   threshold for NACA 0012). Change to match the viability gate.

## Low

4. **Stale test count.** Section 1 says "345 tests." Current count is
   348. Section 4 repeats the stale count.
5. **Undefined phase references.** "Phases 10e and 10f" are not defined
   in PLAN.md or anywhere else.
6. **File map stale.** Section 4 repeats "345 green tests."
