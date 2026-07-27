### A Pluto.jl notebook ###
# v1.0.1

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
	Pkg.activate(joinpath(@__DIR__, ".."))
	
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

# ╔═╡ 00000000-0000-0000-0000-000000000007
@bind _auto_elev CheckBox(default=true)

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
	_pitch = _pitch_global
	_turb  = _turbulence
	
	rho = 1.225
	g_const = 9.81
	
	# Per-rotor pitch offsets
	_offsets = [_pitch_offset_1, _pitch_offset_2, _pitch_offset_3]
	_n = max(1, _n_rotors)
	
	_rotors = AutogyroRotor[]
	for i in 1:_n
		poff = i <= length(_offsets) ? _offsets[i] : 0.0
		push!(_rotors, AutogyroRotor(_rotor_radius, 0.05, 4, 0.15, _pitch + poff, 0.0, 5.0))
	end
	
	_diam_m = _line_diam_mm / 1000.0
	_secs = fill(_section_len, _n)
	
	# Turbulent wind
	_t_sim = 0.0
	_v_wind = _turb ? _wind * (1.0 + 0.08*sin(2π*_t_sim/8.0) + 0.05*sin(2π*_t_sim/2.3)) : _wind

	# Line elevation angle:
	# If _auto_elev is true (default), line elevation angle EMERGES 100% from autogyro L/D physics equilibrium!
	if _auto_elev
		_eq_elev = 55.0
		for _ in 1:8
			_test_forces = [rotor_force_along_line(r, rho, _v_wind, _eq_elev) for r in _rotors]
			_flift = sum(f[2] for f in _test_forces)
			_fdrag = sum(f[3] for f in _test_forces) + bare_line_drag(rho, _v_wind, _diam_m, sum(_secs), _eq_elev)
			_total_mass = sum(r.mass for r in _rotors) + line_mass_per_m(_diam_m, 970.0) * sum(_secs)
			_fweight = _total_mass * g_const
			_next = _fdrag > 0 ? atand(max(0.0, _flift - _fweight), _fdrag) : 10.0
			_next = clamp(_next, 10.0, 85.0)
			if abs(_next - _eq_elev) < 0.05; break; end
			_eq_elev = _next
		end
		_elev = _eq_elev
	else
		_elev = _elevation
	end

	if startswith(_scenario, "🚀")
		_wind = 6.0;  _pitch = 15.0;  if !_auto_elev; _elev = 30.0; end
	elseif startswith(_scenario, "✈️")
		_wind = 8.0;  _pitch = 5.0;   if !_auto_elev; _elev = 55.0; end
	elseif startswith(_scenario, "🛬")
		_wind = 5.0;  _pitch = -10.0; if !_auto_elev; _elev = 75.0; end
	elseif startswith(_scenario, "🌪️")
		_wind = 16.0; _pitch = -5.0; _turb = true; if !_auto_elev; _elev = 45.0; end
	end
	
	_stack = AutogyroStack(_rotors, _secs, _diam_m, _elev)
	_profile = stack_tension_profile(_stack, rho, _v_wind)
	
	_rotor_forces = [(begin
		F_line, F_lift, F_drag, cl, cd = rotor_force_along_line(rot, rho, _v_wind, _elev)
		(F_line, F_lift, F_drag, cl, cd, effective_alpha(rot, _elev))
	end) for rot in _stack.rotors]
	
	_mode_str = _auto_elev ? "Auto L/D physics" : "Manual override"
	md"**Active preset:** $(_scenario) | Wind: $(round(_v_wind,digits=1)) m/s | **Line Elev ($(_mode_str)): $(round(_elev,digits=1))°** | Pitch: $(round(_pitch,digits=0))° | Turb: $(_turb)"
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
		title="Kite Line Side View — $(round(_v_wind,digits=1)) m/s$( _v_wind > 10 ? " (high wind)" : "")",
		xlabel="Horizontal Downwind Distance (m)",
		ylabel="Altitude (m)",
		aspect=DataAspect(),
		limits=(-5, total_len*cos(er) + 12, -3, total_len*sind(_elev) + 12))
	
	# Ground
	lines!(ax, [Point2f(-3, 0), Point2f(total_len*cos(er)+5, 0)],
		color=:gray75, linewidth=1, linestyle=:dash)
	
	# Rotor positions (top -> bottom: R1 is topmost at total_len, Rn is bottommost at _section_len)
	rotor_s = [(_n - i + 1) * _section_len for i in 1:_n]
	
	# Tension-colored line segments (bottom-up: segment 1 is anchor -> Rn with profile[_n+1])
	prev_s = 0.0
	for i in 1:_n
		next_s = rotor_s[_n - i + 1]
		s0 = Point2f(prev_s * cos(er), prev_s * sin(er))
		s1 = Point2f(next_s * cos(er), next_s * sin(er))
		tn = clamp(abs(_profile[_n - i + 2]) / max_t, 0, 1)
		lines!(ax, [s0, s1], color=RGBf(tn, 0.15, 1 - tn), linewidth=2.5 + 2 * tn)
		prev_s = next_s
	end
	
	# Rotor disks (top -> bottom R1..Rn)
	for i in 1:_n
		cx = rotor_s[i] * cos(er)
		cy = rotor_s[i] * sin(er)
		rx = _rotor_radius
		ry = max(_rotor_radius * sind(_elev), 0.1)
		θs = range(0, 2π, length=80)
		
		F_line = _rotor_forces[i][1]
		tn = clamp(abs(F_line) / max_t, 0, 1)
		col = RGBf(tn, 0.2, 1 - tn)
		
		poly!(ax, Point2f.(cx .+ rx * cos.(θs), cy .+ ry * sin.(θs)),
			color=(col, 0.3), strokecolor=col, strokewidth=2.5)
		scatter!(ax, Point2f(cx, cy), color=col, markersize=10)
		text!(ax, "R$i", position=Point2f(cx - 1.5, cy + _rotor_radius + 1),
			fontsize=12, color=:black, align=(:center, :bottom))
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
		text!(ax, "TURBULENT", position=Point2f(total_len*cos(er)-6, total_len*sind(_elev)+8),
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
	
	total_mass = sum(r.mass for r in _stack.rotors) + line_mass_per_m(_stack.line_diameter, _stack.line_density) * sum(_secs)
	total_weight = total_mass * 9.81
	eq_elev = total_drag > 0 ? atand(max(0.0, total_lift - total_weight), total_drag) : 0.0
	
	lines = String[]
	push!(lines, "| Parameter        | Value | Control Type |")
	push!(lines, "|:-----------------|:------|:-------------|")
	push!(lines, "| Wind speed       | $(round(_v_wind,digits=1)) m/s $(_turb ? "🌊 TURB" : "💨") | Environmental Input |")
	push!(lines, "| Line elevation (preset) | $(round(_elev,digits=0))° | Target Trajectory |")
	push!(lines, "| **Equilibrium elevation** | **$(round(eq_elev,digits=1))°** | **Physics Resultant (L/D balance)** |")
	push!(lines, "| Line spec        | Ø$(round(_line_diam_mm,digits=1))mm × $(round(sum(_secs),digits=0))m | Design Parameter |")
	push!(lines, "| **Anchor tension** | **$(round(_profile[end],digits=0)) N** | Output Lift Delivered |")
	push!(lines, "| **System L/D**   | **$(round(sys_ld,digits=2))** | Efficiency Metric |")
	push!(lines, "| Total lift/drag  | $(round(total_lift,digits=0)) / $(round(total_drag,digits=0)) N | Force Vector Sum |")
	push!(lines, "")
	
	n_neg = count(<(0), _profile)
	if n_neg > 0
		push!(lines, "⚠️ **$n_neg segment(s) in compression!** Increase wind or reduce pitch.")
		push!(lines, "")
	end
	
	push!(lines, "| # | Tilt δ | α_eff | CL | CD | F_line |")
	push!(lines, "|:--|:-----:|:-----:|:---:|:---:|:------:|")
	for (i, f) in enumerate(_rotor_forces)
		push!(lines, "| R$i | $(round(_stack.rotors[i].tilt_deg,digits=1))° | $(round(f[6],digits=1))° | $(round(f[4],digits=3)) | $(round(f[5],digits=3)) | $(round(f[1],digits=0)) N |")
	end
	
	Markdown.parse(join(lines, "\n"))
end

# ╔═╡ 00000000-0000-0000-0000-000000000060
md"""
---
### Key Physics & Control vs. Resultant Architecture

| Variable / Parameter | Type | Description |
|:---------------------|:-----|:------------|
| **Rotor Tilt $\delta$ / Collective Pitch** | **Actuator Control Input** | Set by swashplate actuators or empennage trim per rotor. |
| **Wind Speed $v_{\text{wind}}$** | **Environmental Input** | Freestream velocity vector. |
| **Line Elevation $\theta_{\text{eq}}$** | **Equilibrium Resultant** | **Not a direct control slider.** Driven by System $L/D$ balance: $\theta_{\text{eq}} \approx \arctan((F_{\text{lift}} - W)/F_{\text{drag}})$. |
| **Effective AoA $\alpha_{\text{eff}}$** | **Aerodynamic State** | $\alpha_{\text{eff}} = 90^\circ - \theta_{\text{line}} + \delta$. |
| **Anchor Tension $T_{\text{anchor}}$** | **System Output** | Cumulative lift delivered to kite turbine hub at ground. |
"""

# ╔═╡ 00000000-0000-0000-0000-000000000061
md"*Powered by [CoaxialAutogyroStacking.jl](https://github.com/rodread/CoaxialAutogyroStacking.jl) — 75 tests, strict TDD, PCA-2 empirical data*

# ╔═╡ 00000000-0000-0000-0000-000000000023
@bind _elevation Slider(10.0:1.0:80.0, default=55.0, show_value=true)

# ╔═╡ Cell order:
# ╠═bbbbbbbb-0000-0000-0000-000000000001
# ╠═00000000-0000-0000-0000-000000000003
# ╠═00000000-0000-0000-0000-000000000004
# ╠═00000000-0000-0000-0000-000000000005
# ╠═00000000-0000-0000-0000-000000000006
# ╠═00000000-0000-0000-0000-000000000007
# ╠═00000000-0000-0000-0000-000000000022
# ╠═00000000-0000-0000-0000-000000000023
# ╠═00000000-0000-0000-0000-000000000008
# ╠═00000000-0000-0000-0000-000000000009
# ╠═00000000-0000-0000-0000-000000000010
# ╠═00000000-0000-0000-0000-000000000011
# ╠═00000000-0000-0000-0000-000000000012
# ╠═00000000-0000-0000-0000-000000000013
# ╠═00000000-0000-0000-0000-000000000014
# ╠═00000000-0000-0000-0000-000000000015
# ╠═00000000-0000-0000-0000-000000000016
# ╠═00000000-0000-0000-0000-000000000017
# ╠═00000000-0000-0000-0000-000000000018
# ╠═00000000-0000-0000-0000-000000000019
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
