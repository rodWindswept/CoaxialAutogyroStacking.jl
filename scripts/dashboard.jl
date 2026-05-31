#!/usr/bin/env julia
# scripts/dashboard.jl — Coaxial Autogyro Stacking interactive dashboard
# WGLMakie browser-based: side-view + tension profile + HUD + scenarios + turbulence
#
# Usage:
#   julia --project=. scripts/dashboard.jl
#   → Opens in browser at http://localhost:PORT

using Pkg; Pkg.activate(dirname(@__DIR__))
using CoaxialAutogyroStacking
using WGLMakie
using Observables
using Printf
using Bonito

WGLMakie.activate!()

# ═══════════════════════════════════════════════════════════════════════
# Reactive state
# ═══════════════════════════════════════════════════════════════════════

n_rotors       = Observable(3)
wind_speed     = Observable(8.0)
elevation      = Observable(55.0)
rotor_radius   = Observable(1.5)
pitch_global   = Observable(5.0)
line_diam      = Observable(0.004)      # m
section_len    = Observable(10.0)       # m
turbulence     = Observable(false)
time_t         = Observable(0.0)

# Per-rotor pitch offsets
pitch_offsets  = Observable(fill(0.0, 6))

rho = 1.225
g   = 9.81

# ═══════════════════════════════════════════════════════════════════════
# Helpers
# ═══════════════════════════════════════════════════════════════════════

function build_stack(n, r, diam, s_len, elev, pg, offsets)
    n = max(1, n)
    rotors = AutogyroRotor[]
    for i in 1:n
        p_off = i <= length(offsets) ? offsets[i] : 0.0
        push!(rotors, AutogyroRotor(r, 0.05, 4, 0.15, pg + p_off, 5.0))
    end
    AutogyroStack(rotors, vcat(s_len, fill(s_len, n)), diam, elev)
end

turbulent_wind(v, t, on) = on ? v * (1.0 + 0.08*sin(2π*t/8.0) + 0.05*sin(2π*t/2.3) + 0.03*sin(2π*t/0.7)) : v

# ═══════════════════════════════════════════════════════════════════════
# Dashboard figure
# ═══════════════════════════════════════════════════════════════════════

fig = Figure(size=(1400, 950), fontsize=13)

# — Side view —
ax_side = Axis(fig[1, 1],
    title="Kite Line — Side View",
    xlabel="Horizontal (m)", ylabel="Height (m)",
    aspect=DataAspect(),
    limits=(-5, 80, -3, 70))

# — Tension profile —
ax_tens = Axis(fig[1, 2],
    title="Tension Profile Along Line",
    xlabel="Position (m)", ylabel="Tension (N)")

# — HUD —
hud = Label(fig[2, 1:2], "Loading...",
    fontsize=13, halign=:left, justification=:left,
    tellwidth=false, tellheight=true)

# — Controls —
ctls = fig[3, 1:2] = GridLayout()
rowsize!(fig.layout, 3, Relative(0.25))  # Controls row gets 25% height

# Sliders: Bonito/WGLMakie — Slider(range; value=start)
function add_slider(grid, row, col, label, range, start_val, fmt)
    lbl = Label(grid[row, col, Top()], label, fontsize=11)
    sl = Slider(range; value=start_val)
    grid[row, col] = sl
    val_lbl = Label(grid[row, col, Bottom()], Printf.format(Printf.Format(fmt), start_val), fontsize=10)
    on(sl.value) do v
        val_lbl.text = Printf.format(Printf.Format(fmt), v)
    end
    return sl
end

s_wind     = add_slider(ctls, 1, 1, "Wind (m/s)", 3.0:0.5:20.0, 8.0, "%.1f")
s_elev     = add_slider(ctls, 1, 2, "Elevation (°)", 10.0:1.0:80.0, 55.0, "%.0f")
s_nrot     = add_slider(ctls, 1, 3, "Rotors", 1:6, 3, "%d")
s_rad      = add_slider(ctls, 1, 4, "Radius (m)", 0.5:0.1:3.0, 1.5, "%.1f")
s_pitch    = add_slider(ctls, 1, 5, "Pitch (°)", -20.0:1.0:30.0, 5.0, "%.0f")
s_diam     = add_slider(ctls, 1, 6, "Line Ø (mm)", 2.0:1.0:12.0, 4.0, "%.0f")
s_slen     = add_slider(ctls, 1, 7, "Section (m)", 5.0:1.0:30.0, 10.0, "%.0f")

# Toggle + scenario buttons
toggle_w = Toggle(; active=false)
ctls[2, 1] = toggle_w
Label(ctls[2, 1, Top()], "Turbulence 🌊", fontsize=11)

# Per-rotor pitch offset sliders (shown when n_rotors changes)
pitch_offset_labels = [Label(ctls[2, 2+i], "R$(i) offset", fontsize=10) for i in 1:6]
pitch_offset_sliders = [
    Slider(-15.0:0.5:15.0; value=0.0)
    for i in 1:6
]
for i in 1:6
    ctls[2, 2+i] = pitch_offset_sliders[i]
end
[pitch_offset_labels[i].visible = i <= 3 for i in 1:6]

scenario_row = ctls[3, 1:7] = GridLayout()
btn_launch  = Button(scenario_row[1, 1], label="🚀 Launch",  fontsize=12)
btn_cruise  = Button(scenario_row[1, 2], label="✈️ Cruise",  fontsize=12)
btn_land    = Button(scenario_row[1, 3], label="🛬 Land",    fontsize=12)
btn_opt     = Button(scenario_row[1, 4], label="🎯 Optimize", fontsize=12)
btn_reset   = Button(scenario_row[1, 5], label="🔄 Reset",   fontsize=12)

# Connect observables
connect!(wind_speed, s_wind.value)
connect!(elevation, s_elev.value)
connect!(n_rotors, s_nrot.value)
connect!(rotor_radius, s_rad.value)
connect!(pitch_global, s_pitch.value)
connect!(line_diam, s_diam.value)
connect!(section_len, s_slen.value)
connect!(turbulence, toggle_w.active)

# Update line_diam from mm to m
on(s_diam.value) do v
    line_diam[] = v / 1000.0
end

# Show/hide per-rotor pitch controls based on n_rotors
on(n_rotors) do n
    for i in 1:6
        pitch_offset_labels[i].visible = i <= n
    end
end

# Scenario buttons
on(btn_launch.clicks) do _
    s_elev.value[] = 30.0
    s_pitch.value[] = 15.0
    s_wind.value[] = 6.0
    notify.(Ref(s_elev.value)); notify.(Ref(s_pitch.value)); notify.(Ref(s_wind.value))
end
on(btn_cruise.clicks) do _
    s_elev.value[] = 55.0
    s_pitch.value[] = 5.0
    s_wind.value[] = 8.0
    notify.(Ref(s_elev.value)); notify.(Ref(s_pitch.value)); notify.(Ref(s_wind.value))
end
on(btn_land.clicks) do _
    s_elev.value[] = 75.0
    s_pitch.value[] = -10.0
    s_wind.value[] = 5.0
    notify.(Ref(s_elev.value)); notify.(Ref(s_pitch.value)); notify.(Ref(s_wind.value))
end
on(btn_opt.clicks) do _
    stk = build_stack(n_rotors[], rotor_radius[], line_diam[],
                      section_len[], elevation[], pitch_global[], pitch_offsets[])
    opts = optimal_pitches(stk, rho, wind_speed[])
    if length(opts) >= 1
        s_pitch.value[] = opts[1]
        notify(s_pitch.value)
    end
    for i in 1:min(length(opts), 6)
        pitch_offset_sliders[i].value[] = 0.0
    end
    println("Optimized pitches: ", round.(opts, digits=1))
end
on(btn_reset.clicks) do _
    s_wind.value[]      = 8.0
    s_elev.value[]      = 55.0
    s_nrot.value[]      = 3
    s_rad.value[]       = 1.5
    s_pitch.value[]     = 5.0
    s_diam.value[]      = 4.0
    s_slen.value[]      = 10.0
    toggle_w.active[]   = false
    for i in 1:6
        pitch_offset_sliders[i].value[] = 0.0
    end
    notify.(Ref(s_wind.value)); notify.(Ref(s_elev.value))
    notify.(Ref(s_nrot.value)); notify.(Ref(s_rad.value))
    notify.(Ref(s_pitch.value)); notify.(Ref(s_diam.value))
    notify.(Ref(s_slen.value))
end

# ═══════════════════════════════════════════════════════════════════════
# Drawing functions
# ═══════════════════════════════════════════════════════════════════════

function draw_side_view!(ax, n, rad, diam, slen, elev, v_wind, pg, offsets)
    empty!(ax)
    n = max(1, n)
    sec_lens = vcat(slen, fill(slen, n))
    stk = build_stack(n, rad, diam, slen, elev, pg, offsets)
    profile = stack_tension_profile(stk, rho, v_wind)
    max_t = max(maximum(abs, profile), 1.0)

    total_len = sum(sec_lens)
    er = deg2rad(elev)

    # Anchor at origin, free end up-right
    anchor  = Point2f(0, 0)
    top     = Point2f(total_len * cos(er), total_len * sin(er))

    # Ground line
    lines!(ax, [Point2f(-3, 0), Point2f(total_len*cos(er)+3, 0)],
           color=:gray80, linewidth=1, linestyle=:dash)

    # Tension-colored line segments
    cum = 0.0
    for k in 1:(n+1)
        seg_start = Point2f(cum * cos(er), cum * sin(er))
        seg_end   = Point2f((cum + sec_lens[k]) * cos(er), (cum + sec_lens[k]) * sin(er))
        t_norm = clamp(abs(profile[k]) / max_t, 0, 1)
        col = RGBf(t_norm, 0.15, 1 - t_norm)
        lines!(ax, [seg_start, seg_end], color=col, linewidth=2.5 + 2 * t_norm)
        cum += sec_lens[k]
    end

    # Rotor disks
    cum = slen
    for i in 1:n
        cx = cum * cos(er)
        cy = cum * sin(er)

        # Disk ellipse in side view
        rx = rad
        ry = max(rad * sind(elev), 0.08)
        θs = range(0, 2π, length=80)
        ex = cx .+ rx * cos.(θs)
        ey = cy .+ ry * sin.(θs)

        F_line, _, _, _, _ = rotor_force_along_line(stk.rotors[i], rho, v_wind, elev)
        t_norm = clamp(abs(F_line) / max_t, 0, 1)
        col = RGBf(t_norm, 0.2, 1 - t_norm)

        # Fill disk (semi-transparent)
        poly!(ax, Point2f.(ex, ey), color=(col, 0.25), strokecolor=col, strokewidth=2.5)

        # Center dot + label
        scatter!(ax, Point2f(cx, cy), color=col, markersize=10)
        text!(ax, "R$i", position=Point2f(cx - 1.5, cy + rad + 1.0),
              fontsize=12, color=:black, align=(:center, :bottom))

        cum += slen
    end

    # Anchor marker
    scatter!(ax, Point2f(0, 0), color=:saddlebrown, markersize=15, marker=:rect)
    text!(ax, "⚓ anchor", position=Point2f(-4, -2), fontsize=11, color=:saddlebrown)

    # Wind arrow
    wx, wy = total_len*cos(er)/2, total_len*sin(er)/2 + 5
    arrows!(ax, [Point2f(wx - 6, wy)], [Point2f(wx + 4, wy)],
            color=:steelblue, linewidth=2.5, arrowsize=12)
    text!(ax, "$(round(v_wind,digits=1)) m/s",
          position=Point2f(wx + 5, wy - 1.5),
          fontsize=11, color=:steelblue)
end

function draw_tension_profile!(ax, n, rad, diam, slen, elev, v_wind, pg, offsets)
    empty!(ax)
    stk = build_stack(n, rad, diam, slen, elev, pg, offsets)
    profile = stack_tension_profile(stk, rho, v_wind)

    positions = Float64[]
    cum = 0.0
    for i in 1:length(profile)
        push!(positions, cum)
        if i <= n; cum += slen; end
    end

    # Stacked bar: line-drag portion + rotor contribution
    colors = [p >= 0 ? RGBf(0.2, 0.7, 0.3) : RGBf(0.9, 0.2, 0.2) for p in profile]
    barplot!(ax, positions, profile, color=colors, width=slen * 0.8, strokewidth=1, strokecolor=:gray50)

    hlines!(ax, [0.0], color=:gray50, linestyle=:dash, linewidth=1)

    # Annotate rotor positions
    cum_m = slen
    for i in 1:n
        vlines!(ax, [cum_m], color=:gray60, linestyle=:dot, linewidth=1)
        text!(ax, "R$i", position=Point2f(cum_m, profile[i+1]),
              fontsize=10, color=:black, align=(:center, :bottom), offset=(0, 5))
        cum_m += slen
    end
end

function build_hud(n, rad, diam, slen, elev, v_wind, pg, offsets, turbulence_on)
    stk = build_stack(n, rad, diam, slen, elev, pg, offsets)
    profile = stack_tension_profile(stk, rho, v_wind)

    lines = String[]
    push!(lines, "┌─────────────────────────────────┐")
    push!(lines, "│  WIND & LINE                     │")
    push!(lines, @sprintf("│  Wind:  %5.1f m/s  %-12s │", v_wind,
           turbulence_on ? "🌊 TURBULENT" : "💨 steady"))
    push!(lines, @sprintf("│  Elev:  %5.0f°                    │", elev))
    push!(lines, @sprintf("│  Line Ø: %4.1f mm  │  Length: %5.0f m │", diam*1000, (n+1)*slen))
    push!(lines, "├─────────────────────────────────┤")

    push!(lines, @sprintf("│  ROTORS (%d)                       │", n))
    total_l, total_d = 0.0, 0.0
    for i in 1:n
        rot = stk.rotors[i]
        Fl, F_l, F_d, cl, cd = rotor_force_along_line(rot, rho, v_wind, elev)
        total_l += F_l; total_d += F_d
        α = effective_alpha(rot, elev)
        push!(lines, @sprintf("│  R%d α=%5.1f° CL=%4.2f CD=%4.2f F=%6.0f N │",
               i, α, cl, cd, Fl))
    end

    push!(lines, "├─────────────────────────────────┤")
    push!(lines, "│  SYSTEM                          │")
    push!(lines, @sprintf("│  Anchor tension: %8.0f N     │", profile[end]))
    ld = total_d > 0 ? total_l / total_d : Inf
    push!(lines, @sprintf("│  L/D: %6.2f  Lift: %6.0f N    │", ld, total_l))
    push!(lines, @sprintf("│  Drag: %6.0f N                   │", total_d))

    push!(lines, "├─────────────────────────────────┤")
    push!(lines, "│  TENSION PROFILE                 │")
    push!(lines, @sprintf("│  Min: %8.0f  Max: %8.0f N │",
           minimum(profile), maximum(profile)))
    n_neg = count(<(0), profile)
    if n_neg > 0
        push!(lines, @sprintf("│  ⚠ %d segment(s) in compression    │", n_neg))
    end
    push!(lines, "└─────────────────────────────────┘")

    return join(lines, "\n")
end

# ═══════════════════════════════════════════════════════════════════════
# Reactivity: redraw on any parameter change
# ═══════════════════════════════════════════════════════════════════════

function update_all(_...)
    n  = n_rotors[]
    r  = rotor_radius[]
    d  = line_diam[]
    s  = section_len[]
    e  = elevation[]
    pg = pitch_global[]
    on_turb = turbulence[]

    # Collect per-rotor offsets
    offsets_vec = Float64[pitch_offset_sliders[i].value[] for i in 1:6]
    pitch_offsets[] = offsets_vec

    v = turbulent_wind(wind_speed[], time_t[], on_turb)

    # Redraw
    draw_side_view!(ax_side, n, r, d, s, e, v, pg, offsets_vec)
    draw_tension_profile!(ax_tens, n, r, d, s, e, v, pg, offsets_vec)
    hud.text = build_hud(n, r, d, s, e, v, pg, offsets_vec, on_turb)
end

# Connect all sliders + toggle
onany(wind_speed, elevation, n_rotors, rotor_radius, pitch_global,
      line_diam, section_len, turbulence) do args...
    update_all()
end

# Connect per-rotor sliders
for i in 1:6
    on(pitch_offset_sliders[i].value) do _
        update_all()
    end
end

# ═══════════════════════════════════════════════════════════════════════
# Turbulence animation timer
# ═══════════════════════════════════════════════════════════════════════

@async begin
    while true
        sleep(0.1)
        if turbulence[]
            time_t[] = time_t[] + 0.1
            update_all()
        end
    end
end

# Initial draw
update_all()

# ═══════════════════════════════════════════════════════════════════════
# Launch
# ═══════════════════════════════════════════════════════════════════════

println("="^60)
println("  Coaxial Autogyro Stacking — Interactive Dashboard")
println("  Opening in browser...")
println("="^60)

# Display the figure — Bonito will serve it
Page(exportable=true, optimize=false)
