#!/usr/bin/env julia
# scripts/dashboard.jl — Coaxial Autogyro Stacking interactive dashboard
#
# Polygon chain geometry with BEM v2.1 aerodynamics.
# Segment angles are computed from force equilibrium, not set by slider.
#
# Usage:
#   julia --project=. scripts/dashboard.jl

using Pkg; Pkg.activate(@__DIR__)
Pkg.develop(path=joinpath(@__DIR__, ".."))
using CoaxialAutogyroStacking
using GLMakie
using Observables
using Printf

GLMakie.activate!()

# ═══════════════════════════════════════════════════════
# State — only parameters you can physically control
# ═══════════════════════════════════════════════════════

n_rotors       = Observable(3)
wind_speed     = Observable(8.0)
rotor_radius   = Observable(1.5)
pitch_global   = Observable(5.0)
line_diam      = Observable(0.004)
section_len    = Observable(10.0)
turbulence     = Observable(false)
time_t         = Observable(0.0)
pitch_offsets  = Observable(fill(0.0, 6))

rho, g = 1.225, 9.81

const KITE_SPECS = [
    (name = "v5 Octagon (871 W/kg)", factor_trpt = 44.4),
    (name = "Canonical 5-line (568 W/kg)", factor_trpt = 28.9),
]
kite_spec_idx = Observable(1)

# ═══════════════════════════════════════════════════════
# Physics — polygon solver with BEM
# ═══════════════════════════════════════════════════════

function build_stack(n, r, diam, slen, pg, offs)
    n = max(1, n)
    rotors = AutogyroRotor[]
    for i in 1:n
        po = i <= length(offs) ? offs[i] : 0.0
        # 2 blades, 0.15m chord — matches BEM sweep config
        push!(rotors, AutogyroRotor(r, 0.05, 2, 0.15, pg + po, 0.0, 5.0))
    end
    section_lens = fill(slen, n)
    AutogyroStack(rotors, section_lens, diam, 45.0)  # anchor angle: initial guess
end

function solve_stack(n, r, diam, slen, pg, offs, v_wind)
    stk = build_stack(n, r, diam, slen, pg, offs)
    # Polygon solver computes per-segment angles from force equilibrium.
    # The anchor_angle_deg (45°) is just an initial guess — the solver
    # refines all segment angles including the bottom one.
    θ, T, F = solve_polygon_angles(stk.rotors, stk.section_lengths, 45.0, rho, v_wind)
    return stk, θ, T, F
end

turbulent_wind(v, t, on) = on ? v * (1.0 + 0.08*sin(2pi*t/8.0) + 0.05*sin(2pi*t/2.3) + 0.03*sin(2pi*t/0.7)) : v

function power_report(f_anchor, v_wind, spec_idx)
    spec = KITE_SPECS[spec_idx]
    p_trpt      = f_anchor * spec.factor_trpt / 1000
    p_yoyo_peak = f_anchor * (v_wind / 3.0) / 1000
    p_yoyo_net  = p_yoyo_peak * 0.77
    return (p_trpt, p_yoyo_peak, p_yoyo_net, spec.name)
end

# ═══════════════════════════════════════════════════════
# Figure
# ═══════════════════════════════════════════════════════

fig = Figure(size=(1400, 1100), fontsize=12)

ax_side = Axis(fig[1, 1],
    title="Kite Line — Side View (Polygon Chain, BEM v2.1)",
    xlabel="Horizontal (m)", ylabel="Height (m)",
    aspect=DataAspect(), limits=(-5, 80, -3, 70))

ax_tens = Axis(fig[1, 2],
    title="Tension Profile Along Line",
    xlabel="Distance along line from anchor (m)", ylabel="Tension (N)")

# HUD — more height to avoid overlap with controls
hud = Label(fig[2, 1:2], "Loading...",
    fontsize=10, halign=:left, justification=:left,
    tellwidth=false, tellheight=true)
rowsize!(fig.layout, 2, Auto(280))

# Controls — no elevation slider, line angle is computed
ctls = fig[3, 1:2] = GridLayout()
rowsize!(fig.layout, 3, Relative(0.25))

sliders = SliderGrid(ctls[1, 1:6],
    (label="Wind (m/s)", range=3.0:0.5:20.0, startvalue=8.0),
    (label="N rotors",    range=1:6, startvalue=4),
    (label="Radius (m)",  range=0.5:0.1:3.0, startvalue=3.0),
    (label="Tilt (deg)",  range=-20.0:1.0:30.0, startvalue=15.0),
    (label="Dia (mm)",    range=2.0:1.0:12.0, startvalue=4.0),
    (label="Spacing (m)", range=5.0:1.0:30.0, startvalue=15.0),
)

connect!(wind_speed, sliders.sliders[1].value)
connect!(n_rotors, sliders.sliders[2].value)
connect!(rotor_radius, sliders.sliders[3].value)
connect!(pitch_global, sliders.sliders[4].value)
on(sliders.sliders[5].value) do v; line_diam[] = v / 1000.0; end
connect!(section_len, sliders.sliders[6].value)

toggle_turb = Makie.Toggle(ctls[2, 2], active=false)
Label(ctls[2, 1], "Turbulence", fontsize=11, halign=:right)
connect!(turbulence, toggle_turb.active)

toggle_spec = Makie.Toggle(ctls[2, 4], active=true)
spec_lbl = Label(ctls[2, 3], KITE_SPECS[1].name, fontsize=10, halign=:right)
on(toggle_spec.active) do a
    kite_spec_idx[] = a ? 1 : 2
    spec_lbl.text = KITE_SPECS[kite_spec_idx[]].name
end

roff_sliders = Makie.Slider[]
roff_labels  = Label[]
for i in 1:6
    lbl = Label(ctls[3, i], "R$(i)", fontsize=9, halign=:right)
    sl = Makie.Slider(ctls[3, i], range=-15.0:0.5:15.0, value=0.0, width=80)
    push!(roff_labels, lbl); push!(roff_sliders, sl)
    lbl.visible = i <= n_rotors[]
    on(sl.value) do v
        offs = deepcopy(pitch_offsets[])
        offs[i] = v; pitch_offsets[] = offs
    end
end

btn_launch = Makie.Button(ctls[4, 1], label="Launch", fontsize=12)
btn_cruise = Makie.Button(ctls[4, 2], label="Cruise", fontsize=12)
btn_land   = Makie.Button(ctls[4, 3], label="Land", fontsize=12)
btn_reset  = Makie.Button(ctls[4, 4], label="Reset", fontsize=12)

function set_scenario(w, n, r, p, d, sl, spec)
    sliders.sliders[1].value[] = w
    sliders.sliders[2].value[] = n
    sliders.sliders[3].value[] = r
    sliders.sliders[4].value[] = p
    sliders.sliders[5].value[] = d
    sliders.sliders[6].value[] = sl
    toggle_turb.active[] = false
    toggle_spec.active[] = spec
    for s in roff_sliders; s.value[] = 0.0; end
end

on(btn_launch.clicks) do _; set_scenario(6.0, 4, 3.0, 20.0, 4.0, 15.0, true); end
on(btn_cruise.clicks) do _; set_scenario(8.0, 4, 3.0, 15.0, 4.0, 15.0, true); end
on(btn_land.clicks)   do _; set_scenario(5.0, 4, 3.0, 5.0, 4.0, 15.0, true); end
on(btn_reset.clicks)  do _; set_scenario(8.0, 4, 3.0, 15.0, 4.0, 15.0, true); end

on(n_rotors) do n
    for i in 1:6; roff_labels[i].visible = i <= n; end
end

# ═══════════════════════════════════════════════════════
# Drawing — Side View (polygon chain, per-segment angles)
# ═══════════════════════════════════════════════════════

function draw_side_view!(ax, n, r, diam, slen, pg, offs, v_wind)
    empty!(ax)
    n = max(1, n)
    stk, θ, T, F = solve_stack(n, r, diam, slen, pg, offs, v_wind)
    max_t = max(maximum(abs, T), 1.0)

    # Build (x,y) coordinates along the polygon chain from anchor upward.
    # section_lengths[1]=R1→R2, section_lengths[n]=Rn→anchor.
    # Walk from anchor upward: anchor → Rn → R(n-1) → ... → R1.
    xs = [0.0]; ys = [0.0]
    rotor_x = zeros(n); rotor_y = zeros(n)
    for k in 1:n
        i = n - k + 1  # bottom→top: n, n-1, ..., 1
        seg_angle = θ[i]
        seg_len = stk.section_lengths[i]
        push!(xs, xs[end] + seg_len * cosd(seg_angle))
        push!(ys, ys[end] + seg_len * sind(seg_angle))
        rotor_x[i] = xs[end]
        rotor_y[i] = ys[end]
    end
    # xs[1]=anchor, xs[end]=R1 (topmost)

    # Ground
    total_x = xs[end] + 5
    lines!(ax, [Point2f(-3, 0), Point2f(total_x, 0)],
           color=:gray80, linewidth=1, linestyle=:dash)

    # Draw line segments with tension colour.
    # xs[1]=anchor, xs[k+1]=R(n-k+1). T[k+1] is tension below Rk.
    # Segment anchor→Rn uses T[end], Rn→R(n-1) uses T[n], etc.
    for k in 1:n
        t_idx = n - k + 2  # k=1: T[n+1]=anchor, k=n: T[2]=below R1
        tn = clamp(abs(T[t_idx]) / max_t, 0, 1)
        col = RGBf(tn, 0.15, 1 - tn)
        lines!(ax, [Point2f(xs[k], ys[k]), Point2f(xs[k+1], ys[k+1])],
               color=col, linewidth=2.5 + 2*tn)
    end

    # Draw rotors at their positions (R1=topmost, already in rotor_x/rotor_y)
    for i in 1:n
        seg_angle = θ[i]
        rotor = stk.rotors[i]
        cx, cy = rotor_x[i], rotor_y[i]

        # Disk ellipse
        rx, ry = r, max(r * sind(seg_angle), 0.08)
        t_vals = range(0, 2pi, length=80)
        ex, ey = cx .+ rx*cos.(t_vals), cy .+ ry*sin.(t_vals)

        _, T_thrust, _ = rotor_force_bem(rotor, rho, v_wind, seg_angle)
        F_line = T_thrust * cosd(rotor.tilt_deg)
        tn = clamp(abs(F_line) / max_t, 0, 1)
        col = RGBf(tn, 0.2, 1-tn)
        poly!(ax, Point2f.(ex, ey), color=(col, 0.25), strokecolor=col, strokewidth=2.5)
        scatter!(ax, Point2f(cx, cy), color=col, markersize=10)
        text!(ax, "R$(i)", position=Point2f(cx - 1.5, cy + r + 1.0),
              fontsize=12, color=:black, align=(:center, :bottom))
    end

    # Colour legend
    for i in 0:3
        tn = i/3
        col = RGBf(tn, 0.2, 1-tn)
        poly!(ax, Point2f[(1, 58+i*2), (3, 58+i*2), (3, 60+i*2), (1, 60+i*2)],
              color=col, strokewidth=0)
    end
    text!(ax, "0", position=Point2f(0.5, 58), fontsize=8, color=:gray50, align=(:right, :center))
    text!(ax, "$(round(Int, max_t))", position=Point2f(0.5, 64), fontsize=8, color=:gray50, align=(:right, :center))
    text!(ax, "Tension (N)", position=Point2f(0.5, 66), fontsize=9, color=:gray50, align=(:right, :center))

    # Anchor
    scatter!(ax, Point2f(0, 0), color=:saddlebrown, markersize=15, marker=:rect)
    text!(ax, "[anchor]", position=Point2f(-4, -2), fontsize=11, color=:saddlebrown)

    # Wind arrow — horizontal, positioned above mid-stack
    mx = xs[end] / 2
    my = ys[end] / 2 + 5
    arrows2d!(ax, [Point2f(mx-6, my)], [Vec2f(10, 0)],
              color=:steelblue, shaftwidth=2.5, tipwidth=12, tiplength=12)
    text!(ax, "$(round(v_wind,digits=1)) m/s",
          position=Point2f(mx+5, my-1.5), fontsize=11, color=:steelblue)
end

# ═══════════════════════════════════════════════════════
# Drawing — Tension Profile
# ═══════════════════════════════════════════════════════

function draw_tension_profile!(ax, n, r, diam, slen, pg, offs, v_wind)
    empty!(ax)
    stk, θ, T, F = solve_stack(n, r, diam, slen, pg, offs, v_wind)

    # Cumulative distance from anchor upward: anchor→Rn→R(n-1)→...→R1
    cum_dist = [0.0]
    for k in 1:n
        i = n - k + 1  # bottom→top
        push!(cum_dist, cum_dist[end] + stk.section_lengths[i])
    end
    # cum_dist[1]=anchor, cum_dist[k+1]=R(n-k+1), cum_dist[end]=R1(top)

    # T[1]=0 at top (R1), T[end]=anchor. Map to anchor→top order.
    T_anchor_top = reverse(T)  # T_anchor_top[1]=anchor tension, T_anchor_top[end]=0 at top

    # Stepped cumulative tension
    step_x = Float64[]; step_y = Float64[]
    push!(step_x, cum_dist[1]); push!(step_y, T_anchor_top[1])
    for i in 1:n
        push!(step_x, cum_dist[i+1]); push!(step_y, step_y[end])  # horizontal to rotor
        push!(step_x, cum_dist[i+1]); push!(step_y, T_anchor_top[i+1])  # drop to tension above
    end
    lines!(ax, step_x, step_y, color=:purple, linewidth=3, label="Cumulative")
    scatter!(ax, step_x, step_y, color=:purple, markersize=8)

    # Per-rotor contribution (bars)
    per_rotor = [T[i+1] - T[i] for i in 1:n]  # T: top→anchor, delta = contribution below rotor i
    bar_pos = [(cum_dist[n-i+1] + cum_dist[n-i+2]) / 2 for i in 1:n]  # anchor→top order
    barplot!(ax, bar_pos, per_rotor, color=:steelblue, width=slen*0.6,
             strokewidth=1, strokecolor=:gray50, label="Per rotor")

    # Rotor labels at their positions
    for i in 1:n
        pos = cum_dist[n-i+2]  # anchor→top: position of R(i)
        text!(ax, "R$(i)", position=Point2f(pos, T[i+1]),
              fontsize=10, color=:black, align=(:center, :bottom), offset=(0, 5))
    end

    hlines!(ax, [0.0], color=:gray50, linestyle=:dash, linewidth=1)
    axislegend(ax, position=:lt, fontsize=10)
    xlims!(ax, 0, cum_dist[end] * 1.05)
end

# ═══════════════════════════════════════════════════════
# HUD
# ═══════════════════════════════════════════════════════

function build_hud(n, r, diam, slen, pg, offs, v_wind, turbulence_on, spec_idx)
    stk, θ, T, F = solve_stack(n, r, diam, slen, pg, offs, v_wind)
    fa = T[end]
    lines = String[]
    push!(lines, "=== COAXIAL AUTOGYRO STACK (Polygon + BEM v2.1) ===")
    push!(lines, @sprintf("Wind: %.1f m/s %s  |  Line: %.1f mm  |  Span: ~%.0f m",
           v_wind, turbulence_on ? "(TURB)" : "steady", diam*1000, n*slen))

    # Per-rotor readout: segment angle, BEM force, RPM estimate
    push!(lines, "  Rotor   Seg angle   F_line     RPM      Tilt")
    push!(lines, "  ─────   ─────────   ──────    ─────    ────")
    total_lift = 0.0; total_drag = 0.0
    for i in 1:n
        rotor = stk.rotors[i]
        _, T_thrust, _ = rotor_force_bem(rotor, rho, v_wind, θ[i])
        F_line = T_thrust * cosd(rotor.tilt_deg)
        rpm = estimated_autorotation_rpm(rotor, v_wind, effective_alpha(rotor, θ[i]))
        push!(lines, @sprintf("  R%d      %5.1f°      %6.0f N   %5.0f RPM  %5.1f°",
               i, θ[i], F_line, rpm, rotor.tilt_deg))
        # Accumulate lift/drag from PCA-2 for L/D estimate
        _, fl, fd, _, _ = rotor_force_along_line(rotor, rho, v_wind, θ[i])
        total_lift += fl; total_drag += fd
    end

    push!(lines, repeat("-", 50))
    push!(lines, @sprintf("Anchor tension: %.0f N  |  L/D: %.2f  |  Lift: %.0f N  |  Drag: %.0f N",
           fa, total_drag > 0 ? total_lift/total_drag : Inf, total_lift, total_drag))
    p_trpt, p_yp, p_yn, sn = power_report(fa, v_wind, spec_idx)
    push!(lines, @sprintf("TRPT: %.1f kW  |  Yo-yo peak: %.1f kW  |  Yo-yo net: %.1f kW (77%%)",
           p_trpt, p_yp, p_yn))
    push!(lines, @sprintf("Segment angles (top→bottom): %s",
           join([@sprintf("%.1f°", θ[i]) for i in 1:n], "  ")))
    if any(<(0), T)
        push!(lines, "  !! segments in compression")
    end
    return join(lines, "\n")
end

# ═══════════════════════════════════════════════════════
# Update loop
# ═══════════════════════════════════════════════════════

function update_plots(_...)
    n, r, d, s, pg, si, offs =
        n_rotors[], rotor_radius[], line_diam[], section_len[],
        pitch_global[], kite_spec_idx[], pitch_offsets[]
    v = turbulent_wind(wind_speed[], time_t[], turbulence[])
    draw_side_view!(ax_side, n, r, d, s, pg, offs, v)
    draw_tension_profile!(ax_tens, n, r, d, s, pg, offs, v)
    hud.text = build_hud(n, r, d, s, pg, offs, v, turbulence[], si)
end

onany(wind_speed, n_rotors, rotor_radius, pitch_global,
      line_diam, section_len, turbulence, kite_spec_idx, pitch_offsets) do args...
    update_plots()
end

@async while true
    sleep(0.1)
    if turbulence[]
        time_t[] = time_t[] + 0.1
        update_plots()
    end
end

update_plots()

# ═══════════════════════════════════════════════════════
# Display — GLMakie opens in its own window
# ═══════════════════════════════════════════════════════

display(fig)

println("="^60)
println("  Coaxial Autogyro Stacking — Interactive Dashboard")
println("  Polygon chain with BEM v2.1 aerodynamics.")
println("  Segment angles are computed, not set by slider.")
println("  Close the GLMakie window to exit.")

# Block until window is closed — GLMakie scripts exit immediately otherwise
while isopen(fig.scene)
    sleep(0.1)
end
