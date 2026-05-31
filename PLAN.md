# Coaxial-ish Autogyro Stacking — Implementation Plan

> **Goal:** A Julia package modeling multiple independently-pitched autogyro rotors stacked inline on a kite line, computing forces and tension profiles. Built TDD from day one for eventual integration into `KiteTurbineDynamics.jl`.

**Architecture:** Standalone Julia package at `~/Documents/GitHub/CoaxialAutogyroStacking.jl/` mirroring the KiteTurbineDynamics conventions. Uses PCA-2 empirical rotor disk data (already validated in both the Julia and TypeScript codebases). Each rotor has independent pitch relative to the kite line; forces resolve along the line axis. Progressive tension accumulation from top (free end) to bottom (anchor) — matching the corrected stacked-kite tension model in `lift_kite.jl`.

**Key difference from existing code:** The RotaryLifter in KiteTurbineDynamics is a *single* device at fixed omega providing lift. This new package models *multiple* autogyro rotors on one line, each with independent pitch, computing how each one's L/D contribution stacks. The rotor pitch is decoupled from the line elevation angle — this is the coaxial-ish capability.

**Physics reference:** KiteTurbineDynamics.jl/src/lift_kite.jl (PCA-2 data, RotaryLifterParams, stack tension profile)

---

## Phase 1 — Project Skeleton & PCA-2 Data Module

### Task 1: Create package structure

```bash
cd ~/Documents/GitHub
mkdir -p CoaxialAutogyroStacking.jl/src CoaxialAutogyroStacking.jl/test
```

Create `Project.toml` with Julia 1.12.5, no external deps initially.

### Task 2: PCA-2 empirical data module (RED → GREEN)

File: `src/pca2_data.jl`

Export `pca2_interp(alpha_deg)` returning `(cl, cd)` with linear interpolation and boundary clamping [0°, 90°].

Tests (`test/test_pca2_data.jl`):
- Exact data points (0°, 15°, 40°, 90°)
- Interpolation midpoint (12.5°: cl≈0.375, cd≈0.08)
- Boundary clamping (-10° → 0°, 100° → 90°)

PCA-2 data table (from NASA TM 20080022367):
```
α:   0    5   10   15   20   25   30   35   40   45   50   60   70   80   90
CL: 0.00 0.15 0.30 0.45 0.60 0.75 0.85 0.92 0.95 0.90 0.82 0.65 0.45 0.25 0.00
CD: 0.01 0.03 0.06 0.10 0.16 0.24 0.35 0.48 0.62 0.75 0.86 0.96 1.05 1.15 1.25
```

---

## Phase 2 — Single Autogyro Rotor Model

### Task 3: AutogyroRotor struct + disk area

File: `src/rotor.jl`

```julia
struct AutogyroRotor
    radius       :: Float64  # rotor disk radius (m)
    hub_radius   :: Float64  # inner radius (m)
    n_blades     :: Int
    blade_chord  :: Float64  # mean chord (m)
    pitch_deg    :: Float64  # blade collective pitch (degrees)
    mass         :: Float64  # rotor mass (kg)
end
```

`rotor_disk_area(rotor) = π * rotor.radius^2`

### Task 4: Effective disk angle of attack

`α_eff = 90° − line_elevation_deg + pitch_deg`

The rotor axis is coaxial-ish with the line. Pitching forward independently changes the disk's angle of attack to the wind, moving along the PCA-2 CL/CD curve.

### Task 5: Single rotor forces (RED → GREEN)

```julia
function rotor_force_along_line(rotor::AutogyroRotor, rho, v_wind, line_elevation_deg)
    → (F_line, F_lift, F_drag, cl_used, cd_used)
```

Physics:
- `α_eff = 90° - line_elevation_deg + rotor.pitch_deg`
- Look up CL, CD from PCA-2 at α_eff
- `q = 0.5 * rho * v_wind^2`
- `A_disk = π * radius^2`
- `F_lift = q * A_disk * CL` (⊥ wind)
- `F_drag = q * A_disk * CD` (∥ wind)
- `F_line = F_lift * sind(line_elevation) + F_drag * cosd(line_elevation)`

Test cases:
1. Known point: radius=1.5, pitch=10°, line_elev=50°, v=8 m/s → α_eff=50° → CL≈0.82, CD≈0.86 → F_line≈327 N
2. Zero pitch case (pure autogyro)
3. Near-vertical line (elevation 85°)

---

## Phase 3 — Bare Line Section Model

### Task 6: Bare line drag

```julia
function bare_line_drag(rho, v_wind, diameter, length)
    → F_drag  # cylinder crossflow, CD_cylinder = 1.2
```

Test: line=10m, dia=4mm, v=8 m/s → F_drag ≈ 1.88 N

### Task 7: L/D comparison

Verify rotor L/D >> bare line L/D. Bare line has zero lift → L/D ≈ 0. Rotor at optimal pitch should have L/D > 1.

---

## Phase 4 — Multi-Rotor Stack

### Task 8: AutogyroStack struct

```julia
struct AutogyroStack
    rotors           :: Vector{AutogyroRotor}  # top→bottom (1 = topmost)
    section_lengths  :: Vector{Float64}        # n_rotors + 1 entries
    line_diameter    :: Float64
    line_angle_deg   :: Float64                # base line elevation
end
```

### Task 9: Stack tension profile (RED → GREEN)

```julia
function stack_tension_profile(stack::AutogyroStack, rho, v_wind) → Vector{Float64}
```

Returns tension at each position (n_rotors + 1 entries):
- `profile[1]` = above topmost rotor (free end, ≈ 0)
- `profile[end]` = at anchor (maximum tension)

```
T[k] = Σᵢ₌ₖᴺ (F_lineᵢ − Wᵢ·cosθ) + Σⱼ₌ₖᴺ F_drag_sectionⱼ
```

Tests:
1. Monotonic increase downward (profile[i+1] ≥ profile[i])
2. Single rotor: anchor tension ≈ F_line − W·cosθ
3. Three rotors with different pitches give different per-rotor contributions

---

## Phase 5 — System-Level Functions

### Task 10: Optimal pitch per rotor

```julia
function optimal_pitches(stack, rho, v_wind) → Vector{Float64}
```

### Task 11: Integration-compatible API

```julia
function lift_force_steady(stack::AutogyroStack, rho, v_wind) 
    → (F_hub, T_anchor, elevation)
```

Mirrors the dispatch pattern in KiteTurbineDynamics.jl for drop-in integration.

---

## Phase 6 — Quality Gates

- All tests pass: `julia --project=. test/runtests.jl`
- Verify: zero wind → tension from weight only
- Verify: forces scale with v²
- Verify: pitch=0 autogyro matches PCA-2 baseline behavior
- Verify: more rotors = more total lift

---

## Key Decisions

1. **PCA-2 empirical data** — same validated tables as KiteTurbineDynamics/src/lift_kite.jl
2. **No wake interaction** — downstream rotors see freestream; wakes deferred to v2
3. **Independent pitch → effective AoA shift** — computationally cheap, physically grounded
4. **Standalone, integration-ready** — `lift_force_steady` dispatch pattern for later drop-in
5. **TDD throughout** — every function: RED → GREEN → REFACTOR

---

## File Map

```
CoaxialAutogyroStacking.jl/
├── Project.toml
├── PLAN.md                    ← this file
├── src/
│   ├── CoaxialAutogyroStacking.jl   ← module entry
│   ├── pca2_data.jl                 ← PCA-2 empirical data + interpolation
│   ├── rotor.jl                     ← AutogyroRotor struct + forces
│   ├── line_section.jl              ← bare line drag
│   ├── stack.jl                     ← AutogyroStack + tension profile
│   └── optimisation.jl              ← optimal pitch search
└── test/
    ├── runtests.jl
    ├── test_pca2_data.jl
    ├── test_rotor.jl
    ├── test_line_section.jl
    └── test_stack.jl
```
