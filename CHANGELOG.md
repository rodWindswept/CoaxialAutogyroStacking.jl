# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `rotor_solidity(rotor)` — solidity σ = n_blades × chord / (π × R), with PCA-2
  comparison (σ_PCA2 ≈ 0.098 vs ours ≈ 0.032 — 3× difference documented).
- `estimated_autorotation_rpm(rotor, v_wind, α_eff; λ=2.5)` — first-order RPM
  estimate for bearing sizing and tip-speed checks (R=3m at 8 m/s → ~45 RPM,
  tip 14.1 m/s, well below 120 m/s noise limit).
- `optimal_pitch` renamed to `optimal_rotor_tilt` — clarifies that disk tilt
  (manufacturing bearing angle) is distinct from blade pitch (swashplate
  control). Docstring explains design-time vs control-time distinction.
- `optimal_pitches` renamed to `optimal_rotor_tilts`.
- `lift_force_steady(stack, rho, v_wind)` integration API (Task 11) — mirrors
  `KiteTurbineDynamics.jl` dispatch pattern.
- Phase 6 quality gates verified: v² scaling (ratio = 4.0), zero-wind
  tension from weight only, more-rotors-more-lift (linear with N), pitch=0
  autogyro matches PCA-2 baseline, monotonic tension profile.
- Documenter.jl documentation site under `docs/` with rich docstrings
  (Arguments/Returns/Examples on every exported symbol).
- Project scaffolding: README, LICENSE (MIT), CONTRIBUTING via `AGENTS.md`,
  `.gitignore`, CI workflow, `CITATION.cff`, `.JuliaFormatter.toml`.
- `DECISIONS.md` — design decisions log (9 entries from 2026-07-02 deep audit).
- `schematics/PRD.md` — mechanical design specification for single autogyro unit
  (16 elements, coordinate system, tilt spec, force visualization requirements).
- `schematics/generate_params.jl` — Julia→OpenSCAD parameter generator.
- `schematics/parameters.scad` — auto-generated shared parameters.
- `schematics/single_unit.scad` — corrected OpenSCAD model: tube as tension
  tie-rod (not compression), rope ties at both ends, dual-molding sandwich
  bearing, hub-driven generator, swashplate for control authority, empennage
  for torque reaction.
- `schematics/stack.scad` — 4-unit stack at 15m spacing, 55° elevation.
- `schematics/renders/` — isometric, front, side, and stack overview PNGs.

### Changed
- **`bare_line_drag` now uses crossflow velocity** — added `line_angle_deg`
  parameter; drag scales with `(v × cos φ)²` instead of `v²`. At 50° elevation
  this reduces line drag by ~59% (was ~2.4× overestimate). All callers updated.
- **`rotor_disk_area` now subtracts hub radius** — π(R² − r_hub²) instead of
  πR². `hub_radius` field no longer dead.
- **`compute_figures_of_merit` mass parameter exposed** — `rotor_mass_per_unit`
  keyword argument replaces hardcoded 5.0 kg.
- **PCA-2 axes convention verified** — wind axes confirmed from Harris (2003)
  source text. Force resolution in `rotor_force_along_line` is correct.
- Legacy TikZ schematics and early OpenSCAD renders moved to `schematics/archive/`.

### Fixed
- `optimal_pitch` was sweeping `tilt_deg` (5th constructor arg) not
  `blade_pitch_deg` — function renamed and docstring corrected.
- `compute_figures_of_merit` hardcoded rotor mass as 5.0 kg — now parametric.
- `rotor_disk_area` ignored `hub_radius` — now subtracts it.

## [0.1.0] - 2026-06-01

Initial development release. Built test-first, mirroring
`KiteTurbineDynamics.jl` conventions.

### Added
- **Phase 1** — PCA-2 empirical rotor-disk data with `pca2_interp(alpha_deg)`
  (linear interpolation, boundary clamping to [0°, 90°]).
- **Phase 2** — `AutogyroRotor` struct, `rotor_disk_area`, `effective_alpha`,
  and `rotor_force_along_line` (single-rotor forces resolved along the line).
- **Phase 3** — `bare_line_drag` (cylinder crossflow) and rotor-vs-line L/D
  comparison.
- **Phase 4** — `AutogyroStack` struct and `stack_tension_profile`
  (free-end → anchor tension accumulation).
- `optimal_rotor_tilt` / `optimal_rotor_tilts` grid-search disk tilt optimisation
- Pluto.jl interactive dashboard (side view, tension profile, HUD, scenarios,
  turbulence).

[Unreleased]: https://github.com/OWNER/CoaxialAutogyroStacking.jl/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/OWNER/CoaxialAutogyroStacking.jl/releases/tag/v0.1.0
