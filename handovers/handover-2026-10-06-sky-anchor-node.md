# Handover — 2026-10-06 Sky Anchor Boundary Node (v1)

**For:** Rod
**Repo:** CoaxialAutogyroStacking.jl
**Branch:** `sky-anchor-boundary` (off `origin/master`)
**Status:** 502 tests green (423 baseline + 79 new).

---

## 1. What Landed

`SkyAnchorBoundary` — the sky anchor node at the top of the stack. R1
terminates the line. The anchor adds a segment above R1, and `profile[1]`
generalises to the anchor-segment tension. The rigid default keeps it
exactly zero, bit-for-bit.

| Type | What it adds |
|------|--------------|
| `RigidSkyAnchor` | Fixed anchor. Profiles unchanged. |
| `SingleBacklineSkyAnchor` | Tension-only backline, point mass, axial and lateral damping, `k_mom` rocking stiffness. |
| `TriangulatedDualBacklineSkyAnchor` | Lateral stiffness on top of the single backline. |

New functions: `anchor_segment_tension`, `anchor_pendulum_frequency`,
`anchor_axial_frequency`, `whirl_frequency`, `whirl_precession_frequency`,
`whirl_stiffness_required`, `blade_passing_frequency`, `rotor_1p_frequency`,
`anchor_mode_report`, `anchor_gate`, `anchor_acceleration`,
`simulate_anchor`, `slack_events`, `energy_ledger`.

`stack_tension_profile` and `stack_tension_profile_polygon` take `boundary`
and `anchor_segment` keywords. The defaults reproduce the old outputs.

## 2. The Physics (pinned in the 2026-10-05/06 design review)

- Node = point mass `m_eff = m_a + m_b/3`. One tension-only backline to a
  fixed point B.
- The backline direction rebuilds from the instantaneous geometry every
  step. A frozen direction gives no geometric spring and the anchor rings
  indefinitely (KTD handover-2026-05-28).
- Lateral damping `c_lat` is the whip-energy bleed term. The axial damper
  cannot damp swing.
- A smooth hinge regularises `max(0, ·)`. The hinge potential is the exact
  integral of the hinge force, so the smoothing cannot pump at slack.
- Lines cannot push. The tension clamp trims the damper on release. The
  bookkeeping charges the trim exactly, so the ledger stays closed.

## 3. Gates

| Gate | Rule | Status |
|------|------|--------|
| `f_p` (swing) | Report only | Passes trivially |
| `f_whirl` | `sep_whirl_bpf >= 0.3` | Hard |
| `f_ax` | `sep_ax_soft_bpf >= 0.3` at soft EA | Hard |
| Slack | Sustained dwell >= 0.8 s fails | Hard |
| Energy | Pointwise gain <= 0 across crossings | Invariant |

Whirl separation is bought with `k_mom`. For a 2-blade flat rotor
`I_s/I_t = 2`, so `k_mom >= 1.56 I_t omega^2` clears the 0.3 rule
(0.44 kN·m/rad at 45 rpm, 3.16 kN·m/rad at 121 rpm, `I_t = 12.6`).
There is no damping fallback branch. Nothing in v1 touches disk tilt.

## 4. Validation Evidence

1. Rigid bit-for-bit: `stack_tension_profile` output `==` with and
   without the boundary. `profile[1] === 0.0`.
2. Swing free decay: 0.1115 Hz measured vs 0.11147 Hz analytic
   (`sqrt(T_b0/(m_eff L))/2pi`), tol 2%.
3. Drop tests: first slack dwell 0.6386 s = `sqrt(2·2/g)`. Bounce arcs
   recur (elastic catch). The 0.15 m drop stays transient, never flagged.
4. Energy ledger: `max_gain` is exactly 0.0 pointwise. The residual is
   RK4 resolution at the catch and release. Measured 0.24 J at dt = 2 ms,
   3.0e-3 J at dt = 0.25 ms, against a 5.9e-3 J default tolerance.
5. Swing ledger residual 9.8e-8 J. Near machine precision.

## 5. Files Changed

| File | Change |
|------|--------|
| `src/sky_anchor.jl` | NEW — node types, gates, dynamics, slack, ledger |
| `test/test_sky_anchor.jl` | NEW — 79 tests, RED first |
| `src/stack.jl` | `boundary` and `anchor_segment` keywords on both profiles |
| `src/CoaxialAutogyroStacking.jl` | include + exports |
| `test/runtests.jl` | include the new test file |
| `CHANGELOG.md`, `SPEC.md` §4.3, `DECISIONS.md` D6 | contract and record |
| `AGENTS.md`, `HANDOVER.md`, `PLAN.md` | file maps and test counts |

## 6. Reproduce

```bash
julia --project=. test/runtests.jl           # 502 tests
julia --project=. -e 'using Test, CoaxialAutogyroStacking; include("test/test_sky_anchor.jl")'
```

## 7. Open Items

- Derive `k_mom` from the backline geometry (profile[1], segment lengths,
  backline lever) instead of taking it as an input number.
- Fold into KTD.jl. Names align with
  `docs/plans/2026-05-12-sky-anchor-node.md`.
- Phase 12 gust/lull sweeps are the natural home for the slack sweep.
