# src/wake.jl — Wake interaction model for coaxial stacked rotors
#
# Phase 11: Jensen/PARK momentum-deficit propagation.
# Upstream rotors extract momentum from the flow, creating a velocity deficit
# that recovers with downstream distance.  Downstream rotors see reduced
# effective wind speed.

"""
    wake_deficit(CT, radius, downstream_distance; k=0.075) -> Float64

Velocity ratio v/v∞ at `downstream_distance` behind a rotor with thrust
coefficient `CT` and disk `radius`.  Uses the Jensen/PARK wake model.

# Physics

    v/v∞ = 1 − (1−√(1−CT)) × (R/(R + k·x))²

- At the rotor plane (x=0):  v/v∞ = √(1−CT)  — maximum deficit
- Far downstream (x→∞):      v/v∞ → 1.0       — full recovery
- Wider rotor → slower recovery (R in denominator of wake expansion)
- Higher CT → larger initial deficit

The wake expands as a cone with half-angle set by the decay constant `k`.
Default k=0.075 suits open-terrain atmospheric flow.  For closely-spaced
coaxial rotors a higher k (0.10–0.15) may better reflect the confined geometry.

# Arguments
- `CT::Real`: thrust coefficient, T/(0.5·ρ·v²·A).  Clamped to [0, 1].
- `radius::Real`: rotor disk radius (m).
- `downstream_distance::Real`: distance behind the rotor plane (m).
- `k::Real`: wake decay constant (default 0.075).

# Returns
- `Float64`: velocity ratio v/v∞ ∈ [0, 1].

# Examples
```jldoctest
julia> wake_deficit(0.5, 3.0, 0.0) ≈ sqrt(0.5)
true

julia> wake_deficit(0.0, 3.0, 100.0) ≈ 1.0
true
```
"""
function wake_deficit(CT, radius, downstream_distance; k=0.075)
    CT_clamped = clamp(CT, 0.0, 1.0)
    initial_deficit = 1.0 - sqrt(1.0 - CT_clamped)
    wake_radius = radius + k * downstream_distance
    area_ratio = (wake_radius > 0.0) ? (radius / wake_radius)^2 : 1.0
    return 1.0 - initial_deficit * area_ratio
end

export wake_deficit

"""
    stack_effective_wind(rotors, section_lengths, rho, v_wind, elev_deg; k=0.075) -> Vector{Float64}

Per-rotor effective wind speed after accounting for upstream wake momentum
deficits.  Uses one-pass freestream CT for each rotor as a first-order
approximation.  (Iterative refinement — recomputing CT at the deficit-reduced
velocity — is a future task.)

# Algorithm

For each rotor i (top→bottom):
1. Compute BEM thrust at `v_wind` to estimate CT
2. For every upstream rotor j < i, compute the wake deficit ratio at the
   downstream distance Σ section_lengths[j:i−1]
3. Take the minimum ratio (most conservative deficit)
4. v_eff[i] = v_wind × min_ratio

Rotor 1 (topmost) always sees freestream.

# Arguments
- `rotors::Vector{AutogyroRotor}`: rotors ordered top→bottom.
- `section_lengths::Vector{Float64}`: line segment lengths (m), n_rotors entries.
- `rho`: air density (kg/m³).
- `v_wind`: freestream wind speed (m/s).
- `elev_deg`: line elevation angle (degrees).
- `k::Real`: wake decay constant (default 0.075).

# Returns
- `Vector{Float64}`: effective wind speed per rotor (m/s).
"""
function stack_effective_wind(rotors, section_lengths, rho, v_wind, elev_deg; k=0.075)
    n = length(rotors)
    v_eff = fill(v_wind, n)

    # Pre-compute freestream CT for each rotor
    CT = zeros(n)
    for i in 1:n
        _, T, _ = rotor_force_bem(rotors[i], rho, v_wind, elev_deg)
        A = rotor_disk_area(rotors[i])
        q = 0.5 * rho * v_wind^2
        CT[i] = A > 0.0 ? T / (q * A) : 0.0
    end

    # Propagate deficits downward
    for i in 2:n
        min_ratio = 1.0
        for j in 1:(i-1)
            # Distance from rotor j down to rotor i along the line
            dist = sum(section_lengths[j:(i-1)])
            ratio = wake_deficit(CT[j], rotors[j].radius, dist; k=k)
            min_ratio = min(min_ratio, ratio)
        end
        v_eff[i] = v_wind * min_ratio
    end

    return v_eff
end

export stack_effective_wind
