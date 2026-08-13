# src/wake.jl — Wake interaction model for coaxial stacked rotors
#
# Phase 11: Jensen/PARK momentum-deficit propagation.
# Upstream rotors extract momentum from the flow, creating a velocity deficit
# that recovers with downstream distance.  Downstream rotors see reduced
# effective wind speed.

"""
    wake_deficit(CT, radius, downstream_distance; model=:jensen, k=0.075, I=0.05, E1=0.1, E2=0.6) -> Float64

Velocity ratio v/v∞ at `downstream_distance` behind a rotor with thrust
coefficient `CT` and disk `radius`.

Two models are available:
- `model=:jensen` (default): Jensen/PARK wake model with decay constant `k`.
- `model=:bastankhah`: Bastankhah 2026 generalised actuator disk theory
  with turbulent entrainment.  Uses ambient turbulence intensity `I`.

# Arguments
- `CT::Real`: thrust coefficient, T/(0.5·ρ·v²·A).  Clamped to [0, 1].
- `radius::Real`: rotor disk radius (m).
- `downstream_distance::Real`: distance behind the rotor plane (m).
- `model::Symbol`: `:jensen` (default) or `:bastankhah`.
- `k::Real`: Jensen wake decay constant (default 0.075, only for `:jensen`).
- `I::Real`: ambient turbulence intensity (default 0.05, only for `:bastankhah`).
- `E1::Real`: wake-shear entrainment coefficient (default 0.1, only for `:bastankhah`).
- `E2::Real`: background-turbulence entrainment coefficient (default 0.6, only for `:bastankhah`).

# Returns
- `Float64`: velocity ratio v/v∞ ∈ [0, 1].
"""
function wake_deficit(CT, radius, downstream_distance;
    model::Symbol=:jensen, k=0.075, I=0.05, E1=0.1, E2=0.6)
    if model == :bastankhah
        CT_c = clamp(CT, 0.0, 1.0)
        a = bastankhah_a_from_ct(CT_c; I=I, E1=E1, E2=E2)
        D = 2.0 * radius
        x_over_D = downstream_distance / D
        if x_over_D <= 0.0
            return 1.0 - a
        end
        return wake_deficit_bastankhah_downstream(a, CT_c, x_over_D; I=I, E1=E1, E2=E2)
    end
    # Default: Jensen/PARK
    CT_clamped = clamp(CT, 0.0, 1.0)
    initial_deficit = 1.0 - sqrt(1.0 - CT_clamped)
    wake_radius = radius + k * downstream_distance
    area_ratio = (wake_radius > 0.0) ? (radius / wake_radius)^2 : 1.0
    return 1.0 - initial_deficit * area_ratio
end

export wake_deficit

"""
    stack_effective_wind(rotors, section_lengths, rho, v_wind, elev_deg; model=:jensen, k=0.075, I=0.05, E1=0.1, E2=0.6) -> Vector{Float64}

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
- `model::Symbol`: `:jensen` (default) or `:bastankhah`.
- `k::Real`: Jensen wake decay constant (default 0.075).
- `I::Real`: ambient turbulence intensity for Bastankhah model (default 0.05).

# Returns
- `Vector{Float64}`: effective wind speed per rotor (m/s).
"""
function stack_effective_wind(rotors, section_lengths, rho, v_wind, elev_deg; model::Symbol=:jensen, k=0.075, I=0.05, E1=0.1, E2=0.6)
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
            ratio = wake_deficit(CT[j], rotors[j].radius, dist; model=model, k=k, I=I, E1=E1, E2=E2)
            min_ratio = min(min_ratio, ratio)
        end
        v_eff[i] = v_wind * min_ratio
    end

    return v_eff
end

export stack_effective_wind

# ═══════════════════════════════════════════════════════════════════════
# Phase 12: Bastankhah 2026 Generalised Actuator Disk Theory
# Bastankhah, Hydon, Shapiro, Gayme & Meneveau (2026) J. Fluid Mech.
# Refs: Eqs. 2.18a,b (upstream), 2.17a,b (downstream ODE), 2.23 (CT-a)
# ═══════════════════════════════════════════════════════════════════════

"""
    wake_deficit_bastankhah_upstream(a, x_over_D) -> Float64

Upstream velocity ratio U/U0 at dimensionless position `x_over_D` (= x/D)
for induction factor `a`.  Analytical solution from Eq. 2.18a.

At x/D = 0 (rotor plane): U/U0 = 1 - a.
At x/D -> -infinity (far upstream): U/U0 -> 1.

# Arguments
- `a::Real`: induction factor at the actuator disk.
- `x_over_D::Real`: dimensionless streamwise position (negative = upstream).
"""
function wake_deficit_bastankhah_upstream(a, x_over_D)
    R_hat = 0.5  # dimensionless disk radius (= R/D)
    term = a^2 - 2.0 * a
    denom = sqrt(x_over_D^2 + R_hat^2)
    return sqrt(term * (x_over_D / denom + 1.0) + 1.0)
end

export wake_deficit_bastankhah_upstream

"""
    entrainment_velocity_bastankhah(U, x_over_D; E1, E2, I) -> Float64

Dimensionless entrainment velocity Ue/U0 from Eqs. 2.5–2.7.

- `U`: dimensionless velocity U/U0 at current position.
- `x_over_D`: dimensionless downstream position x/D.
- `E1`: wake-shear entrainment coefficient (default 0.1).
- `E2`: background-turbulence entrainment coefficient (default 0.6).
- `I`: ambient turbulence intensity (default 0.05).

The entrainment has two components combined as a generalised mean (n=4):
- Wake-shear driven: E1 * (1 - U)                        [Eq. 2.5]
- Background-turbulence driven: E2 * I * x/√(x²+R²)      [Eq. 2.6]
The spatial factor x/√(x²+R²) suppresses background entrainment near
the disk and ramps it up as wake pressure recovers.
"""
function entrainment_velocity_bastankhah(U, x_over_D; E1=0.1, E2=0.6, I=0.05)
    R_hat = 0.5
    W_hat = E1 * (1.0 - U)                              # Eq. 2.5
    shield = x_over_D / sqrt(x_over_D^2 + R_hat^2)      # Eq. 2.6 spatial factor
    A_hat = E2 * I * shield                              # Eq. 2.6
    return (W_hat^4 + A_hat^4)^0.25                      # Eq. 2.7, n=4
end

"""
    wake_deficit_bastankhah_downstream(a, CT, x_over_D; kwargs...) -> Float64

Downstream velocity ratio U/U0 at dimensionless position `x_over_D` (= x/D)
for induction factor `a` and thrust coefficient `CT`.  Integrates Eqs.
2.17a,b from x=0 using RK4 with ``n=1000`` steps per diameter.

# Arguments
- `a::Real`: induction factor.
- `CT::Real`: thrust coefficient.
- `x_over_D::Real`: downstream position (must be >= 0).
- `E1`, `E2`, `I`: entrainment parameters (see `entrainment_velocity_bastankhah`).
- `n_steps::Int`: integration steps per unit x/D (default 1000).
"""
function wake_deficit_bastankhah_downstream(a, CT, x_over_D;
    E1=0.1, E2=0.6, I=0.05, n_steps::Int=10000)
    x_over_D <= 0.0 && return 1.0 - a  # at or before disk
    R_hat = 0.5

    # Initial conditions at x=0: sigma/D=1, U/U0=1-a
    sigma = 1.0
    U = 1.0 - a

    dx = x_over_D / n_steps

    # Track position, integrate from x=0 to x_over_D
    x_curr = 0.0
    for step in 1:n_steps
        # Midpoint of this step
        x_mid = x_curr + dx / 2.0

        # RK4 on (sigma, U)
        # -- k1 at x_curr
        Ue1 = entrainment_velocity_bastankhah(U, x_curr; E1=E1, E2=E2, I=I)
        pressure_term = (R_hat^2) / (x_curr^2 + R_hat^2)^1.5 * ((2.0*a - a^2) - CT)
        dUdx1 = (1.0 / (2.0 * U)) * (pressure_term + (8.0 / sigma) * Ue1 * (1.0 - U))
        dsigdx1 = (1.0 / (2.0 * U)) * (4.0 * Ue1 - sigma * dUdx1)

        # -- k2 at midpoint from k1
        sigma2 = sigma + 0.5 * dx * dsigdx1
        U2 = U + 0.5 * dx * dUdx1
        Ue2 = entrainment_velocity_bastankhah(U2, x_mid; E1=E1, E2=E2, I=I)
        pressure_term2 = (R_hat^2) / (x_mid^2 + R_hat^2)^1.5 * ((2.0*a - a^2) - CT)
        dUdx2 = (1.0 / (2.0 * U2)) * (pressure_term2 + (8.0 / sigma2) * Ue2 * (1.0 - U2))
        dsigdx2 = (1.0 / (2.0 * U2)) * (4.0 * Ue2 - sigma2 * dUdx2)

        # -- k3 at midpoint from k2
        sigma3 = sigma + 0.5 * dx * dsigdx2
        U3 = U + 0.5 * dx * dUdx2
        Ue3 = entrainment_velocity_bastankhah(U3, x_mid; E1=E1, E2=E2, I=I)
        pressure_term3 = (R_hat^2) / (x_mid^2 + R_hat^2)^1.5 * ((2.0*a - a^2) - CT)
        dUdx3 = (1.0 / (2.0 * U3)) * (pressure_term3 + (8.0 / sigma3) * Ue3 * (1.0 - U3))
        dsigdx3 = (1.0 / (2.0 * U3)) * (4.0 * Ue3 - sigma3 * dUdx3)

        # -- k4 at endpoint
        x_next = x_curr + dx
        sigma4 = sigma + dx * dsigdx3
        U4 = U + dx * dUdx3
        Ue4 = entrainment_velocity_bastankhah(U4, x_next; E1=E1, E2=E2, I=I)
        pressure_term4 = (R_hat^2) / (x_next^2 + R_hat^2)^1.5 * ((2.0*a - a^2) - CT)
        dUdx4 = (1.0 / (2.0 * U4)) * (pressure_term4 + (8.0 / sigma4) * Ue4 * (1.0 - U4))
        dsigdx4 = (1.0 / (2.0 * U4)) * (4.0 * Ue4 - sigma4 * dUdx4)

        # -- RK4 weighted sum
        sigma += (dx / 6.0) * (dsigdx1 + 2.0*dsigdx2 + 2.0*dsigdx3 + dsigdx4)
        U     += (dx / 6.0) * (dUdx1  + 2.0*dUdx2  + 2.0*dUdx3  + dUdx4)
        x_curr = x_next
    end

    return U
end

export wake_deficit_bastankhah_downstream
export entrainment_velocity_bastankhah

"""
    bastankhah_downstream_solution(a, CT; n_pts=20000, L=30.0, kwargs...) -> (x, sigma, U)

Full downstream solution arrays from x=0 to x=L for given induction factor
`a` and thrust coefficient `CT`.  Returns dimensionless position `x/D`,
wake width `sigma/D`, and velocity `U/U0`.

Used internally by `bastankhah_ct_from_a` to compute the Y integral (Eq. 2.24).
"""
function bastankhah_downstream_solution(a, CT; n_pts::Int=20000, L=30.0,
    E1=0.1, E2=0.6, I=0.05)
    R_hat = 0.5
    dx = L / n_pts

    xs = zeros(n_pts + 1)
    sigmas = zeros(n_pts + 1)
    Us = zeros(n_pts + 1)

    xs[1] = 0.0
    sigmas[1] = 1.0
    Us[1] = 1.0 - a

    x_curr = 0.0
    sigma = 1.0
    U = 1.0 - a

    for i in 1:n_pts
        x_mid = x_curr + dx / 2.0
        x_next = x_curr + dx

        # RK4 on (sigma, U)
        Ue1 = entrainment_velocity_bastankhah(U, x_curr; E1=E1, E2=E2, I=I)
        pt1 = (R_hat^2) / (x_curr^2 + R_hat^2)^1.5 * ((2.0*a - a^2) - CT)
        dU1 = (1.0/(2.0*U)) * (pt1 + (8.0/sigma)*Ue1*(1.0-U))
        ds1 = (1.0/(2.0*U)) * (4.0*Ue1 - sigma*dU1)

        s2 = sigma + 0.5*dx*ds1; U2 = U + 0.5*dx*dU1
        Ue2 = entrainment_velocity_bastankhah(U2, x_mid; E1=E1, E2=E2, I=I)
        pt2 = (R_hat^2) / (x_mid^2 + R_hat^2)^1.5 * ((2.0*a - a^2) - CT)
        dU2 = (1.0/(2.0*U2)) * (pt2 + (8.0/s2)*Ue2*(1.0-U2))
        ds2 = (1.0/(2.0*U2)) * (4.0*Ue2 - s2*dU2)

        s3 = sigma + 0.5*dx*ds2; U3 = U + 0.5*dx*dU2
        Ue3 = entrainment_velocity_bastankhah(U3, x_mid; E1=E1, E2=E2, I=I)
        pt3 = (R_hat^2) / (x_mid^2 + R_hat^2)^1.5 * ((2.0*a - a^2) - CT)
        dU3 = (1.0/(2.0*U3)) * (pt3 + (8.0/s3)*Ue3*(1.0-U3))
        ds3 = (1.0/(2.0*U3)) * (4.0*Ue3 - s3*dU3)

        s4 = sigma + dx*ds3; U4 = U + dx*dU3
        Ue4 = entrainment_velocity_bastankhah(U4, x_next; E1=E1, E2=E2, I=I)
        pt4 = (R_hat^2) / (x_next^2 + R_hat^2)^1.5 * ((2.0*a - a^2) - CT)
        dU4 = (1.0/(2.0*U4)) * (pt4 + (8.0/s4)*Ue4*(1.0-U4))
        ds4 = (1.0/(2.0*U4)) * (4.0*Ue4 - s4*dU4)

        sigma += (dx/6.0) * (ds1 + 2.0*ds2 + 2.0*ds3 + ds4)
        U     += (dx/6.0) * (dU1 + 2.0*dU2 + 2.0*dU3 + dU4)
        x_curr = x_next

        xs[i+1] = x_curr
        sigmas[i+1] = sigma
        Us[i+1] = U
    end

    return xs, sigmas, Us
end

"""
    bastankhah_ct_from_a(a; kwargs...) -> Float64

Iteratively compute the thrust coefficient CT for induction factor `a`
using the Bastankhah 2026 CT-a relationship (Eqs. 2.23–2.24).

Starts from the Steiros & Hultmark (2018) initial guess and iterates
until |CT_new − CT_old| ≤ tol.

# Arguments
- `a::Real`: induction factor.
- `I::Real`: ambient turbulence intensity (default 0.05).
- `tol::Real`: convergence tolerance (default 5e-3).
- `relax::Real`: relaxation factor (default 0.05).
- `max_iter::Int`: maximum iterations (default 500).
- `L::Real`: downstream domain length in diameters (default 30).
"""
function bastankhah_ct_from_a(a; I=0.05, E1=0.1, E2=0.6,
    tol=5e-3, relax=0.05, max_iter=500, L=30.0)
    # Initial guess: Steiros & Hultmark 2018
    ct = 4.0 * a * (3.0 - a) / (3.0 * (1.0 + a))

    for iter in 1:max_iter
        x, sigma, U = bastankhah_downstream_solution(a, ct; L=L, I=I, E1=E1, E2=E2)

        # Eq. 2.24: Y = (1/D^2) ∫ (1 - x/√(x²+R²)) · d(σ²)/dx · dx
        # Trapezoidal integration
        Y = 0.0
        dx = x[2] - x[1]
        for i in 1:(length(x)-1)
            weight = 1.0 - x[i] / sqrt(x[i]^2 + 0.25)
            dsig2 = (sigma[i+1]^2 - sigma[i]^2) / dx
            # Skip the first step where d/dx is poorly defined? No, include all.
            Y += weight * dsig2 * dx
        end

        # Eq. 2.23
        ct_new = 2.0 * a + (1.0 / Y - 1.0) * a^2

        if abs(ct - ct_new) <= tol
            return ct_new
        end

        # Relaxed update
        ct = relax * ct_new + (1.0 - relax) * ct
    end

    return ct  # Return whatever we got after max_iter
end

export bastankhah_ct_from_a
export bastankhah_downstream_solution

"""
    bastankhah_a_from_ct(CT; kwargs...) -> Float64

Iteratively compute the induction factor `a` for a given thrust coefficient
`CT` using the Bastankhah 2026 CT-a relationship (inverse of Eq. 2.23).

# Arguments
- `CT::Real`: thrust coefficient.
- `I`, `E1`, `E2`, `tol`, `relax`, `max_iter`, `L`: see `bastankhah_ct_from_a`.
"""
function bastankhah_a_from_ct(CT; I=0.05, E1=0.1, E2=0.6,
    tol=5e-3, relax=0.5, max_iter=100, L=30.0)
    CT <= 0.0 && return 0.0
    # Initial guess from classical Froude: CT = 4a(1-a)
    a = 0.5 * (1.0 - sqrt(max(0.0, 1.0 - CT)))

    for iter in 1:max_iter
        x, sigma, U = bastankhah_downstream_solution(a, CT; L=L, I=I, E1=E1, E2=E2)

        # Eq. 2.24
        Y = 0.0
        dx_val = x[2] - x[1]
        for i in 1:(length(x)-1)
            weight = 1.0 - x[i] / sqrt(x[i]^2 + 0.25)
            dsig2 = (sigma[i+1]^2 - sigma[i]^2) / dx_val
            Y += weight * dsig2 * dx_val
        end

        # Inverse of Eq. 2.23 solved for a
        denom = 1.0 - Y
        if abs(denom) < 1e-10
            a_new = a
        else
            a_new = Y * (-1.0 + sqrt((Y + denom * CT) / Y)) / denom
        end

        if isnan(a_new) || abs(a - a_new) <= tol
            return a_new
        end
        a = relax * a_new + (1.0 - relax) * a
    end

    return a
end

export bastankhah_a_from_ct

# ═══════════════════════════════════════════════════════════════════════
# Tail plane effective wind — wake + downwash at empennage
# ═══════════════════════════════════════════════════════════════════════

"""
    tailplane_effective_wind(rotor, rho, v_wind, elev_deg, tail_distance;
                             model=:jensen, k=0.075) -> (v_eff, v_ind)

Effective wind speed and induced downwash velocity at the empennage,
accounting for rotor wake deficit and momentum-induced downwash.

Returns (v_eff, v_ind) where:
- `v_eff`: horizontal wind speed at tail (m/s), wake-deficit reduced.
- `v_ind`: vertical downwash velocity (m/s) from rotor momentum.

The tail sees wind at angle atan(v_ind, v_eff) relative to horizontal.
"""
function tailplane_effective_wind(rotor::AutogyroRotor, rho, v_wind, elev_deg,
                                  tail_distance; model::Symbol=:jensen, k=0.075)
    # Rotor thrust coefficient
    _, T, _ = rotor_force_bem(rotor, rho, v_wind, elev_deg)
    A = rotor_disk_area(rotor)
    q = 0.5 * rho * v_wind^2
    CT = A > 0.0 ? clamp(T / (q * A), 0.0, 0.99) : 0.0

    # Wake deficit ratio at tail distance
    ratio = wake_deficit(CT, rotor.radius, tail_distance; model=model, k=k)
    v_eff = v_wind * ratio

    # Induced downwash via momentum theory: v_ind = v_wind * a
    # a ≈ 0.5*(1 - sqrt(1-CT)) for CT ≤ 0.96
    a = CT > 0.0 ? 0.5 * (1.0 - sqrt(1.0 - CT)) : 0.0
    v_ind = v_wind * a

    return v_eff, v_ind
end

"""
    tailplane_force(v_eff, v_ind, span, chord; cl_alpha=0.08) -> (F_lift, F_drag, alpha_deg)

Lift and drag on an empennage surface at given effective wind.
Assumes thin symmetric airfoil with linear CL slope (cl_alpha per degree).
"""
function tailplane_force(v_eff, v_ind, span, chord; cl_alpha=0.08)
    rho = 1.225
    v_total = sqrt(v_eff^2 + v_ind^2)
    v_total < 0.1 && return (0.0, 0.0, 0.0)

    # Angle of attack from downwash
    alpha_deg = atand(v_ind, v_eff)
    area = span * chord
    q_dyn = 0.5 * rho * v_total^2

    # Thin airfoil: CL ≈ cl_alpha * alpha (per degree)
    cl = cl_alpha * abs(alpha_deg)
    cd0 = 0.01  # profile drag
    cd = cd0 + cl^2 / (π * (span^2 / area))  # induced drag

    lift = q_dyn * area * cl * sign(alpha_deg)
    drag = q_dyn * area * cd

    return lift, drag, alpha_deg
end

export tailplane_effective_wind, tailplane_force
