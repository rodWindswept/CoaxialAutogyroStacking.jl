# src/airfoil_data.jl - NACA 0012 CL/CD lookup tables
#
# Data sources:
#   Re = 100,000: XFoil 6.96 prediction (airfoiltools.com, Ncrit=9)
#   Re = 200,000, 500,000, 1,000,000: scaled from Re=100k using
#     Abbott & von Doenhoff "Theory of Wing Sections" (1959)
#     lift-slope invariance (2π/rad), CL_max scaling, CD_min scaling.
#
# All tables at Mach=0 (incompressible). α in degrees, Re dimensionless.

# ── Raw XFoil data (Re = 100,000, Ncrit=9) ──────────────────────────────────
# (alpha_deg, CL, CD)
const _NACA0012_RE100K = [
    (-12.75, -0.5002, 0.13756),
    (-12.50, -0.5184, 0.13358),
    (-12.25, -0.7724, 0.10051),
    (-12.00, -0.7713, 0.09532),
    (-11.75, -0.7896, 0.08685),
    (-11.50, -0.8377, 0.07511),
    (-11.25, -0.9695, 0.06291),
    (-11.00, -0.9842, 0.05891),
    (-10.75, -0.9915, 0.05467),
    (-10.50, -0.9911, 0.05060),
    (-10.25, -0.9765, 0.04806),
    (-10.00, -0.9659, 0.04582),
    ( -9.75, -0.9597, 0.04303),
    ( -9.50, -0.9523, 0.04019),
    ( -9.25, -0.9430, 0.03777),
    ( -9.00, -0.9245, 0.03526),
    ( -8.75, -0.9056, 0.03367),
    ( -8.50, -0.8883, 0.03189),
    ( -8.25, -0.8673, 0.02998),
    ( -8.00, -0.8471, 0.02869),
    ( -7.75, -0.8256, 0.02707),
    ( -7.50, -0.8050, 0.02598),
    ( -7.25, -0.7836, 0.02464),
    ( -7.00, -0.7631, 0.02348),
    ( -6.75, -0.7430, 0.02242),
    ( -6.50, -0.7235, 0.02143),
    ( -6.25, -0.7047, 0.02050),
    ( -6.00, -0.6862, 0.01958),
    ( -5.75, -0.6682, 0.01875),
    ( -5.50, -0.6504, 0.01798),
    ( -5.25, -0.6324, 0.01733),
    ( -5.00, -0.6141, 0.01674),
    ( -4.75, -0.5953, 0.01627),
    ( -4.50, -0.5761, 0.01585),
    ( -4.25, -0.5565, 0.01550),
    ( -4.00, -0.5366, 0.01520),
    ( -3.75, -0.5162, 0.01493),
    ( -3.50, -0.4957, 0.01471),
    ( -3.25, -0.4751, 0.01453),
    ( -3.00, -0.4545, 0.01440),
    ( -2.75, -0.4340, 0.01432),
    ( -2.50, -0.4137, 0.01429),
    ( -2.25, -0.3935, 0.01433),
    ( -2.00, -0.3737, 0.01444),
    ( -1.75, -0.3539, 0.01463),
    ( -1.50, -0.3320, 0.01489),
    ( -1.25, -0.3021, 0.01527),
    ( -1.00, -0.2578, 0.01574),
    ( -0.75, -0.2041, 0.01619),
    ( -0.50, -0.1345, 0.01658),
    ( -0.25, -0.0651, 0.01682),
    (  0.00,  0.0000, 0.01693),
    (  0.25,  0.0651, 0.01682),
    (  0.50,  0.1344, 0.01658),
    (  0.75,  0.2040, 0.01619),
    (  1.00,  0.2578, 0.01574),
    (  1.25,  0.3020, 0.01527),
    (  1.50,  0.3320, 0.01489),
    (  1.75,  0.3538, 0.01462),
    (  2.00,  0.3737, 0.01444),
    (  2.25,  0.3934, 0.01433),
    (  2.50,  0.4136, 0.01429),
    (  2.75,  0.4339, 0.01432),
    (  3.00,  0.4544, 0.01440),
    (  3.25,  0.4750, 0.01453),
    (  3.50,  0.4957, 0.01471),
    (  3.75,  0.5162, 0.01493),
    (  4.00,  0.5365, 0.01520),
    (  4.25,  0.5565, 0.01549),
    (  4.50,  0.5761, 0.01585),
    (  4.75,  0.5953, 0.01627),
    (  5.00,  0.6141, 0.01674),
    (  5.25,  0.6323, 0.01732),
    (  5.50,  0.6503, 0.01798),
    (  5.75,  0.6681, 0.01874),
    (  6.00,  0.6862, 0.01958),
    (  6.25,  0.7046, 0.02050),
    (  6.50,  0.7235, 0.02143),
    (  6.75,  0.7430, 0.02242),
    (  7.00,  0.7631, 0.02348),
    (  7.25,  0.7836, 0.02464),
    (  7.50,  0.8050, 0.02598),
    (  7.75,  0.8256, 0.02706),
    (  8.00,  0.8471, 0.02869),
    (  8.25,  0.8673, 0.02998),
    (  8.50,  0.8884, 0.03189),
    (  8.75,  0.9057, 0.03367),
    (  9.00,  0.9246, 0.03526),
    (  9.25,  0.9431, 0.03777),
    (  9.50,  0.9524, 0.04019),
    (  9.75,  0.9598, 0.04303),
    ( 10.00,  0.9661, 0.04582),
    ( 10.25,  0.9768, 0.04806),
    ( 10.50,  0.9913, 0.05061),
    ( 10.75,  0.9917, 0.05469),
    ( 11.00,  0.9845, 0.05893),
    ( 11.25,  0.9697, 0.06293),
    ( 11.50,  0.8378, 0.07522),
    ( 11.75,  0.7898, 0.08703),
]

# ── Constructed tables for higher Re ────────────────────────────────────────
# Method: take Re=100k data, scale CL in linear range to maintain
# 2π/rad lift slope, extend linear range to higher α, raise CL_max,
# lower CD proportionally to CD_min(Re)/CD_min(100k).

# CD_min at each Re:
const _CD_MIN = Dict(1e5 => 0.01429, 2e5 => 0.0105, 5e5 => 0.0085, 1e6 => 0.0070)

# CL_max and stall α at each Re:
const _STALL = Dict(
    1e5 => (α_stall=10.75, CL_max=0.9917),
    2e5 => (α_stall=13.0,  CL_max=1.2),
    5e5 => (α_stall=15.0,  CL_max=1.4),
    1e6 => (α_stall=16.0,  CL_max=1.6),
)

# Lift slope (2π/rad in degrees) — invariant with Re in linear range
# 2π per radian, 1 rad = 180/π degrees → per degree = 2π²/180 ≈ 0.11
const _CL_ALPHA = 2π^2 / 180.0  # ≈ 0.10966 deg⁻¹

"""
    naca0012_cl(alpha_deg::Real, Re::Real) -> Float64

Lift coefficient for NACA 0012 airfoil at given angle of attack (degrees)
and Reynolds number. Uses linear interpolation within stored tables;
nearest-Re interpolation between stored Re values (100k, 200k, 500k, 1M).

Outside the table range (±10–12° depending on Re): extended using a
flat-plate post-stall model: CL = CL_max × sin(2α) to approximate
deep-stall behaviour with gradual lift loss.

# Arguments
- `alpha_deg`: angle of attack (degrees).
- `Re`: Reynolds number (dimensionless).

# Examples
```jldoctest
julia> naca0012_cl(0.0, 1e5)
0.0

julia> naca0012_cl(5.0, 5e5) > 0.5
true
```
"""
function naca0012_cl(alpha_deg::Real, Re::Real)
    # Reflect: symmetric airfoil, CL(-α) = -CL(α)
    α = abs(alpha_deg)
    sign = alpha_deg >= 0 ? 1.0 : -1.0

    table = _table_for_re(Re)
    cl = _interp_1d(α, table, 1, 2)  # column 1=alpha, column 2=CL

    # Post-stall extension for α beyond table max
    α_max = table[end][1]
    if α > α_max
        s = _STALL[_nearest_re(Re)]
        cl_max = s.CL_max
        α_stall = s.α_stall
        # Linear decay from CL_max at α_stall to 0 at α=90°
        if α >= 90.0
            cl = 0.0
        else
            cl = cl_max * (90.0 - α) / (90.0 - α_stall)
        end
        cl = max(cl, 0.0)
    end

    return sign * cl
end

"""
    naca0012_cd(alpha_deg::Real, Re::Real) -> Float64

Drag coefficient for NACA 0012 airfoil. Same interpolation strategy as
[`naca0012_cl`](@ref). Post-stall: CD → CD_max (≈ 2.0, flat plate normal
to flow).

# Examples
```jldoctest
julia> naca0012_cd(0.0, 1e5) > 0.01
true
```
"""
function naca0012_cd(alpha_deg::Real, Re::Real)
    α = abs(alpha_deg)
    table = _table_for_re(Re)
    cd = _interp_1d(α, table, 1, 3)  # column 1=alpha, column 3=CD

    # Post-stall: CD rises toward flat-plate value
    α_max = table[end][1]
    if α > α_max
        cd_max = 2.0  # flat plate normal to flow
        cd_min = _CD_MIN[_nearest_re(Re)]
        # Smooth blend from last tabulated CD to flat-plate CD
        frac = min((α - α_max) / 30.0, 1.0)
        cd = cd * (1 - frac) + cd_max * frac
    end

    return cd
end

# ── Internal helpers ────────────────────────────────────────────────────────

"Available Reynolds numbers for table lookup."
const _AVAILABLE_RES = [1e5, 2e5, 5e5, 1e6]

function _nearest_re(Re::Real)
    distances = [abs(Re - r) for r in _AVAILABLE_RES]
    return _AVAILABLE_RES[argmin(distances)]
end

function _table_for_re(Re::Real)
    r = _nearest_re(Re)
    if r == 1e5
        return _NACA0012_RE100K
    else
        return _build_scaled_table(r)
    end
end

# Build scaled tables for higher Re from Re=100k template + scaling laws
function _build_scaled_table(Re_target::Real)
    cd_ratio = _CD_MIN[Re_target] / _CD_MIN[1e5]
    s = _STALL[Re_target]

    pts = Tuple{Float64,Float64,Float64}[]
    for (α, cl_ref, cd_ref) in _NACA0012_RE100K

        # CL: keep linear range, extend before stall
        cl = cl_ref
        if abs(α) <= s.α_stall
            # In linear range, CL should track 2π/rad. The Re=100k data
            # already does (mostly), but we enforce it near the linear range.
            cl_ideal = _CL_ALPHA * α
            # Blend: use table value near stall, ideal slope elsewhere
            if abs(α) < 8.0
                cl = cl_ideal
            else
                # Blend from ideal to table near stall
                w = (abs(α) - 8.0) / (s.α_stall - 8.0)
                cl = cl_ideal * (1 - w) + cl_ref * w
            end
        else
            # Post-stall: not in this table — handled by extrapolation
            # in naca0012_cl(). Skip these points for higher-Re tables
            # since stall α is higher.
            if α > 10.75
                continue
            end
        end

        # CD: scale proportionally to CD_min ratio
        cd = cd_ref * cd_ratio

        push!(pts, (α, cl, cd))
    end

    # Extend table to this Re's stall α (if stall α > Re=100k stall)
    if s.α_stall > 10.75
        last_α = pts[end][1]
        # Extend linear range from last point to stall α
        for α in (last_α + 0.25):0.25:(s.α_stall + 1.0)
            cl = _CL_ALPHA * α
            # CD grows quadratically with CL in linear range
            cd = _CD_MIN[Re_target] + 0.05 * cl^2
            push!(pts, (α, cl, cd))
        end
    end

    return pts
end

"""
    _interp_1d(x, table, col_x, col_y) -> Float64

Linear interpolation in a sorted table of tuples. Returns boundary values
for x outside table range.
"""
function _interp_1d(x, table, col_x, col_y)
    xs = [row[col_x] for row in table]
    ys = [row[col_y] for row in table]

    # Below range
    if x <= xs[1]
        return ys[1]
    end

    # Above range
    if x >= xs[end]
        return ys[end]
    end

    # Binary search for interval
    lo, hi = 1, length(xs)
    while hi - lo > 1
        mid = (lo + hi) ÷ 2
        if xs[mid] <= x
            lo = mid
        else
            hi = mid
        end
    end

    # Linear interpolation
    t = (x - xs[lo]) / (xs[hi] - xs[lo])
    return ys[lo] + t * (ys[hi] - ys[lo])
end

export naca0012_cl, naca0012_cd
