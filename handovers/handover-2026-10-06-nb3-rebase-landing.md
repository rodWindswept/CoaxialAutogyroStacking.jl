# Handover — n_b = 3 sky-anchor re-base (W8 landing)

**Date:** 2026-10-06
**Repo:** `CoaxialAutogyroStacking.jl`
**Branch:** `sky-anchor-boundary`, one commit on top of a75bd1d (Phase 13)
**Scope:** W8 of KTD `docs/plans/2026-09-29-work-division.md` section 7 — the
n_b = 3 re-base edit set plus the machine-default scope catch.

## What changed

1. **Whirl gates re-based to n_b = 3** (`test/test_sky_anchor.jl`, numbers in
   DECISIONS D7):
   - Pins: `2,073.3` N·m/rad at 45 rpm, `14,990.5` at 121 rpm (were 436.49 /
     3,155.9 under the 2-blade budget).
   - The "free pivot = BPF" identity becomes the separation check: `sep =
     1/3` at n_b = 3. The precession pin at the threshold moves 0.6 omega to
     1.9 omega.
   - Report fixture: `k_mom` 600 -> 3,000, `bpf` 1.5 -> 2.25, required k_mom
     436.49 -> 2,073.3.
   - Gate verdicts rebuilt: the free pivot now PASSES (sep = 1/3); the old
     600 and 3,500 pins document the fail band; the 121 rpm pass case moves
     to the stiff rail (`k_mom = 20,000` with the 400 kN rope); the 1 MN rope
     at 121 rpm shows the axial flip (whirl fails mid-band, axial passes).
2. **Machine-default scope catch:** `n_blades = 2` -> `3` in `sweep.jl`
   (both sweeps and the options table), `scripts/gen_comparison_sweep.jl`,
   `notebooks/bem_charts_v2.jl`,
   `diagrams/bem-radial-loading/compute_radial_loading.jl`, the `src/rotor.jl`
   docstring and `schematics/DIMENSIONS.md` (solidity 0.0318 -> 0.0477 in
   both the header and the table).

## Evidence (the bar)

- Suite: `julia --project=. test/runtests.jl` — 504/504 pass, 10.0 s
  (502 -> 504: the gate testset grew by two assertions).
- Focused pins: `test/test_sky_anchor.jl` alone — 81/81 pass, 1.9 s.
- Probe: `coax_nb3_landing_probe.jl` — 20/20 assertions, plus a BEM sweep
  viability check at n_b = 3 (tip speeds stay below 120 m/s).
- Suite, pins and probe all re-run clean on the committed tree.

## Notes for the reader

- `scripts/gen_comparison_sweep.jl` carried a pre-existing STE score of 2.78
  per 100 words, above the pre-commit gate's 2.0. The cause was an
  8-sentence comment corpus: the shebang line counts as one sentence in the
  STE extractor. Two decorative separator comments were removed. The file
  now scores 0.00.
- Six flips plus the `:86` edit, per the W8 spec. `DIMENSIONS.md` also
  carries the solidity value in its header line, so that line moved too.

## Out of scope, flagged

- `sky_anchor.jl` function defaults stay at `n_blades = 2`. The
  machine-level call sites pass `n_blades = 3` explicitly. Fix the defaults
  only if a ruling asks.
- `schematics/generate_params.jl:19` (`n_bl = 2`) and the "2-blade rotor"
  text in `parameters.scad` are sibling readings not named in the W8 set.
- `I_t` re-derive for the 3-blade BOM is open. It moves every `k_mom` pin
  again.
- `HANDOVER.md` section 2's performance table is a 473a316-era record (under
  the old n_b = 2 default). A fresh sweep under the n_b = 3 default was not
  run. That is outside the W8 set.
- `bem_charts_v2.jl:409` and `:515` keep explicit `2` scaffolds. They feed
  n_blades-independent quantities (solver rotor lists, effective alpha).
