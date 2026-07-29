# Resolution: Ticket 02 — Audit PLAN.md

## Finding

Seven issues. The Phase 8 sweep table is the most damaging — it describes
a PCA-2 sweep that no longer exists. An agent reading PLAN.md would try to
run the wrong parameter sweep.

## Stale data

1. **Phase 8 sweep table wrong.** Lists 6 radii (0.5–3.0m), 6 spacings
   (5–30m), and 5 wind speeds. The current BEM sweep uses 3 radii (1.5,
   2.0, 3.0m), fixed 15m spacing, and 7 wind speeds (4–16 m/s). The table
   must be updated or replaced with a reference to the BEM sweep config.

2. **Wrong filename.** Phase 8 references `sweep_results.tsv`. The current
   sweep output is `bem_full_sweep.tsv`. Change the reference.

3. **Wrong config count.** Phase 8 claims 1,728 configurations. The BEM
   sweep produces 96 distinct (radius, n_rotors, profile, elevation)
   combinations. Update the count.

4. **Stale test count.** Phase 10 says "345 tests green." The current
   test suite has 348 tests (348/348 pass, 2026-07-27). Update the number.

5. **"v1 limitation" language.** Phase 8 repeatedly refers to "PCA-2 disk
   model" and "straight line (v1 limitation)." Both are superseded by the
   BEM v2.1 model. Keep the v1 context for reference but add a note that
   v2.1 is current.

## Verified correct

6. All src/ files (12) and test/ files (12) match the PLAN.md file map.
7. SPEC.md and CONTEXT.md exist at the paths listed.
