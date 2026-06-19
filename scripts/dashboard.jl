#!/usr/bin/env julia
# scripts/dashboard.jl — Coaxial Autogyro Stacking interactive dashboard
#
# Usage:
#   julia --project=. scripts/dashboard.jl

using Pkg; Pkg.activate(dirname(@__DIR__))
using CoaxialAutogyroStacking
using GLMakie
using Observables
using Printf

GLMakie.activate!()

# ═══════════════════════════════════════════════════════
# State
# ═══════════════════════════════════════════════════════

n_rotors       = Observable(3)
wind_speed     = Observable(8.0)
elevation      = Observable(55.0)
rotor_radius   = Observable(1.5)
pitch_global   = Observable(5.0)
line_diam      = Observable(0.004)
section_len    = Observable(10.0)
turbulence     = Observable(false)
time_t         = Observable(0.0)
pitch_offsets  = Observable(fill(0.0, 6))
kite_spec_idx  = Observable(1)

rho, g = 1.225, 9.81

const KITE_SPECS = [
    (name = "v5 Octagon (871 W/kg)", factor_trpt = 44.4),
    (name = "Canonical 5-line (568 W/kg)", factor_trpt = 28.9),
]

# ═══════════════════════════════════════════════════════
# Helpers
# ═══════════════════════════════════════════════════════

function build_stack(n, r, diam, slen, elev, pg, offs)
    n = max(1, n)
    rotors = AutogyroRotor[]
    for i in 1:n
        po = i <= length(offs) ? offs[i] : 0.0
        push!(rotors, AutogyroRotor(r, 0.05, 4, 0.15, pg + po, 0.0, 5.0))
    end
    # Rotors terminate the line at the top — no free-end section.
    # Sections: between each rotor pair, then bottom rotor → anchor.
    section_lens = fill(slen, n)
    AutogyroStack(rotors, section_lens, diam, elev)
end

turbulent_wind(v, t, on) = on ? v * (1.0 + 0.08*sin(2π*t/8.0) + 0.05*sin(2π*t/2.3) + 0.03*sin(2π*t/0.7)) : v

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

fig = Figure(size=(1400, 1050), fontsize=12)

ax_side = Axis(fig[1, 1],
    title="Kite Line — Side View",
    xlabel="Horizontal (m)", ylabel="Height (m)",
    aspect=DataAspect(), limits=(-5, 80, -3, 70))

ax_tens = Axis(fig[1, 2],
    title="Tension Profile Along Line",
    xlabel="Position (m)", ylabel="Tension (N)")

# HUD — fixed-height to prevent overflow into controls
hud = Label(fig[2, 1:2], "Loading...",
    fontsize=11, halign=:left, justification=:left,
    tellwidth=false, tellheight=true)
rowsize!(fig.layout, 2, Auto(200))  # reserve ~200px for HUD

# Controls — compact
ctls = fig[3, 1:2] = GridLayout()
rowsize!(fig.layout, 3, Relative(0.20))

sliders = SliderGrid(ctls[1, 1:7],
    (label="Wind", range=3.0:0.5:20.0, startvalue=8.0),
    (label="Elev", range=10.0:1.0:80.0, startvalue=55.0),
    (label="N", range=1:6, startvalue=3),
    (label="R (m)", range=0.5:0.1:3.0, startvalue=1.5),
    (label="Pitch", range=-20.0:1.0:30.0, startvalue=5.0),
    (label="Dia", range=2.0:1.0:12.0, startvalue=4.0),
    (label="Sec", range=5.0:1.0:30.0, startvalue=10.0),
)

connect!(wind_speed, sliders.sliders[1].value)
connect!(elevation, sliders.sliders[2].value)
connect!(n_rotors, sliders.sliders[3].value)
connect!(rotor_radius, sliders.sliders[4].value)
connect!(pitch_global, sliders.sliders[5].value)
on(sliders.sliders[6].value) do v; line_diam[] = v / 1000.0; end
connect!(section_len, sliders.sliders[7].value)

toggle_turb = Makie.Toggle(ctls[2, 1], active=false)
Label(ctls[2, 1, Top()], "Turbulence", fontsize=11)
connect!(turbulence, toggle_turb.active)

toggle_spec = Makie.Toggle(ctls[2, 2], active=true)
spec_lbl = Label(ctls[2, 2, Top()], KITE_SPECS[1].name, fontsize=10)
on(toggle_spec.active) do a
    kite_spec_idx[] = a ? 1 : 2
    spec_lbl.text = KITE_SPECS[kite_spec_idx[]].name
end

roff_sliders = Makie.Slider[]
roff_labels  = Label[]
for i in 1:6
    lbl = Label(ctls[2, 2+i, Top()], "R$(i)", fontsize=9)
    sl = Makie.Slider(ctls[2, 2+i], range=-15.0:0.5:15.0, value=0.0)
    push!(roff_labels, lbl); push!(roff_sliders, sl)
    lbl.visible = i <= 3
    on(sl.value) do v
        offs = deepcopy(pitch_offsets[])
        offs[i] = v; pitch_offsets[] = offs
    end
end

btn_launch = Makie.Button(ctls[3, 1], label="Launch", fontsize=12)
btn_cruise = Makie.Button(ctls[3, 2], label="Cruise", fontsize=12)
btn_land   = Makie.Button(ctls[3, 3], label="Land", fontsize=12)
btn_opt    = Makie.Button(ctls[3, 4], label="Optimize", fontsize=12)
btn_reset  = Makie.Button(ctls[3, 5], label="Reset", fontsize=12)

function set_scenario(w, e, n, r, p, d, sl, spec)
    sliders.sliders[1].value[] = w
    sliders.sliders[2].value[] = e
    sliders.sliders[3].value[] = n
    sliders.sliders[4].value[] = r
    sliders.sliders[5].value[] = p
    sliders.sliders[6].value[] = d
    sliders.sliders[7].value[] = sl
    toggle_turb.active[] = false
    toggle_spec.active[] = spec
    for s in roff_sliders; s.value[] = 0.0; end
end

on(btn_launch.clicks) do _; set_scenario(6.0, 30.0, 2, 1.5, 15.0, 4.0, 10.0, true); end
on(btn_cruise.clicks) do _; set_scenario(8.0, 55.0, 3, 1.5, 5.0, 4.0, 10.0, true); end
on(btn_land.clicks)   do _; set_scenario(5.0, 75.0, 3, 1.5, -10.0, 4.0, 10.0, true); end
on(btn_opt.clicks) do _
    stk = build_stack(n_rotors[], rotor_radius[], line_diam[],
                      section_len[], elevation[], pitch_global[], pitch_offsets[])
    opts = optimal_pitches(stk, rho, wind_speed[])
    if length(opts) >= 1; sliders.sliders[5].value[] = opts[1]; end
    for s in roff_sliders; s.value[] = 0.0; end
end
on(btn_reset.clicks) do _; set_scenario(8.0, 55.0, 3, 1.5, 5.0, 4.0, 10.0, true); end

on(n_rotors) do n
    for i in 1:6; roff_labels[i].visible = i <= n; end
end

# ═══════════════════════════════════════════════════════
# Drawing
# ═══════════════════════════════════════════════════════

function draw_side_view!(ax, n, rad, diam, slen, elev, v_wind, pg, offs)
    empty!(ax)
    n = max(1, n)
    sec_lens = vcat(slen, fill(slen, n))
    stk = build_stack(n, rad, diam, slen, elev, pg, offs)
    profile = stack_tension_profile(stk, rho, v_wind)
    max_t = max(maximum(abs, profile), 1.0)
    total_len = sum(sec_lens)  # line terminates at top rotor — no free-end section
    er = deg2rad(elev)

    lines!(ax, [Point2f(-3, 0), Point2f(total_len*cos(er)+3, 0)],
           color=:gray80, linewidth=1, linestyle=:dash)
    # Tension-colored line segments — draw anchor up to top rotor
    # No free-end section: line terminates at topmost rotor
    cum = 0.0
    for k in n:-1:1
        seg_start = Point2f(cum * cos(er), cum * sin(er))
        seg_end   = Point2f((cum + sec_lens[k]) * cos(er), (cum + sec_lens[k]) * sin(er))
        t_norm = clamp(abs(profile[k+1]) / max_t, 0, 1)
        col = RGBf(t_norm, 0.15, 1 - t_norm)
        lines!(ax, [seg_start, seg_end], color=col, linewidth=2.5 + 2 * t_norm)
        cum += sec_lens[k]
    end
    # Rotor disks — R1 at top (terminates the line), Rn nearest anchor
    cum = 0.0  # start at top rotor position
    for i in 1:n
        cx, cy = cum*cos(er), cum*sin(er)
        rx, ry = rad, max(rad*sind(elev), 0.08)
        θs = range(0, 2π, length=80)
        ex, ey = cx .+ rx*cos.(θs), cy .+ ry*sin.(θs)
        F_line, _, _, _, _ = rotor_force_along_line(stk.rotors[i], rho, v_wind, elev)
        tn = clamp(abs(F_line)/max_t, 0, 1)
        col = RGBf(tn, 0.2, 1-tn)
        poly!(ax, Point2f.(ex, ey), color=(col, 0.25), strokecolor=col, strokewidth=2.5)
        scatter!(ax, Point2f(cx, cy), color=col, markersize=10)
        text!(ax, "R$i", position=Point2f(cx-1.5, cy+rad+1.0),
              fontsize=12, color=:black, align=(:center, :bottom))
        if i < n
            cum += sec_lens[i+1]  # section between R_i and R_{i+1}
        end
    end

    scatter!(ax, Point2f(0, 0), color=:saddlebrown, markersize=15, marker=:rect)
    text!(ax, "[anchor]", position=Point2f(-4, -2), fontsize=11, color=:saddlebrown)

    wxa, wya = total_len*cos(er)/2, total_len*sin(er)/2 + 5
    arrows2d!(ax, [Point2f(wxa-6, wya)], [Vec2f(10, 0)],
              color=:steelblue, shaftwidth=2.5, tipwidth=12, tiplength=12)
    text!(ax, "$(round(v_wind,digits=1)) m/s",
          position=Point2f(wxa+5, wya-1.5), fontsize=11, color=:steelblue)
end

function draw_tension_profile!(ax, n, rad, diam, slen, elev, v_wind, pg, offs)
    empty!(ax)
    stk = build_stack(n, rad, diam, slen, elev, pg, offs)
    profile = stack_tension_profile(stk, rho, v_wind)
    # profile[1]=free end (~0), profile[end]=anchor (max)
    # Plot anchor at pos=0, free end at pos=n*slen
    profile_rev = reverse(profile)
    pos = Float64[]; cum = 0.0
    for i in 1:length(profile_rev)
        push!(pos, cum); if i <= n; cum += slen; end
    end
    colors = [p>=0 ? RGBf(0.2,0.7,0.3) : RGBf(0.9,0.2,0.2) for p in profile_rev]
    barplot!(ax, pos, profile_rev, color=colors, width=slen*0.8, strokewidth=1, strokecolor=:gray50)
    hlines!(ax, [0.0], color=:gray50, linestyle=:dash, linewidth=1)
    # Rotor positions: anchor→free end, rotor i is at i*slen from anchor
    cum_m = slen
    for i in 1:n
        vlines!(ax, [cum_m], color=:gray60, linestyle=:dot, linewidth=1)
        # profile_rev[i+1] = tension at rotor i position (counting from anchor)
        text!(ax, "R$i", position=Point2f(cum_m, profile_rev[i+1]),
              fontsize=10, color=:black, align=(:center, :bottom), offset=(0,5))
        cum_m += slen
    end
end

function build_hud(n, rad, diam, slen, elev, v_wind, pg, offs, turbulence_on, spec_idx)
    stk = build_stack(n, rad, diam, slen, elev, pg, offs)
    profile = stack_tension_profile(stk, rho, v_wind)
    fa = profile[end]
    lines = String[]
    push!(lines, "=== COAXIAL AUTOGYRO STACK ===")
    push!(lines, @sprintf("Wind: %.1f m/s %s  |  Elev: %.0f deg  |  Line: %.1f mm  |  Span: ~%.0f m",
           v_wind, turbulence_on ? "(TURB)" : "steady", elev, diam*1000, n*slen))
    tl, td = 0.0, 0.0
    for i in 1:n
        rot = stk.rotors[i]
        Fl, Flift, Fdrag, cl, cd = rotor_force_along_line(rot, rho, v_wind, elev)
        tl += Flift; td += Fdrag
        push!(lines, @sprintf("R%d  a=%.1f deg  CL=%.2f  CD=%.2f  F_line=%.0f N", i,
               effective_alpha(rot, elev), cl, cd, Fl))
    end
    push!(lines, repeat("-", 50))
    push!(lines, @sprintf("Anchor: %.0f N  |  L/D: %.2f  |  Lift: %.0f N  |  Drag: %.0f N",
           fa, td>0 ? tl/td : Inf, tl, td))
    p_trpt, p_yp, p_yn, sn = power_report(fa, v_wind, spec_idx)
    push!(lines, @sprintf("TRPT: %.1f kW  |  Yo-yo peak: %.1f kW  |  Yo-yo net: %.1f kW (77%%)",
           p_trpt, p_yp, p_yn))
    push!(lines, @sprintf("Tension: %.0f–%.0f N  |  Spec: %s",
           minimum(profile), maximum(profile), sn))
    if count(<(0), profile) > 0
        push!(lines, "  !! segments in compression")
    end
    return join(lines, "\n")
end

function update_plots(_...)
    n, r, d, s, e, pg, ot, si, offs =
        n_rotors[], rotor_radius[], line_diam[], section_len[],
        elevation[], pitch_global[], turbulence[], kite_spec_idx[], pitch_offsets[]
    v = turbulent_wind(wind_speed[], time_t[], ot)
    draw_side_view!(ax_side, n, r, d, s, e, v, pg, offs)
    draw_tension_profile!(ax_tens, n, r, d, s, e, v, pg, offs)
    hud.text = build_hud(n, r, d, s, e, v, pg, offs, ot, si)
end

onany(wind_speed, elevation, n_rotors, rotor_radius, pitch_global,
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
println("  GLMakie window should be open. Close window to exit.")
println("="^60)

while true; sleep(1); end
