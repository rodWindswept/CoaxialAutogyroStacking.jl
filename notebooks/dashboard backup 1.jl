### A Pluto.jl notebook ###
# v0.21.0

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Coaxial Autogyro Stacking — Interactive Dashboard                  ║
# ║  Side view + tension profile + HUD + turbulence + scenarios          ║
# ╚══════════════════════════════════════════════════════════════════════╝

using Pkg
Pkg.activate(raw"/home/rod/Documents/GitHub/CoaxialAutogyroStacking.jl")

# ╔═╡ 00000000-0000-0000-0000-000000000001
begin
	using CoaxialAutogyroStacking
	using WGLMakie
	using PlutoUI
	using Printf
	WGLMakie.activate!()
	
	TableOfContents(title="📋 Sections")
end

# ╔═╡ 00000000-0000-0000-0000-000000000002
md"""
# 🪁 Coaxial Autogyro Stacking Dashboard

**Physics:** Multiple autogyro rotors stacked on a kite line. Each rotor has independent pitch — the "coaxial-ish" capability means the rotor disk AoA can differ from the kite line elevation.

- **Warm colors** = high force contribution | **Cool colors** = low force
- **Green bars** = positive tension | **Red bars** = compression (⚠ bad!)
- **PCA-2 empirical rotor data** for CL/CD (same as KiteTurbineDynamics.jl)
"""

# ╔═╡ 00000000-0000-0000-0000-000000000003
md"## 🎬 Scenario Preset"

# ╔═╡ 00000000-0000-0000-0000-000000000004
@bind _scenario Select(["Custom ✏️", "🚀 Launch (low angle, aggressive lift)", "✈️ Cruise (optimal)", "🛬 Landing (steep, depowered)", "🌪️ Storm gust"])

# ╔═╡ 00000000-0000-0000-0000-000000000005
md"## 🎛️ Wind & Line"

# ╔═╡ 00000000-0000-0000-0000-000000000006
@bind _wind_speed Slider(3.0:0.5:20.0, default=8.0, show_value=true)

# ╔═╡ 00000000-0000-0000-0000-000000000007
@bind _elevation Slider(10.0:1.0:80.0, default=55.0, show_value=true)

# ╔═╡ 00000000-0000-0000-0000-000000000008
@bind _line_diam_mm Slider(2.0:0.5:12.0, default=4.0, show_value=true)

# ╔═╡ 00000000-0000-0000-0000-000000000009
@bind _turbulence CheckBox(default=false)

# ╔═╡ 00000000-0000-0000-0000-000000000010
md"## 🔧 Rotor Configuration"

# ╔═╡ 00000000-0000-0000-0000-000000000011
@bind _n_rotors Slider(1:6, default=3, show_value=true)

# ╔═╡ 00000000-0000-0000-0000-000000000012
@bind _rotor_radius Slider(0.5:0.1:3.0, default=1.5, show_value=true)

# ╔═╡ 00000000-0000-0000-0000-000000000013
@bind _pitch_global Slider(-20.0:1.0:30.0, default=5.0, show_value=true)

# ╔═╡ 00000000-0000-0000-0000-000000000014
@bind _section_len Slider(5.0:1.0:30.0, default=10.0, show_value=true)

# ╔═╡ 00000000-0000-0000-0000-000000000015
md"### Per-Rotor Pitch Offsets"

# ╔═╡ 00000000-0000-0000-0000-000000000016
@bind _pitch_offset_1 Slider(-15.0:0.5:15.0, default=0.0, show_value=true)

# ╔═╡ 00000000-0000-0000-0000-000000000017
@bind _pitch_offset_2 Slider(-15.0:0.5:15.0, default=0.0, show_value=true)

# ╔═╡ 00000000-0000-0000-0000-000000000018
@bind _pitch_offset_3 Slider(-15.0:0.5:15.0, default=0.0, show_value=true)

# ╔═╡ 00000000-0000-0000-0000-000000000019
md"*(R4–R6 offsets hidden when n < 4 — adjust n_rotors slider to reveal)*"

# ╔═╡ 00000000-0000-0000-0000-000000000020
md"## 📐 Physics Computation"

# ╔═╡ 00000000-0000-0000-0000-000000000021
begin
	# Scenario presets override individual sliders when selected
	_wind  = _wind_speed
	_elev  = _elevation
	_pitch = _pitch_global
	_turb  = _turbulence
	
	if startswith(_scenario, "🚀")
		_wind = 6.0;  _elev = 30.0;  _pitch = 15.0
	elseif startswith(_scenario, "✈️")
		_wind = 8.0;  _elev = 55.0;  _pitch = 5.0
	elseif startswith(_scenario, "🛬")
		_wind = 5.0;  _elev = 75.0;  _pitch = -10.0
	elseif startswith(_scenario, "🌪️")
		_wind = 16.0; _elev = 45.0;  _pitch = -5.0; _turb = true
	end
	
	rho = 1.225
	g_const = 9.81
	
	# Per-rotor pitch offsets
	_offsets = [_pitch_offset_1, _pitch_offset_2, _pitch_offset_3]
	_n = max(1, _n_rotors)
	
	_rotors = AutogyroRotor[]
	for i in 1:_n
		poff = i <= length(_offsets) ? _offsets[i] : 0.0
		push!(_rotors, AutogyroRotor(_rotor_radius, 0.05, 4, 0.15, _pitch + poff, 5.0))
	end
	
	_diam_m = _line_diam_mm / 1000.0
	_secs = vcat(_section_len, fill(_section_len, _n))
	_stack = AutogyroStack(_rotors, _secs, _diam_m, _elev)
	
	# Turbulent wind
	_t_sim = 0.0
	_v_wind = _turb ? _wind * (1.0 + 0.08*sin(2π*_t_sim/8.0) + 0.05*sin(2π*_t_sim/2.3)) : _wind
	
	_profile = stack_tension_profile(_stack, rho, _v_wind)
	
	_rotor_forces = [(begin
		F_line, F_lift, F_drag, cl, cd = rotor_force_along_line(rot, rho, _v_wind, _elev)
		(F_line, F_lift, F_drag, cl, cd, effective_alpha(rot, _elev))
	end) for rot in _stack.rotors]
	
	md"**Active preset:** $(_scenario) | Wind: $(round(_wind,digits=1)) m/s | Elev: $(round(_elev,digits=0))° | Pitch: $(round(_pitch,digits=0))° | Turb: $(_turb)"
end

# ╔═╡ 00000000-0000-0000-0000-000000000030
md"## 🎨 Side View — Kite Line + Rotors"

# ╔═╡ 00000000-0000-0000-0000-000000000031
let
	total_len = sum(_secs)
	er = deg2rad(_elev)
	max_t = max(maximum(abs, _profile), 1.0)
	
	fig_side = Figure(size=(700, 550))
	ax = Axis(fig_side[1, 1],
		title="Kite Line Side View — $(_v_wind > 10 ? "💨" : "🍃") $(round(_v_wind,digits=1)) m/s",
		xlabel="Horizontal (m)", ylabel="Height (m)",
		aspect=DataAspect(),
		limits=(-5, total_len + 12, -3, total_len*sind(_elev) + 12))
	
	# Ground
	lines!(ax, [Point2f(-3, 0), Point2f(total_len*cos(er)+5, 0)],
		color=:gray75, linewidth=1, linestyle=:dash)
	
	# Tension-colored line
	cum = 0.0
	for k in 1:(_n+1)
		s0 = Point2f(cum*cos(er), cum*sin(er))
		s1 = Point2f((cum+_secs[k])*cos(er), (cum+_secs[k])*sin(er))
		tn = clamp(abs(_profile[k])/max_t, 0, 1)
		lines!(ax, [s0, s1], color=RGBf(tn, 0.15, 1-tn), linewidth=2.5 + 2*tn)
		cum += _secs[k]
	end
	
	# Rotor disks
	cum = _section_len
	for i in 1:_n
		cx, cy = cum*cos(er), cum*sin(er)
		rx = _rotor_radius
		ry = max(_rotor_radius * sind(_elev), 0.1)
		θs = range(0, 2π, length=80)
		
		F_line = _rotor_forces[i][1]
		tn = clamp(abs(F_line)/max_t, 0, 1)
		col = RGBf(tn, 0.2, 1-tn)
		
		poly!(ax, Point2f.(cx .+ rx*cos.(θs), cy .+ ry*sin.(θs)),
			color=(col, 0.3), strokecolor=col, strokewidth=2.5)
		scatter!(ax, Point2f(cx, cy), color=col, markersize=10)
		text!(ax, "R$i", position=Point2f(cx-1.5, cy+_rotor_radius+1),
			fontsize=12, color=:black, align=(:center, :bottom))
		
		cum += _section_len
	end
	
	# Anchor
	scatter!(ax, Point2f(0, 0), color=:saddlebrown, markersize=18, marker=:utriangle)
	text!(ax, "anchor", position=Point2f(-5, -1.5), fontsize=11, color=:saddlebrown)
	
	# Wind arrow
	wx = total_len*cos(er)/2
	wy = total_len*sind(_elev) + 6
	arrows!(ax, [Point2f(wx-5, wy)], [Point2f(wx+5, wy)],
		color=RGBf(0.3, 0.6, 0.9), linewidth=3, arrowsize=14)
	
	# Turbulence indicator
	if _turb
		text!(ax, "🌊 TURBULENT", position=Point2f(total_len*cos(er)-8, total_len*sind(_elev)+8),
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
		title="Tension Profile Along Kite Line",
		xlabel="Position along line (m)", ylabel="Tension (N)")
	
	colors = [p >= 0 ? RGBf(0.2, 0.7, 0.3) : RGBf(0.9, 0.2, 0.2) for p in _profile]
	barplot!(ax, positions, _profile, color=colors, width=_section_len*0.8,
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
	
	lines = String[]
	push!(lines, "| Parameter        | Value |")
	push!(lines, "|:-----------------|:------|")
	push!(lines, "| Wind speed       | $(round(_v_wind,digits=1)) m/s $(_turb ? "🌊 TURB" : "💨") |")
	push!(lines, "| Line elevation   | $(round(_elev,digits=0))° |")
	push!(lines, "| Line spec        | Ø$(round(_line_diam_mm,digits=1))mm × $(round((_n+1)*_section_len,digits=0))m |")
	push!(lines, "| **Anchor tension** | **$(round(_profile[end],digits=0)) N** |")
	push!(lines, "| **System L/D**   | **$(round(sys_ld,digits=2))** |")
	push!(lines, "| Total lift/drag  | $(round(total_lift,digits=0)) / $(round(total_drag,digits=0)) N |")
	push!(lines, "")
	
	n_neg = count(<(0), _profile)
	if n_neg > 0
		push!(lines, "⚠️ **$n_neg segment(s) in compression!** Increase wind or reduce pitch.")
		push!(lines, "")
	end
	
	push!(lines, "| # | Pitch | α_eff | CL | CD | F_line |")
	push!(lines, "|:--|:-----:|:-----:|:---:|:---:|:------:|")
	for (i, f) in enumerate(_rotor_forces)
		push!(lines, "| R$i | $(round(_stack.rotors[i].pitch_deg,digits=1))° | $(round(f[6],digits=1))° | $(round(f[4],digits=3)) | $(round(f[5],digits=3)) | $(round(f[1],digits=0)) N |")
	end
	
	Markdown.parse(join(lines, "\n"))
end

# ╔═╡ 00000000-0000-0000-0000-000000000060
md"""
---
### Key Physics

| Symbol | Meaning |
|:-------|:--------|
| α_eff | 90° − line_elevation + pitch — effective disk angle of attack |
| CL, CD | PCA-2 empirical rotor disk coefficients (linear interp, 0–90°) |
| F_line | F_lift·sin(elev) + F_drag·cos(elev) — force along kite line axis |
| Tension | Accumulates from free end downward: each rotor adds F_line − W_rotor·cos(elev) |
| ⚠ Compression | Negative tension = rotor can't support its weight at current wind/elev/pitch |
"""

# ╔═╡ 00000000-0000-0000-0000-000000000061
md"*Powered by [CoaxialAutogyroStacking.jl](https://github.com/rodread/CoaxialAutogyroStacking.jl) — 75 tests, strict TDD, PCA-2 empirical data*"
