# src/sweep.jl — Parameter sweep for stacked autogyro configurations
#
# Sweeps rotor radius, stack count, spacing, tilt profile, wind speed, and
# line elevation to discover Pareto-optimal configurations.
#
# Figures of merit:
#   1. Anchor tension (N) — raw lift
#   2. Anchor tension per rotor mass (N/kg) — mass efficiency
#   3. Tension coefficient of variation across wind speeds — gust stability

using DataFrames
using Statistics: mean, std

# ── Tilt profile generators ────────────────────────────────────────────────────
# Each returns a Vector{Float64} of length N (tilt per rotor, top→bottom)
# All tilts in degrees, clamped to [0°, 30°] (PCA-2 valid range)

"""
    uniform_tilt(N)

All rotors at the midpoint tilt (10°). Baseline profile.
"""
function uniform_tilt(N)
    return fill(10.0, N)
end

"""
    top_draggy_tilt(N)

Tilt decreases from top (20°) to bottom (0°). Top rotors are draggier — they
pull the line outward into the wind, shaping it for the rotors below.
"""
function top_draggy_tilt(N)
    N == 1 && return [10.0]
    return [20.0 - 20.0 * (i - 1) / (N - 1) for i in 1:N]
end

"""
    bottom_lifty_tilt(N)

Tilt increases from top (0°) to bottom (20°). Top rotors are nearly flat
(perpendicular to line), bottom rotors at optimal L/D for the shaped line.
"""
function bottom_lifty_tilt(N)
    N == 1 && return [10.0]
    return [0.0 + 20.0 * (i - 1) / (N - 1) for i in 1:N]
end

"""
    graded_tilt(N)

Linear ramp from 5° (top) to 20° (bottom). Intermediate between uniform and
bottom-lifty.
"""
function graded_tilt(N)
    N == 1 && return [10.0]
    return [5.0 + 15.0 * (i - 1) / (N - 1) for i in 1:N]
end

const TILT_PROFILES = Dict(
    "uniform"       => uniform_tilt,
    "top_draggy"    => top_draggy_tilt,
    "bottom_lifty"  => bottom_lifty_tilt,
    "graded"        => graded_tilt,
)

# ── Sweep function ────────────────────────────────────────────────────────────

"""
    parameter_sweep(; kwargs...) -> DataFrame

Run a full parameter sweep over stacked autogyro configurations.

# Keyword Arguments (with defaults)

| Parameter | Default | Description |
|-----------|---------|-------------|
| `radii` | `[0.5, 1.0, 1.5, 2.0, 2.5, 3.0]` | Rotor radius (m) |
| `stack_counts` | `[1, 2, 3, 4]` | Number of rotors |
| `spacings` | `[5.0, 10.0, 15.0, 20.0, 25.0, 30.0]` | Rotor spacing (m) |
| `profiles` | `["uniform", "top_draggy", "bottom_lifty", "graded"]` | Tilt profile names |
| `wind_speeds` | `[4.0, 6.0, 8.0, 10.0, 12.0]` | Wind speed (m/s) |
| `elevations` | `[45.0, 55.0, 65.0]` | Line elevation (degrees) |
| `rho` | `1.225` | Air density (kg/m³) |
| `line_dia` | `0.004` | Dyneema diameter (m) |
| `rotor_mass` | `5.0` | Mass per rotor (kg) |
| `hub_radius` | `0.05` | Hub inner radius (m) |
| `n_blades` | `2` | Number of blades |
| `blade_chord` | `0.15` | Mean blade chord (m) |

# Returns

DataFrame with columns:
- `radius`, `n_rotors`, `spacing`, `profile`, `elevation`, `wind_speed`
- `anchor_tension`: anchor tension at this wind speed (N)
- `total_lift`: total aerodynamic lift from all rotors (N)
- `profile_min`, `profile_max`: tension range across segment positions (N)

# Examples

```julia
# Quick test sweep (tiny grid)
df = parameter_sweep(radii=[1.0, 2.0], stack_counts=[1, 3],
                     spacings=[10.0], profiles=["uniform"],
                     wind_speeds=[8.0], elevations=[55.0])

# Full production sweep
df_full = parameter_sweep()
```
"""
function parameter_sweep(;
    radii          = [0.5, 1.0, 1.5, 2.0, 2.5, 3.0],
    stack_counts   = [1, 2, 3, 4],
    spacings       = [5.0, 10.0, 15.0, 20.0, 25.0, 30.0],
    profiles       = ["uniform", "top_draggy", "bottom_lifty", "graded"],
    wind_speeds    = [4.0, 6.0, 8.0, 10.0, 12.0],
    elevations     = [45.0, 55.0, 65.0],
    rho            = 1.225,
    line_dia       = 0.004,
    rotor_mass     = 5.0,
    hub_radius     = 0.05,
    n_blades       = 2,
    blade_chord    = 0.15,
)

    # Pre-allocate results (worst-case count)
    total_combos = length(radii) * length(stack_counts) * length(spacings) *
                   length(profiles) * length(elevations)
    n_rows = total_combos * length(wind_speeds)
    results = Vector{Any}(undef, n_rows)

    idx = 1
    for radius in radii
        for n in stack_counts
            for spacing in spacings
                for profile_name in profiles
                    tilts = TILT_PROFILES[profile_name](n)

                    for elev in elevations
                        # Build rotors with this profile's tilts
                        rotors = AutogyroRotor[]
                        for tilt in tilts
                            push!(rotors, AutogyroRotor(
                                radius, hub_radius, n_blades,
                                blade_chord, tilt, 0.0, rotor_mass))
                        end

                        # Section lengths: equal spacing between rotors + to anchor
                        section_lens = fill(spacing, n)

                        # Build stack
                        stack = AutogyroStack(rotors, section_lens, line_dia, elev)

                        # Compute tension at each wind speed
                        for v in wind_speeds
                            profile = stack_tension_profile(stack, rho, v)
                            anchor_t = profile[end]
                            # Total lift = sum of F_line across all rotors
                            total_lift = 0.0
                            for r in rotors
                                fl, _, _, _, _ = rotor_force_along_line(r, rho, v, elev)
                                total_lift += fl
                            end

                            results[idx] = (
                                radius       = radius,
                                n_rotors     = n,
                                spacing      = spacing,
                                profile      = profile_name,
                                elevation    = elev,
                                wind_speed   = v,
                                anchor_tension = anchor_t,
                                total_lift   = total_lift,
                                profile_min  = minimum(profile),
                                profile_max  = maximum(profile),
                            )
                            idx += 1
                        end
                    end
                end
            end
        end
    end

    # Trim to actual count
    resize!(results, idx - 1)
    return DataFrame(results)
end

# ── Post-processing: figures of merit ─────────────────────────────────────────

"""
    compute_figures_of_merit(df::DataFrame) -> DataFrame

Group sweep results by configuration and compute:
- `mean_anchor_tension`: mean anchor tension across wind speeds (N)
- `tension_per_kg`: anchor tension per unit rotor mass (N/kg)
- `tension_cv`: coefficient of variation across wind speeds (lower = more stable)

Returns a DataFrame with one row per unique configuration.
"""
function compute_figures_of_merit(df::DataFrame)
    # Group by configuration (everything except wind_speed and tension cols)
    config_cols = [:radius, :n_rotors, :spacing, :profile, :elevation]
    gdf = groupby(df, config_cols)

    result_rows = []
    for g in gdf
        tensions = g.anchor_tension
        mean_t = mean(tensions)
        cv_t = length(tensions) > 1 ? std(tensions) / abs(mean_t) : 0.0
        mass_total = g.n_rotors[1] * 5.0  # rotor_mass = 5 kg (hardcoded for now)
        push!(result_rows, (
            radius          = g.radius[1],
            n_rotors        = g.n_rotors[1],
            spacing         = g.spacing[1],
            profile         = g.profile[1],
            elevation       = g.elevation[1],
            mean_anchor_tension = mean_t,
            tension_per_kg  = mean_t / mass_total,
            tension_cv      = cv_t,
            max_tension     = maximum(tensions),
            min_tension     = minimum(tensions),
        ))
    end
    return DataFrame(result_rows)
end

# ── Pareto filter ─────────────────────────────────────────────────────────────

"""
    pareto_front(df::DataFrame, x_col::Symbol, y_col::Symbol; sense=(:max,:max)) -> DataFrame

Return Pareto-optimal rows from `df` for the 2-objective problem defined by
`x_col` and `y_col`. `sense` controls optimisation direction: `:max` for
\"more is better\", `:min` for \"less is better\".

Default: maximise both objectives (e.g. maximise tension and tension_per_kg).
"""
function pareto_front(df::DataFrame, x_col::Symbol, y_col::Symbol;
                       sense=(:max, :max))
    rows = collect(eachrow(df))
    xs = [r[x_col] for r in rows]
    ys = [r[y_col] for r in rows]

    # Flip sign for minimisation objectives
    sx = sense[1] == :min ? -1.0 : 1.0
    sy = sense[2] == :min ? -1.0 : 1.0

    pareto_mask = trues(length(rows))
    for i in 1:length(rows)
        for j in 1:length(rows)
            if i != j && pareto_mask[i]
                if sx * xs[j] >= sx * xs[i] && sy * ys[j] >= sy * ys[i] &&
                   (sx * xs[j] > sx * xs[i] || sy * ys[j] > sy * ys[i])
                    pareto_mask[i] = false
                end
            end
        end
    end

    return df[pareto_mask, :]
end

export parameter_sweep, compute_figures_of_merit, pareto_front
export uniform_tilt, top_draggy_tilt, bottom_lifty_tilt, graded_tilt
