# src/sky_anchor.jl — sky anchor boundary for the top of the rotor stack
#
# The stack line runs from the ground anchor up through the rotors to R1.
# R1 terminates the line.  A sky anchor node adds a segment above R1.
# A backline ties the node to a fixed point.
#
# Prior art in KiteTurbineDynamics.jl:
# - docs/plans/2026-05-12-sky-anchor-node.md — the three-way knot.
#   The lifter kite, the backline, and the stack meet at the sky anchor.
# - handovers/handover-2026-05-28-pitch-depower.md section 2 — the frozen
#   direction failure.  A fixed force vector gives no restoring spring.
#   The anchor rang indefinitely.  The fix rebuilds the tension direction
#   from the instantaneous geometry every step.
# - The sky anchor spec (2026-10-06 review): lines cannot push.
#   Brief unloading is expected.  Sustained slack is a defect.

"""
    SkyAnchorBoundary

Abstract type for the sky anchor boundary at the top of an `AutogyroStack`.

The topmost rotor (R1) terminates the stack line.  The sky anchor node sits
above R1 on a new line segment.  A backline connects the node to a fixed point.

Concrete types:
- `RigidSkyAnchor`: fixed anchor.  Tension profiles do not change.
- `SingleBacklineSkyAnchor`: one tension-only backline.
- `TriangulatedDualBacklineSkyAnchor`: adds lateral stiffness to the node.
"""
abstract type SkyAnchorBoundary end

"""
    RigidSkyAnchor(position = (0.0, 0.0, 0.0))

Fixed sky anchor.  The anchor cannot move.

Tension profiles with this boundary are bit-for-bit identical to the profiles
without a sky anchor.  `profile[1]` stays exactly zero.

The struct keeps the position for dynamic callers.  The static profiles never use it.
"""
struct RigidSkyAnchor <: SkyAnchorBoundary
    position::NTuple{3, Float64}
end

RigidSkyAnchor() = RigidSkyAnchor((0.0, 0.0, 0.0))

"""
    SingleBacklineSkyAnchor(anchor_mass, backline_anchor, L_b0; EA_b, I_t, kwargs...)

Sky anchor node with one tension-only backline.  All values in SI units.

The node is a point mass `anchor_mass` m_a at A.  The backline runs from A to
a fixed point B (`backline_anchor`) with natural length `L_b0`.

# Node quantities

- Effective mass: `m_eff = m_a + m_b/3`.  `m_b` is the backline mass from
  `backline_mass`.
- Static backline tension: `T_b0 = m_a g + pretension`.  The mean stack pull
  at A is zero in the static model.
- Backline stiffness: `k_b = EA_b / L_b0`.

# Keyword arguments

- `EA_b`: elastic axial stiffness (N).  The source is the Samson AMSTEEL-X
  SK78 table.  Elastic elongation is 0.46 / 0.70 / 0.96 percent at 10 / 20 /
  30 percent of break.  That gives EA of about 30 times MBL.
- `EA_soft_factor`: soft multiplier on `EA_b` (default 0.25).  It covers
  constructional and creep stretch.  The soft EA is about 7 times MBL.
  The axial gate runs at the soft EA.
- `c_b`: axial damping (N s/m).  It covers line hysteresis only.  The default
  is `2 zeta_b sqrt(k_b m_eff)` with `zeta_b = 0.03`.
- `c_lat`: lateral swing damping (N s/m).  The default is
  `2 zeta_p m_eff omega_p` with `zeta_p = 0.1`.  This is the whip-energy
  bleed term.  The axial damper cannot damp swing.
- `I_t`: hub transverse inertia of the top rotor (kg m^2).  Blades-only
  credit is 3 kg m^2.  Full conservative rotor credit is 12.6 kg m^2.
- `k_mom`: node rocking stiffness (N m/rad).  It sets the whirl separation.
- `backline_diameter`: backline diameter (m), default 0.006.
- `line_density`: line material density (kg/m^3), default 970 (Dyneema).
- `pretension`: sky-kite pretension at the node (N), default 0.
"""
struct SingleBacklineSkyAnchor <: SkyAnchorBoundary
    anchor_mass::Float64
    backline_anchor::NTuple{3, Float64}
    L_b0::Float64
    EA_b::Float64
    EA_soft_factor::Float64
    c_b::Float64
    c_lat::Float64
    I_t::Float64
    k_mom::Float64
    backline_diameter::Float64
    line_density::Float64
    pretension::Float64
end

function SingleBacklineSkyAnchor(
    anchor_mass,
    backline_anchor,
    L_b0;
    EA_b,
    I_t,
    EA_soft_factor=0.25,
    c_b=nothing,
    c_lat=nothing,
    zeta_b=0.03,
    zeta_p=0.1,
    k_mom=0.0,
    backline_diameter=0.006,
    line_density=970.0,
    pretension=0.0,
)
    @assert anchor_mass > 0.0 "anchor_mass must be positive"
    @assert L_b0 > 0.0 "L_b0 must be positive"
    @assert EA_b > 0.0 "EA_b must be positive"
    @assert I_t > 0.0 "I_t must be positive"
    @assert k_mom >= 0.0 "k_mom must be non-negative"
    @assert backline_diameter > 0.0 "backline_diameter must be positive"

    m_b = line_mass_per_m(backline_diameter, line_density) * L_b0
    m_eff = anchor_mass + m_b / 3.0
    k_b = EA_b / L_b0
    T_b0 = anchor_mass * 9.81 + pretension
    @assert T_b0 > 0.0 "static backline tension must be positive"
    omega_p = sqrt(T_b0 / (m_eff * L_b0))

    c_b_val = c_b === nothing ? 2.0 * zeta_b * sqrt(k_b * m_eff) : Float64(c_b)
    c_lat_val = c_lat === nothing ? 2.0 * zeta_p * m_eff * omega_p : Float64(c_lat)

    return SingleBacklineSkyAnchor(
        Float64(anchor_mass),
        NTuple{3, Float64}(backline_anchor),
        Float64(L_b0),
        Float64(EA_b),
        Float64(EA_soft_factor),
        c_b_val,
        c_lat_val,
        Float64(I_t),
        Float64(k_mom),
        Float64(backline_diameter),
        Float64(line_density),
        Float64(pretension),
    )
end

"""
    TriangulatedDualBacklineSkyAnchor(single, lateral_stiffness)

Dual triangulated backline.  It adds a lateral spring, normal to the
backline, with stiffness `lateral_stiffness` in N/m.

Zero stiffness equals the single backline.  A large value approaches a rigid
lateral constraint.

The lateral spring acts on the node displacement from the vertical through
the fixed point B.  The vertical is the hanging equilibrium direction.
This is the v1 form of "normal to the backline".  The full dual-line
geometry arrives with the fold into KiteTurbineDynamics.jl.
"""
struct TriangulatedDualBacklineSkyAnchor <: SkyAnchorBoundary
    single::SingleBacklineSkyAnchor
    lateral_stiffness::Float64
    function TriangulatedDualBacklineSkyAnchor(single, lateral_stiffness)
        @assert lateral_stiffness >= 0.0 "lateral_stiffness must be non-negative"
        return new(single, Float64(lateral_stiffness))
    end
end

# --- Derived node quantities ---

"""
    backline_mass(b)

Backline mass (kg): `line_mass_per_m(diameter, density) * L_b0`.
"""
function backline_mass(b::SingleBacklineSkyAnchor)
    return line_mass_per_m(b.backline_diameter, b.line_density) * b.L_b0
end
backline_mass(t::TriangulatedDualBacklineSkyAnchor) = backline_mass(t.single)

"""
    anchor_effective_mass(b)

Effective point mass (kg): `m_eff = m_a + m_b/3`.

The model lumps the backline inertia at one third.
"""
anchor_effective_mass(b::SingleBacklineSkyAnchor) = b.anchor_mass + backline_mass(b) / 3.0
function anchor_effective_mass(t::TriangulatedDualBacklineSkyAnchor)
    return anchor_effective_mass(t.single)
end

"""
    backline_stiffness(b)

Elastic axial stiffness of the backline (N/m): `k_b = EA_b / L_b0`.
"""
backline_stiffness(b::SingleBacklineSkyAnchor) = b.EA_b / b.L_b0
backline_stiffness(t::TriangulatedDualBacklineSkyAnchor) = backline_stiffness(t.single)

"""
    soft_backline_stiffness(b)

Soft (constructional-stretch) axial stiffness (N/m):
`EA_b * EA_soft_factor / L_b0`.  The axial gate runs at this stiffness.
"""
soft_backline_stiffness(b::SingleBacklineSkyAnchor) = b.EA_b * b.EA_soft_factor / b.L_b0
function soft_backline_stiffness(t::TriangulatedDualBacklineSkyAnchor)
    return soft_backline_stiffness(t.single)
end

"""
    backline_tension_static(b)

Static backline tension at A (N): `m_a g + pretension`.
"""
backline_tension_static(b::SingleBacklineSkyAnchor) = b.anchor_mass * 9.81 + b.pretension
function backline_tension_static(t::TriangulatedDualBacklineSkyAnchor)
    return backline_tension_static(t.single)
end

# --- Mode frequencies ---

"""
    anchor_pendulum_frequency(b; heavy = false)

Swing mode frequency of the node (Hz).

Taut-string form: `f_p = (1/2pi) sqrt(T_b0 / (m_eff L_b0))`.

Heavy-string form (`heavy = true`): `f_p = (1/2pi) sqrt(3 g / (2 L_b0))`.
Use the heavy form when the anchor mass is much smaller than `m_b/3`.

The gate treats this frequency as informational only.  It passes trivially.
"""
function anchor_pendulum_frequency(b::SingleBacklineSkyAnchor; heavy=false)
    if heavy
        return sqrt(3.0 * 9.81 / (2.0 * b.L_b0)) / (2pi)
    end
    m_eff = anchor_effective_mass(b)
    T_b0 = backline_tension_static(b)
    return sqrt(T_b0 / (m_eff * b.L_b0)) / (2pi)
end

function anchor_pendulum_frequency(t::TriangulatedDualBacklineSkyAnchor; heavy=false)
    return anchor_pendulum_frequency(t.single; heavy=heavy)
end

"""
    anchor_axial_frequency(b; soft = false)

Axial mode frequency of the node (Hz): `f_ax = (1/2pi) sqrt(EA / (L_b0 m_eff))`.

`soft = false` uses the elastic EA.  `soft = true` uses the soft EA
(`EA_b * EA_soft_factor`).  The hard gate runs at the soft EA, the softest
credible value.  The elastic EA gives a clear margin.
"""
function anchor_axial_frequency(b::SingleBacklineSkyAnchor; soft=false)
    ea = soft ? b.EA_b * b.EA_soft_factor : b.EA_b
    m_eff = anchor_effective_mass(b)
    return sqrt(ea / (b.L_b0 * m_eff)) / (2pi)
end

function anchor_axial_frequency(t::TriangulatedDualBacklineSkyAnchor; soft=false)
    return anchor_axial_frequency(t.single; soft=soft)
end

"""
    whirl_frequency(k_mom, I_t, rpm)

Fast (forward) whirl root of the rotors on the compliant node (Hz).

    f_whirl = (1/2pi) [omega + sqrt(omega^2 + k_mom / I_t)]

`omega = 2pi rpm / 60` is the rotor rate.  The relation holds for a flat
rotor with `I_s / I_t = 2` (perpendicular axis theorem, 2 blades).
At `k_mom = 0` the fast root sits exactly on BPF = 2/rev.

The slow (backward) root is `sqrt(omega^2 + k_mom/I_t) - omega`.  It stays
below 1P while `k_mom < 3 I_t omega^2`.  Over-stiffening past that point
pushes the precession root up into 1P.
"""
function whirl_frequency(k_mom, I_t, rpm)
    @assert k_mom >= 0.0 "k_mom must be non-negative"
    @assert I_t > 0.0 "I_t must be positive"
    @assert rpm >= 0.0 "rpm must be non-negative"
    omega = 2pi * rpm / 60.0
    return (omega + sqrt(omega^2 + k_mom / I_t)) / (2pi)
end

"""
    whirl_precession_frequency(k_mom, I_t, rpm)

Slow (backward) whirl root (Hz): `(sqrt(omega^2 + k_mom/I_t) - omega) / 2pi`.
"""
function whirl_precession_frequency(k_mom, I_t, rpm)
    @assert k_mom >= 0.0 "k_mom must be non-negative"
    @assert I_t > 0.0 "I_t must be positive"
    @assert rpm >= 0.0 "rpm must be non-negative"
    omega = 2pi * rpm / 60.0
    return (sqrt(omega^2 + k_mom / I_t) - omega) / (2pi)
end

"""
    whirl_stiffness_required(I_t, rpm; n_blades = 2, separation = 0.3)

Minimum node rocking stiffness `k_mom` (N m/rad) that clears the whirl gate.

    k_mom = [(1 + separation) n_blades - 1]^2 I_t omega^2 - I_t omega^2

For a 2-blade machine at separation 0.3 the factor is 1.56.
Separation is `(1 + separation) x BPF`.  The function returns zero when
the free pivot already clears the rule.
"""
function whirl_stiffness_required(I_t, rpm; n_blades=2, separation=0.3)
    @assert I_t > 0.0 "I_t must be positive"
    @assert rpm > 0.0 "rpm must be positive"
    @assert separation >= 0.0 "separation must be non-negative"
    omega = 2pi * rpm / 60.0
    c = (1.0 + separation) * n_blades - 1.0
    return max(0.0, (c^2 - 1.0) * I_t * omega^2)
end

"""
    blade_passing_frequency(rpm; n_blades = 2)

Blade passing frequency (Hz): `BPF = n_blades * rpm / 60`.
The 2-blade stack machine has `BPF = 2/rev`.
"""
blade_passing_frequency(rpm; n_blades=2) = n_blades * rpm / 60.0

"""
    rotor_1p_frequency(rotor, v_wind, alpha_eff_deg; lambda = 2.5)

Rotation frequency 1P (Hz) from `estimated_autorotation_rpm`.

   1P = estimated_autorotation_rpm(rotor, v_wind, alpha_eff_deg) / 60
"""
function rotor_1p_frequency(rotor, v_wind, alpha_eff_deg; lambda=2.5)
    rpm = estimated_autorotation_rpm(rotor, v_wind, alpha_eff_deg; λ=lambda)
    return rpm / 60.0
end

# --- Gate report ---

"""
    anchor_mode_report(b; rpm, n_blades = 2)

Mode frequencies and separations of the sky anchor node for one rotor rate.

Separation is `abs(f - f_exc) / f_exc`.

Reported fields: `f_1p`, `bpf`, `f_p`, `f_p_heavy`, `sep_p_1p`, `sep_p_bpf`,
`f_ax`, `f_ax_soft`, `sep_ax_soft_bpf`, `f_whirl`, `f_precession`,
`k_mom_required`, `sep_whirl_bpf`.

`f_p` is informational.  The hard gates are the whirl separation and the
axial separation at the soft EA.  See `anchor_gate`.
"""
function anchor_mode_report(b::SingleBacklineSkyAnchor; rpm, n_blades=2)
    @assert rpm > 0.0 "rpm must be positive"
    f_1p = rpm / 60.0
    bpf = blade_passing_frequency(rpm; n_blades=n_blades)
    f_p = anchor_pendulum_frequency(b)
    f_p_heavy = anchor_pendulum_frequency(b; heavy=true)
    f_ax = anchor_axial_frequency(b)
    f_ax_soft = anchor_axial_frequency(b; soft=true)
    f_whirl = whirl_frequency(b.k_mom, b.I_t, rpm)
    f_prec = whirl_precession_frequency(b.k_mom, b.I_t, rpm)
    k_req = whirl_stiffness_required(b.I_t, rpm; n_blades=n_blades)

    sep(f, f_exc) = abs(f - f_exc) / f_exc

    return (;
        rpm,
        n_blades,
        f_1p,
        bpf,
        f_p,
        f_p_heavy,
        sep_p_1p=sep(f_p, f_1p),
        sep_p_bpf=sep(f_p, bpf),
        f_ax,
        f_ax_soft,
        sep_ax_soft_bpf=sep(f_ax_soft, bpf),
        f_whirl,
        f_precession=f_prec,
        k_mom_required=k_req,
        sep_whirl_bpf=sep(f_whirl, bpf),
    )
end

function anchor_mode_report(t::TriangulatedDualBacklineSkyAnchor; rpm, n_blades=2)
    return anchor_mode_report(t.single; rpm=rpm, n_blades=n_blades)
end

"""
    anchor_gate(b; rpm, n_blades = 2, separation = 0.3)

Hard gate check for the sky anchor node at one rotor rate.

Two hard gates, per the pinned spec:

1. Whirl: `sep_whirl_bpf >= separation`.  Separation is bought with `k_mom`.
   The free pivot sits exactly on BPF and fails.
2. Axial: `sep_ax_soft_bpf >= separation` at the soft EA.

There is no damping fallback branch.  No v1 element damps disk tilt.
The gate reports `f_p` for information only.  It never gates.

Returns `(ok, whirl_pass, axial_pass, report)`.
"""
function anchor_gate(b::SingleBacklineSkyAnchor; rpm, n_blades=2, separation=0.3)
    rep = anchor_mode_report(b; rpm=rpm, n_blades=n_blades)
    whirl_pass = rep.sep_whirl_bpf >= separation
    axial_pass = rep.sep_ax_soft_bpf >= separation
    return (; ok=whirl_pass && axial_pass, whirl_pass, axial_pass, report=rep)
end

function anchor_gate(t::TriangulatedDualBacklineSkyAnchor; rpm, n_blades=2, separation=0.3)
    return anchor_gate(t.single; rpm=rpm, n_blades=n_blades, separation=separation)
end

# --- Static coupling into the tension profile ---

"""
    anchor_segment_tension(b; kite_pull = b.pretension,
                           backline_tension = backline_tension_static(b))

Static tension in the anchor segment above R1 (N).

Vertical balance at the node: the kite pulls up.  The backline, the anchor
weight, and the segment pull down.

    T_a = max(0, kite_pull - backline_tension - m_a g)

The default backline tension is `m_a g + pretension`.  The defaults give
T_a = 0.  That matches the zero mean stack pull at A in the static model.

Letting the backline out lowers its tension and raises T_a.  This is the
KTD furl mechanism (docs/plans/2026-05-12-sky-anchor-node.md): relaxing the
backline lets the kite lift the anchor and pull the stack top.

The `RigidSkyAnchor` method returns 0.0.  The segment does not exist.
"""
function anchor_segment_tension(
    b::SingleBacklineSkyAnchor;
    kite_pull=b.pretension,
    backline_tension=backline_tension_static(b),
)
    return max(0.0, kite_pull - backline_tension - b.anchor_mass * 9.81)
end

function anchor_segment_tension(
    t::TriangulatedDualBacklineSkyAnchor;
    kite_pull=t.single.pretension,
    backline_tension=backline_tension_static(t.single),
)
    return anchor_segment_tension(
        t.single; kite_pull=kite_pull, backline_tension=backline_tension
    )
end

anchor_segment_tension(::RigidSkyAnchor; kwargs...) = 0.0

# --- Node dynamics ---
#
# The node state holds position and velocity in 3D.  The backline tension
# rebuilds along the instantaneous node-to-B direction every step.  A frozen
# direction gives no geometric spring and the anchor rings indefinitely
# (handover-2026-05-28-pitch-depower.md section 2).
#
# The tension-only rule uses a smooth hinge.  The hinge potential is the
# exact integral of the hinge force.  The energy ledger then stays
# non-positive across slack crossings by construction.

# Smooth hinge: an even, C1 approximation of max(0, eps).
_soft_hinge(eps, s) = 0.5 * (eps + sqrt(eps * eps + s * s))

# Smooth hinge slope.  It gates the axial hysteresis damper.
# A slack rope cannot damp.
_soft_hinge_slope(eps, s) = 0.5 * (1.0 + eps / sqrt(eps * eps + s * s))

# Integral of the smooth hinge from 0 to eps.
# d/d eps _hinge_potential = _soft_hinge.
function _hinge_potential(eps, s)
    return 0.25 * eps * eps +
           0.25 * (eps * sqrt(eps * eps + s * s) + s * s * asinh(eps / s))
end

# Total force on the node and the dissipation rate (W).
function _node_force(b::SingleBacklineSkyAnchor, r, v, smooth)
    B = b.backline_anchor
    d1 = B[1] - r[1]
    d2 = B[2] - r[2]
    d3 = B[3] - r[3]
    len = sqrt(d1 * d1 + d2 * d2 + d3 * d3)
    u1 = d1 / len
    u2 = d2 / len
    u3 = d3 / len

    eps = len - b.L_b0
    vpar = v[1] * u1 + v[2] * u2 + v[3] * u3
    epsdot = -vpar

    hinge = _soft_hinge(eps, smooth)
    hinge_slope = _soft_hinge_slope(eps, smooth)

    k_b = b.EA_b / b.L_b0
    t_pot = k_b * hinge
    t_raw = t_pot + b.c_b * epsdot * hinge_slope
    # Lines cannot push.  Smooth floor at zero tension.
    t_ten = _soft_hinge(t_raw, 1.0e-3)

    m_eff = b.anchor_mass + backline_mass(b) / 3.0

    f1 = t_ten * u1
    f2 = t_ten * u2
    f3 = t_ten * u3

    # Lateral swing damping.  This is the whip-energy bleed term.
    f1 -= b.c_lat * (v[1] - vpar * u1)
    f2 -= b.c_lat * (v[2] - vpar * u2)
    f3 -= b.c_lat * (v[3] - vpar * u3)

    f3 -= m_eff * 9.81

    # Exact non-conservative accounting.  The clamp trims the damper
    # during release.  The first term accounts for the trim.
    diss =
        (t_ten - t_pot) * epsdot +
        b.c_lat * ((v[1] - vpar * u1)^2 + (v[2] - vpar * u2)^2 + (v[3] - vpar * u3)^2)

    return (Float64[f1, f2, f3], diss)
end

# The dual backline adds a lateral spring.  The spring pulls toward the
# vertical through B.  It is conservative.  Its potential is `u_lat`.
function _node_force(t::TriangulatedDualBacklineSkyAnchor, r, v, smooth)
    F, diss = _node_force(t.single, r, v, smooth)
    B = t.single.backline_anchor
    F[1] -= t.lateral_stiffness * (r[1] - B[1])
    F[2] -= t.lateral_stiffness * (r[2] - B[2])
    return (F, diss)
end

_node_mass(b::SingleBacklineSkyAnchor) = anchor_effective_mass(b)
_node_mass(t::TriangulatedDualBacklineSkyAnchor) = anchor_effective_mass(t.single)

"""
    anchor_acceleration(b, r, v; smooth = 1.0e-4)

Node acceleration (m/s^2) for position `r` and velocity `v`.

`r` and `v` are 3-vectors.  `smooth` is the regularisation width (m) of the
tension-only hinge.

The backline direction rebuilds from the instantaneous geometry.  Do not
freeze it.  See `handover-2026-05-28-pitch-depower.md` section 2 in
KiteTurbineDynamics.jl.
"""
function anchor_acceleration(
    b::Union{SingleBacklineSkyAnchor, TriangulatedDualBacklineSkyAnchor},
    r,
    v;
    smooth=1.0e-4,
)
    F, _ = _node_force(b, r, v, smooth)
    m = _node_mass(b)
    return F ./ m
end

# RK4 state: [x, y, z, vx, vy, vz, e_diss].
# The last component integrates the dissipation rate.
function _anchor_state_derivative(b, y, smooth)
    r = (y[1], y[2], y[3])
    v = (y[4], y[5], y[6])
    F, diss = _node_force(b, r, v, smooth)
    m = _node_mass(b)
    return Float64[y[4], y[5], y[6], F[1] / m, F[2] / m, F[3] / m, diss]
end

function _rk4_step(b, y, dt, smooth)
    k1 = _anchor_state_derivative(b, y, smooth)
    k2 = _anchor_state_derivative(b, y .+ (0.5 * dt) .* k1, smooth)
    k3 = _anchor_state_derivative(b, y .+ (0.5 * dt) .* k2, smooth)
    k4 = _anchor_state_derivative(b, y .+ dt .* k3, smooth)
    return y .+ (dt / 6.0) .* (k1 .+ 2.0 .* k2 .+ 2.0 .* k3 .+ k4)
end

"""
    simulate_anchor(b; r0, v0, tspan = (0.0, 60.0), dt = 0.001, smooth = 1.0e-4)

Integrate the sky anchor node with fixed-step RK4.

# Arguments
- `b`: a `SingleBacklineSkyAnchor` or `TriangulatedDualBacklineSkyAnchor`.
- `r0`, `v0`: initial position and velocity, 3-vectors.
- `tspan`: start and stop time (s).
- `dt`: step (s).
- `smooth`: regularisation width of the tension-only hinge (m).

# Returns
A named tuple with time series: `t`, `r` (positions), `v` (velocities),
`eps` (backline stretch, m), `tension` (N), `ke`, `pe`, `u` (backline
potential), `u_lat` (lateral spring potential), `diss` (cumulative
dissipation, J), and `m_eff`.

Slack events come from `slack_events`.  The energy check comes from
`energy_ledger`.
"""
function simulate_anchor(
    b::Union{SingleBacklineSkyAnchor, TriangulatedDualBacklineSkyAnchor};
    r0,
    v0,
    tspan=(0.0, 60.0),
    dt=0.001,
    smooth=1.0e-4,
)
    @assert dt > 0.0 "dt must be positive"
    @assert tspan[2] > tspan[1] "tspan must increase"

    n_steps = round(Int, (tspan[2] - tspan[1]) / dt)
    m_eff = _node_mass(b)
    B = _backline_anchor(b)
    L_b0 = _backline_L0(b)

    y = Float64[r0[1], r0[2], r0[3], v0[1], v0[2], v0[3], 0.0]

    t = Vector{Float64}(undef, n_steps + 1)
    rs = Vector{Vector{Float64}}(undef, n_steps + 1)
    vs = Vector{Vector{Float64}}(undef, n_steps + 1)
    eps = Vector{Float64}(undef, n_steps + 1)
    tension = Vector{Float64}(undef, n_steps + 1)
    ke = Vector{Float64}(undef, n_steps + 1)
    pe = Vector{Float64}(undef, n_steps + 1)
    u = Vector{Float64}(undef, n_steps + 1)
    u_lat = Vector{Float64}(undef, n_steps + 1)
    diss = Vector{Float64}(undef, n_steps + 1)

    _store = function (i)
        r = Float64[y[1], y[2], y[3]]
        v = Float64[y[4], y[5], y[6]]
        t[i] = tspan[1] + (i - 1) * dt
        rs[i] = r
        vs[i] = v
        d1 = B[1] - r[1]
        d2 = B[2] - r[2]
        d3 = B[3] - r[3]
        len = sqrt(d1 * d1 + d2 * d2 + d3 * d3)
        eps[i] = len - L_b0
        vpar = (v[1] * d1 + v[2] * d2 + v[3] * d3) / len
        t_ten = _soft_hinge(_tension_raw(b, eps[i], -vpar, smooth), 1.0e-3)
        tension[i] = t_ten
        ke[i] = 0.5 * m_eff * (v[1]^2 + v[2]^2 + v[3]^2)
        pe[i] = m_eff * 9.81 * r[3]
        u[i] = _spring_potential(b, eps[i], smooth)
        u_lat[i] = _lateral_potential(b, r)
        diss[i] = y[7]
        return nothing
    end

    _store(1)
    for i in 1:n_steps
        y = _rk4_step(b, y, dt, smooth)
        _store(i + 1)
    end

    return (; t, r=rs, v=vs, eps, tension, ke, pe, u, u_lat, diss, m_eff)
end

_backline_anchor(b::SingleBacklineSkyAnchor) = b.backline_anchor
_backline_anchor(t::TriangulatedDualBacklineSkyAnchor) = t.single.backline_anchor
_backline_L0(b::SingleBacklineSkyAnchor) = b.L_b0
_backline_L0(t::TriangulatedDualBacklineSkyAnchor) = t.single.L_b0

function _tension_raw(b::SingleBacklineSkyAnchor, eps, epsdot, smooth)
    return (b.EA_b / b.L_b0) * _soft_hinge(eps, smooth) +
           b.c_b * epsdot * _soft_hinge_slope(eps, smooth)
end

function _tension_raw(t::TriangulatedDualBacklineSkyAnchor, eps, epsdot, smooth)
    return _tension_raw(t.single, eps, epsdot, smooth)
end

function _spring_potential(b::SingleBacklineSkyAnchor, eps, smooth)
    return (b.EA_b / b.L_b0) * _hinge_potential(eps, smooth)
end

function _spring_potential(t::TriangulatedDualBacklineSkyAnchor, eps, smooth)
    return _spring_potential(t.single, eps, smooth)
end

_lateral_potential(::SingleBacklineSkyAnchor, r) = 0.0
function _lateral_potential(t::TriangulatedDualBacklineSkyAnchor, r)
    B = t.single.backline_anchor
    dx = r[1] - B[1]
    dy = r[2] - B[2]
    return 0.5 * t.lateral_stiffness * (dx * dx + dy * dy)
end

"""
    slack_events(sim; min_dwell = 0.8)

Find intervals where the backline stretch is negative.  Stretch is
`eps = |r_B - r_A| - L_b0`.  A negative stretch means slack.

The function reports each event with start time, end time, and dwell.
An event is sustained when `dwell >= min_dwell`.

The default 0.8 s matches the KTD wobble gate (T < 1 N for delta t > 0.8 s).
Expect brief unloading.  Sustained slack is the defect.

# Returns
`(events, n_total, sustained, n_sustained)`.  Each event is a named tuple
with `t0`, `t1`, and `dwell`.
"""
function slack_events(sim; min_dwell=0.8)
    events = NamedTuple{(:t0, :t1, :dwell), Tuple{Float64, Float64, Float64}}[]
    n = length(sim.t)
    in_slack = false
    t_start = 0.0

    for i in 1:(n - 1)
        e0 = sim.eps[i]
        e1 = sim.eps[i + 1]
        if !in_slack && e0 < 0.0
            in_slack = true
            t_start = sim.t[i]
        elseif in_slack && e1 >= 0.0
            t_end = sim.t[i] + (sim.t[i + 1] - sim.t[i]) * (-e0) / (e1 - e0)
            push!(events, (t0=t_start, t1=t_end, dwell=t_end - t_start))
            in_slack = false
        end
    end

    if in_slack
        push!(events, (t0=t_start, t1=sim.t[end], dwell=sim.t[end] - t_start))
    end

    sustained = [e for e in events if e.dwell >= min_dwell]
    return (; events, n_total=length(events), sustained, n_sustained=length(sustained))
end

"""
    energy_ledger(sim; tol = nothing)

Pointwise energy check over a `simulate_anchor` run.

Mechanical energy is `ke + pe + u + u_lat`.  `gain` is the change from the
first sample.  `residual` is `gain + diss`.  The residual is zero up to
integration error when the force comes from a potential.

The check `ok` requires two conditions.  The mechanical energy never gains
more than `tol`.  The residual never exceeds `tol` in magnitude.  The
default `tol` is `1e-6` of the energy scale.

The hinge potential is the exact integral of the hinge force, so the
tension-only smoothing cannot pump energy at slack crossings.

The tension clamp trims the damper during release windows.  The dissipation
term in `_node_force` accounts for the trim exactly.  The residual then
stays at integration-error level through slack crossings.
"""
function energy_ledger(sim; tol=nothing)
    mech = sim.ke .+ sim.pe .+ sim.u .+ sim.u_lat
    gain = mech .- mech[1]
    residual = gain .+ sim.diss
    e_ref = maximum(abs, mech)
    atol = tol === nothing ? 1.0e-6 * max(e_ref, 1.0) : Float64(tol)
    max_gain = maximum(gain)
    max_residual = maximum(abs, residual)
    ok = max_gain <= atol && max_residual <= atol
    return (; mech, gain, residual, max_gain, max_residual, tol=atol, ok)
end
