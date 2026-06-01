# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `lift_force_steady(stack, rho, v_wind)` integration API (Task 11) — mirrors
  `KiteTurbineDynamics.jl` dispatch pattern.
- Phase 6 quality gates verified: v² scaling (ratio = 4.0), zero-wind
  tension from weight only, more-rotors-more-lift (linear with N), pitch=0
  autogyro matches PCA-2 baseline, monotonic tension profile.
- Documenter.jl documentation site under `docs/` with rich docstrings
  (Arguments/Returns/Examples on every exported symbol).
- Project scaffolding: README, LICENSE (MIT), CONTRIBUTING via `AGENTS.md`,
  `.gitignore`, CI workflow, `CITATION.cff`, `.JuliaFormatter.toml`.

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
- **Phase 5** — `optimal_pitch` and `optimal_pitches` grid-search.
- Pluto.jl interactive dashboard (side view, tension profile, HUD, scenarios,
  turbulence).

[Unreleased]: https://github.com/OWNER/CoaxialAutogyroStacking.jl/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/OWNER/CoaxialAutogyroStacking.jl/releases/tag/v0.1.0
