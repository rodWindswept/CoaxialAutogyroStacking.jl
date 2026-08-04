### A Pluto.jl notebook ###
# v1.0.3

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ bbbbbbbb-0000-0000-0000-000000000001
begin
	import Pkg
	Pkg.activate(@__DIR__)
	Pkg.develop(path=joinpath(@__DIR__, ".."))
	
	using CoaxialAutogyroStacking
	using WGLMakie
	using PlutoUI
	using Printf
	WGLMakie.activate!()
	
	TableOfContents(title="📋 Sections")
end

# ╔═╡ 00000000-0000-0000-0000-000000000003
md"## 🎬 Scenario Preset"

# ╔═╡ 00000000-0000-0000-0000-000000000004
@bind _scenario Select(["Custom ✏️", "🚀 Launch (low angle, aggressive lift)", "✈️ Cruise (optimal)", "🛬 Landing (steep, depowered)", "🌪️ Storm gust"])

# ╔═╡ 00000000-0000-0000-0000-000000000005
md"## 🎛️ Wind, Line & Flight Mode"

# ╔═╡ 00000000-0000-0000-0000-000000000006
@bind _wind_speed Slider(3.0:0.5:20.0, default=8.0, show_value=true)

# ╔═╡ 00000000-0000-0000-0000-000000000023
md"*Line angle is computed from force equilibrium — no elevation slider needed.*"

# ╔═╡ 00000000-0000-0000-0000-000000000008
@bind _line_diam_mm Slider(2.0:0.5:12.0, default=4.0, show_value=true)

# ╔═╡ 00000000-0000-0000-0000-000000000009
@bind _turbulence CheckBox(default=false)

# ╔═╡ 00000000-0000-0000-0000-000000000010
md"## 🔧 Rotor Configuration"

# ╔═╡ 00000000-0000-0000-0000-000000000011
@bind _n_rotors Slider(1:6, default=4, show_value=true)

# ╔═╡ 00000000-0000-0000-0000-000000000012
@bind _rotor_radius Slider(0.5:0.1:3.0, default=3.0, show_value=true)

# ╔═╡ 11000000-0000-0000-0000-000000000001
md"### Disk Tilt (δ)"

# ╔═╡ 11000000-0000-0000-0000-000000000002
md"*Tilt angle of the rotor disk away from perpendicular to the line. Leading edge forward-down into the wind. Sets the thrust direction — the primary control for shaping the polygon chain.*"

# ╔═╡ 00000000-0000-0000-0000-000000000013
@bind _tilt_global Slider(0.0:1.0:30.0, default=15.0, show_value=true)

# ╔═╡ 00000000-0000-0000-0000-000000000015
md"#### Per-Rotor Tilt Offsets"

# ╔═╡ 00000000-0000-0000-0000-000000000016
@bind _tilt_offset_1 Slider(-15.0:0.5:15.0, default=0.0, show_value=true)

# ╔═╡ 00000000-0000-0000-0000-000000000017
@bind _tilt_offset_2 Slider(-15.0:0.5:15.0, default=0.0, show_value=true)

# ╔═╡ 00000000-0000-0000-0000-000000000018
@bind _tilt_offset_3 Slider(-15.0:0.5:15.0, default=0.0, show_value=true)

# ╔═╡ 00000000-0000-0000-0000-000000000025
@bind _tilt_offset_4 Slider(-15.0:0.5:15.0, default=0.0, show_value=true)

# ╔═╡ 00000000-0000-0000-0000-000000000026
@bind _tilt_offset_5 Slider(-15.0:0.5:15.0, default=0.0, show_value=true)

# ╔═╡ 00000000-0000-0000-0000-000000000027
@bind _tilt_offset_6 Slider(-15.0:0.5:15.0, default=0.0, show_value=true)

# ╔═╡ 00000000-0000-0000-0000-000000000019
md"*Per-rotor tilt offsets from global δ. One slider per rotor — set n_rotors to reveal more.*"

# ╔═╡ 22000000-0000-0000-0000-000000000001
md"### Blade Pitch (collective)"

# ╔═╡ 22000000-0000-0000-0000-000000000002
md"*Collective blade pitch angle. Changes thrust magnitude without changing thrust direction. Finer control than disk tilt — does not reshape the polygon chain.*"

# ╔═╡ 00000000-0000-0000-0000-000000000024
@bind _blade_pitch_global Slider(-10.0:1.0:20.0, default=0.0, show_value=true)

# ╔═╡ 33000000-0000-0000-0000-000000000001
md"#### Per-Rotor Blade Pitch Offsets"

# ╔═╡ 33000000-0000-0000-0000-000000000002
@bind _bp_offset_1 Slider(-15.0:0.5:15.0, default=0.0, show_value=true)

# ╔═╡ 33000000-0000-0000-0000-000000000003
@bind _bp_offset_2 Slider(-15.0:0.5:15.0, default=0.0, show_value=true)

# ╔═╡ 33000000-0000-0000-0000-000000000004
@bind _bp_offset_3 Slider(-15.0:0.5:15.0, default=0.0, show_value=true)

# ╔═╡ 00000000-0000-0000-0000-000000000014
@bind _section_len Slider(5.0:1.0:30.0, default=15.0, show_value=true)

# ╔═╡ 00000000-0000-0000-0000-000000000020
md"## 📐 Physics Computation"

# ╔═╡ 00000000-0000-0000-0000-000000000021
begin
	# Scenario presets override individual sliders when selected
	_wind  = _wind_speed
	_tilt  = _tilt_global
	_turb  = _turbulence
	_bp_global = _blade_pitch_global
	
	rho = 1.225
	g_const = 9.81
	
	# Per-rotor offsets
	_tilt_offsets = [_tilt_offset_1, _tilt_offset_2, _tilt_offset_3,
	                 _tilt_offset_4, _tilt_offset_5, _tilt_offset_6]
	_bp_offsets   = [_bp_offset_1, _bp_offset_2, _bp_offset_3]
	_n = max(1, _n_rotors)
	
	_rotors = AutogyroRotor[]
	for i in 1:_n
		toff = i <= length(_tilt_offsets) ? _tilt_offsets[i] : 0.0
		bpoff = i <= length(_bp_offsets) ? _bp_offsets[i] : 0.0
		tilt_i = clamp(_tilt + toff, 0.0, 45.0)
		bp_i = _bp_global + bpoff
		push!(_rotors, AutogyroRotor(_rotor_radius, 0.05, 2, 0.15, tilt_i, bp_i, 5.0))
	end
	
	_diam_m = _line_diam_mm / 1000.0
	_secs = fill(_section_len, _n)
	
	# Turbulent wind
	_t_sim = 0.0
	_v_wind = _turb ? _wind * (1.0 + 0.08*sin(2π*_t_sim/8.0) + 0.05*sin(2π*_t_sim/2.3)) : _wind

	# Anchor angle: 45° initial guess. The polygon solver converges to
	# equilibrium segment angles regardless of the initial guess.
	_elev = 45.0

	if startswith(_scenario, "🚀")
		_wind = 6.0;  _tilt = 15.0
	elseif startswith(_scenario, "✈️")
		_wind = 8.0;  _tilt = 10.0
	elseif startswith(_scenario, "🛬")
		_wind = 5.0;  _tilt = 0.0
	elseif startswith(_scenario, "🌪️")
		_wind = 16.0; _tilt = 5.0; _turb = true
	end
	
	# Polygon chain geometry — segment angles from force equilibrium at each rotor
	_poly_θ, _poly_T, _poly_F = solve_polygon_angles(_rotors, _secs, _elev, rho, _v_wind; max_iter=30)
	
	# Phase 11: per-rotor effective wind after wake momentum deficits.
	# Rotor 1 (topmost) always sees freestream; downstream rotors see reduced wind.
	_v_eff = stack_effective_wind(_rotors, _secs, rho, _v_wind, _elev)
	
	# Full tension profile with line drag + weight (uses polygon angles internally)
	_profile = stack_tension_profile_polygon(AutogyroStack(_rotors, _secs, _diam_m, _elev), rho, _v_wind)
	
	# Per-rotor forces at polygon segment angles, using wake-aware effective wind
	_rotor_forces = [(begin
		_, T, rpm = rotor_force_bem(rot, rho, _v_eff[i], _poly_θ[i])
		α_eff = effective_alpha(rot, _poly_θ[i])
		F_line = T * cosd(rot.tilt_deg)
		(F_line, T, 0.0, 0.0, 0.0, α_eff, rpm)
	end) for (i, rot) in enumerate(_rotors)]
	
	# Segment spread for display
	_seg_spread = length(_poly_θ) > 1 ? round(maximum(_poly_θ) - minimum(_poly_θ), digits=1) : 0.0
	
	# Effective wind per rotor for display
	_v_eff_str = join([@sprintf("R%d:%.1f", i, _v_eff[i]) for i in 1:_n], " ")
	
	md"""**Active preset:** $(_scenario) | Wind: $(round(_v_wind,digits=1)) m/s | **Elev: $(round(_elev,digits=1))°** | Tilt δ: $(round(_tilt,digits=0))° | BP: $(round(_bp_global,digits=0))° | **Chain spread: $(_seg_spread)°**
	
	**v_eff (top→bot):** $(_v_eff_str) m/s"""
end

# ╔═╡ 00000000-0000-0000-0000-000000000030
md"## 🎨 Side View — Polygon Chain"

# ╔═╡ 00000000-0000-0000-0000-000000000031
let
	# Build polygon vertices from segment angles (top → bottom)
	verts = [Point2f(0.0, 0.0)]  # anchor
	cum_x, cum_y = 0.0, 0.0
	for i in _n:-1:1  # bottom → top for drawing
		seg_angle = _poly_θ[i]
		seg_len = _secs[i]
		cum_x += seg_len * cosd(seg_angle)
		cum_y += seg_len * sind(seg_angle)
		push!(verts, Point2f(cum_x, cum_y))
	end
	reverse!(verts)  # top → bottom for consistent indexing
	
	total_x = cum_x
	total_y = cum_y
	max_t = max(maximum(abs, _poly_T), 1.0)
	
	fig_side = Figure(size=(700, 550))
	ax = Axis(fig_side[1, 1],
		title="Polygon Chain — $(round(_v_wind,digits=1)) m/s | Chain spread: $(_seg_spread)°",
		xlabel="Horizontal Downwind Distance (m)",
		ylabel="Altitude (m)",
		aspect=DataAspect(),
		limits=(-3, total_x + 10, -3, total_y + 8))
	
	# Ground
	lines!(ax, [Point2f(-3, 0), Point2f(total_x + 5, 0)],
		color=:gray75, linewidth=1, linestyle=:dash)
	
	# Polygon segments with tension coloring
	for i in 1:_n
		v_top = verts[i]      # rotor i position
		v_bot = verts[i+1]    # rotor i+1 (or anchor)
		tn = clamp(abs(_poly_T[i+1]) / max_t, 0, 1)
		lines!(ax, [v_top, v_bot], color=RGBf(tn, 0.15, 1 - tn), linewidth=2.5 + 2 * tn)
		
		# Segment angle label
		mid = Point2f((v_top[1] + v_bot[1])/2, (v_top[2] + v_bot[2])/2)
		text!(ax, "$(round(_poly_θ[i],digits=1))°", position=mid + Point2f(1.2, 0.3),
			fontsize=9, color=:gray40)
	end
	
	# Rotor disks — drawn with foreshortening based on disk-normal angle
	for i in 1:_n
		v = verts[i]
		rx = _rotor_radius
		# Disk normal angle = segment angle + tilt (disk tilted δ from ⟂ to line)
		disk_normal_angle = _poly_θ[i] + _rotors[i].tilt_deg
		ry = max(_rotor_radius * abs(sind(disk_normal_angle)), 0.1)
		θs = range(0, 2π, length=80)
		
		F_line = _rotor_forces[i][1]
		tn = clamp(abs(F_line) / max_t, 0, 1)
		col = RGBf(tn, 0.2, 1 - tn)
		
		poly!(ax, Point2f.(v[1] .+ rx * cos.(θs), v[2] .+ ry * sin.(θs)),
			color=(col, 0.3), strokecolor=col, strokewidth=2.5)
		scatter!(ax, v, color=col, markersize=10)
		text!(ax, "R$i\nδ=$(round(_rotors[i].tilt_deg,digits=0))°",
			position=v + Point2f(-1.5, _rotor_radius + 1.5),
			fontsize=10, color=:black, align=(:center, :bottom))
	end
	
	# Anchor
	scatter!(ax, verts[end], color=:saddlebrown, markersize=18, marker=:utriangle)
	text!(ax, "anchor", position=verts[end] + Point2f(-2, -1.5), fontsize=11, color=:saddlebrown)
	
	# Wind arrow — horizontal, positioned above mid-stack
	wx = total_x / 2
	wy = total_y + 5
	arrows!(ax, [Point2f(wx-6, wy)], [Vec2f(10, 0)],
		color=RGBf(0.3, 0.6, 0.9), linewidth=3, arrowsize=14)
	text!(ax, "$(round(_v_wind,digits=1)) m/s", position=Point2f(wx, wy + 1.5),
		fontsize=11, color=RGBf(0.3, 0.6, 0.9))
	
	# Turbulence indicator
	if _turb
		text!(ax, "TURBULENT", position=Point2f(total_x - 6, total_y + 7),
			fontsize=11, color=:orange, font=:bold)
	end
	
	fig_side
end

# ╔═╡ 00000000-0000-0000-0000-000000000040
md"## 📊 Tension Profile"

# ╔═╡ 00000000-0000-0000-0000-000000000041
let
	positions = Float64[]
	cum = 0.0
	for i in 1:length(_profile)
		push!(positions, cum)
		if i <= _n; cum += _section_len; end
	end
	
	fig_tens = Figure(size=(700, 400))
	ax = Axis(fig_tens[1, 1],
		title="Tension Profile — Anchor (left) → Top Rotor (right)",
		xlabel="Distance from anchor (m)", ylabel="Tension (N)")
	
	colors = [p >= 0 ? RGBf(0.2, 0.7, 0.3) : RGBf(0.9, 0.2, 0.2) for p in _profile]
	barplot!(ax, positions, reverse(_profile), color=reverse(colors), width=_section_len*0.8,
		strokewidth=1, strokecolor=:gray50)
	
	hlines!(ax, [0.0], color=:gray50, linestyle=:dash, linewidth=1.5)
	
	cum_m = _section_len
	for i in 1:_n
		vlines!(ax, [cum_m], color=:gray60, linestyle=:dot, linewidth=1)
		cum_m += _section_len
	end
	
	fig_tens
end

# ╔═╡ 00000000-0000-0000-0000-000000000050
md"## 📈 Performance HUD"

# ╔═╡ 00000000-0000-0000-0000-000000000051
let
	total_lift = sum(f[2] for f in _rotor_forces)
	total_drag = sum(f[3] for f in _rotor_forces)
	sys_ld = total_drag > 0 ? total_lift / total_drag : Inf
	
	total_mass = sum(r.mass for r in _rotors) + line_mass_per_m(_diam_m, 970.0) * sum(_secs)
	total_weight = total_mass * 9.81
	eq_elev = total_drag > 0 ? atand(max(0.0, total_lift - total_weight), total_drag) : 0.0
	
	lines = String[]
	push!(lines, "| Parameter        | Value |")
	push!(lines, "|:-----------------|:------|")
	push!(lines, "| Wind speed       | $(round(_v_wind,digits=1)) m/s $(_turb ? "🌊 TURB" : "💨") |")
	push!(lines, "| Anchor elevation | $(round(_poly_θ[_n],digits=1))° |")
	push!(lines, "| **Chain spread** | **$(_seg_spread)°** |")
	push!(lines, "| **Anchor tension** | **$(round(_profile[end],digits=0)) N** |")
	push!(lines, "| **System L/D**   | **$(round(sys_ld,digits=2))** |")
	push!(lines, "| Eq. elevation    | $(round(eq_elev,digits=1))° |")
	push!(lines, "")
	
	n_neg = count(<(0), _profile)
	if n_neg > 0
		push!(lines, "⚠️ **$n_neg segment(s) in compression!** Increase wind or reduce tilt.")
		push!(lines, "")
	end
	
	push!(lines, "| # | δ tilt | θ seg | α_eff | v_eff | F_line | RPM |")
	push!(lines, "|:--|:------:|:-----:|:-----:|:-----:|:------:|:---:|")
	for (i, f) in enumerate(_rotor_forces)
		push!(lines, "| R$i | $(round(_rotors[i].tilt_deg,digits=1))° | $(round(_poly_θ[i],digits=1))° | $(round(f[6],digits=1))° | $(round(_v_eff[i],digits=1)) m/s | $(round(f[1],digits=0)) N | $(round(f[7],digits=0)) |")
	end
	
	Markdown.parse(join(lines, "\n"))
end

# ╔═╡ 00000000-0000-0000-0000-000000000060
md"""
---
### Key Physics — Control Inputs vs. Equilibrium Resultants

| Variable | Type | Description |
|:---------|:-----|:------------|
| **Disk Tilt δ** | **Actuator Control** | Rotor disk angle vs perpendicular-to-line. Changes thrust **direction** → reshapes polygon chain. |
| **Blade Pitch** | **Actuator Control** | Collective blade angle. Changes thrust **magnitude** without changing direction. |
| **Wind Speed** | **Environmental Input** | Freestream velocity. |
| **Polygon θ seg** | **Equilibrium Resultant** | Segment angle from force equilibrium at each rotor. Cumulative tension + thrust + weight. |
| **Chain Spread** | **Output Metric** | max(θ) − min(θ) across all segments. >0 means the chain is curved. |
| **Anchor Tension** | **System Output** | Cumulative lift delivered to ground attachment. |
"""

# ╔═╡ 00000000-0000-0000-0000-000000000061
md"*Powered by [CoaxialAutogyroStacking.jl](https://github.com/rodread/CoaxialAutogyroStacking.jl) — 407 tests green | BEM v2 + polygon line geometry + wake + tip-loss*"

# ╔═╡ Cell order:
# ╟─bbbbbbbb-0000-0000-0000-000000000001
# ╠═00000000-0000-0000-0000-000000000003
# ╠═00000000-0000-0000-0000-000000000004
# ╠═00000000-0000-0000-0000-000000000005
# ╠═00000000-0000-0000-0000-000000000006
# ╠═00000000-0000-0000-0000-000000000023
# ╠═00000000-0000-0000-0000-000000000008
# ╠═00000000-0000-0000-0000-000000000009
# ╠═00000000-0000-0000-0000-000000000010
# ╠═00000000-0000-0000-0000-000000000011
# ╠═00000000-0000-0000-0000-000000000012
# ╠═11000000-0000-0000-0000-000000000001
# ╠═11000000-0000-0000-0000-000000000002
# ╠═00000000-0000-0000-0000-000000000013
# ╠═00000000-0000-0000-0000-000000000015
# ╠═00000000-0000-0000-0000-000000000016
# ╠═00000000-0000-0000-0000-000000000017
# ╠═00000000-0000-0000-0000-000000000018
# ╠═00000000-0000-0000-0000-000000000025
# ╠═00000000-0000-0000-0000-000000000026
# ╠═00000000-0000-0000-0000-000000000027
# ╠═00000000-0000-0000-0000-000000000019
# ╠═22000000-0000-0000-0000-000000000001
# ╠═22000000-0000-0000-0000-000000000002
# ╠═00000000-0000-0000-0000-000000000024
# ╠═33000000-0000-0000-0000-000000000001
# ╠═33000000-0000-0000-0000-000000000002
# ╠═33000000-0000-0000-0000-000000000003
# ╠═33000000-0000-0000-0000-000000000004
# ╠═00000000-0000-0000-0000-000000000014
# ╠═00000000-0000-0000-0000-000000000020
# ╠═00000000-0000-0000-0000-000000000021
# ╠═00000000-0000-0000-0000-000000000030
# ╠═00000000-0000-0000-0000-000000000031
# ╠═00000000-0000-0000-0000-000000000040
# ╠═00000000-0000-0000-0000-000000000041
# ╠═00000000-0000-0000-0000-000000000050
# ╠═00000000-0000-0000-0000-000000000051
# ╠═00000000-0000-0000-0000-000000000060
# ╠═00000000-0000-0000-0000-000000000061
