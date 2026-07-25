# src/stall_delay.jl — 3-D stall-delay corrections for BEM
#
# Phase 10f (v2.1): Snel/Himmelskamp correction — centrifugal pumping delays
# separation on rotating blades, increasing CL in the post-stall regime.
# Strongest near the root (high c/r) where 3-D boundary-layer effects dominate.
#
# Reference: Snel et al. (1993), as implemented in QBlade.

"""
    _snel_blending_g(alpha_deg::Real) -> Float64

Blending function g(α) for the Snel stall-delay correction.

- g = 1.0   for 0 < α < 30° (full correction in post-stall regime)
- g smoothly transitions from 1 to 0 for 30° ≤ α ≤ 60°
- g = 0.0   for α ≥ 60° (deep stall — 2-D behaviour dominates)

The transition uses: g = 0.5 * (1 + cos(6·α − 180°))
which is continuous at both boundaries (g(30°)=1, g(60°)=0).
"""
function _snel_blending_g(alpha_deg::Real)
    α = abs(alpha_deg)
    if α <= 30.0
        return 1.0
    elseif α >= 60.0
        return 0.0
    else
        return 0.5 * (1.0 + cosd(6.0 * α - 180.0))
    end
end

"""
    snel_cl_3d(cl_2d::Real, alpha_deg::Real, local_tsr::Real, c_over_r::Real) -> Float64

Apply the Snel stall-delay correction to a 2-D lift coefficient.

# Physics

On a rotating blade, centrifugal pumping drives radial flow in the boundary
layer, thinning it and delaying separation. This "Himmelskamp effect" is
captured by the semi-empirical Snel correction:

    CL_3D = CL_2D + (3.1·λ²/(1+λ²)) · g(α) · (c/r)² · (CL_pot − CL_2D)

where:
- `λ = local_tsr` = ω·r / v_axial (local tip-speed ratio at this station)
- `g(α)` is the blending function (see [`_snel_blending_g`](@ref))
- `c/r = c_over_r` is the local chord-to-radius ratio
- `CL_pot = 2π·α` is the potential-flow lift (as if no separation occurred)

The correction is strongest near the root (high c/r) and vanishes at α ≥ 60°.

# Arguments
- `cl_2d`: uncorrected 2-D lift coefficient.
- `alpha_deg`: local angle of attack (degrees).
- `local_tsr`: local tip-speed ratio ω·r / v_axial.
- `c_over_r`: local chord-to-radius ratio.

# Returns
- `cl_3d`: rotationally-corrected lift coefficient.

# Examples
```jldoctest
julia> snel_cl_3d(0.5, 10.0, 3.0, 0.1) isa Float64
true
```
"""
function snel_cl_3d(cl_2d::Real, alpha_deg::Real, local_tsr::Real, c_over_r::Real)
    # Potential-flow lift: CL = 2π·α (thin airfoil theory, symmetric)
    alpha_rad = deg2rad(alpha_deg)
    cl_pot = 2π * alpha_rad

    # Correction multiplier: stronger at high TSR, stronger near root
    lambda = local_tsr
    tsr_factor = 3.1 * lambda^2 / (1.0 + lambda^2)

    g = _snel_blending_g(alpha_deg)
    cr_squared = c_over_r^2

    delta_cl = tsr_factor * g * cr_squared * (cl_pot - cl_2d)

    # Correction is only applied when CL_2D < CL_pot (stall/post-stall).
    # In the linear range, the airfoil may outperform potential flow;
    # we never reduce lift.
    if delta_cl < 0.0
        return Float64(cl_2d)
    end

    return cl_2d + delta_cl
end

export snel_cl_3d
