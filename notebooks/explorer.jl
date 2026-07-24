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

# ╔═╡ 00000000-0000-0000-0000-000000000000
begin
	import Pkg
	Pkg.activate(raw"/home/cameron-read/Documents/GitHub/CoaxialAutogyroStacking.jl")
	using CoaxialAutogyroStacking
	using DataFrames
	using Statistics
	using CairoMakie
	using PlutoUI
	println("Loaded!")
end

# ╔═╡ abc12345-0000-0000-0000-000000000001
md"""
# Coaxial Autogyro Stacking — Interactive Explorer
*Your model, live and interactive.*

Change any number below and watch everything update instantly.
"""

# ╔═╡ abc12345-0000-0000-0000-000000000003
md"""
## 1. Single Rotor Forces

**Try this:** Bump `rotor_radius` from 1.5 to 3.0. What happens to lift?
"""

# ╔═╡ abc12345-0000-0000-0000-000000000005
@bind rotor_radius PlutoUI.Slider(0.5:0.1:3.0; default=1.5, show_value=true)

# ╔═╡ abc12345-0000-0000-0000-000000000006
@bind tilt_deg PlutoUI.Slider(0:30; default=10, show_value=true)

# ╔═╡ abc12345-0000-0000-0000-000000000007
@bind wind_speed PlutoUI.Slider(2:12; default=8, show_value=true)

# ╔═╡ abc12345-0000-0000-0000-000000000008
@bind elevation PlutoUI.Slider(30:5:80; default=55, show_value=true)

# ╔═╡ abc12345-0000-0000-0000-000000000009
begin
	r = AutogyroRotor(rotor_radius, 0.05, 2, 0.15, tilt_deg, 0.0, 5.0)
	F_line, F_lift, F_drag, alpha, rpm = rotor_force_along_line(r, 1.225, wind_speed, elevation)
	tip = rotor_tip_speed(r, wind_speed, effective_alpha(r, elevation))
	re_num = rotor_reynolds_number(r, 1.225, wind_speed, effective_alpha(r, elevation))
	
	md"""
	| Force | Value |
	|-------|-------|
	| F_line (along Dyneema) | **$(round(F_line)) N** |
	| F_lift (perpendicular to wind) | $(round(F_lift)) N |
	| F_drag (parallel to wind) | $(round(F_drag)) N |
	| Effective AoA | $(round(alpha, digits=1))° |
	| Estimated RPM | $(round(rpm)) |
	| Tip speed | $(round(tip, digits=1)) m/s |
	| Tip Reynolds | $(round(re_num, sigdigits=2)) |
	"""
end

# ╔═╡ abc12345-0000-0000-0000-000000000010
md"""
## 2. Stack Tension Profile
"""

# ╔═╡ abc12345-0000-0000-0000-000000000011
@bind n_rotors PlutoUI.Slider(1:6; default=3, show_value=true)

# ╔═╡ abc12345-0000-0000-0000-000000000012
@bind spacing PlutoUI.Slider(5:5:30; default=10, show_value=true)

# ╔═╡ abc12345-0000-0000-0000-000000000013
begin
	stack_rotors = [AutogyroRotor(rotor_radius, 0.05, 2, 0.15, tilt_deg, 0.0, 5.0) for _ in 1:n_rotors]
	stack = AutogyroStack(stack_rotors, fill(Float64(spacing), n_rotors), 0.004, Float64(elevation))
	tension = stack_tension_profile(stack, 1.225, wind_speed)
	
	fig_t = Figure(size=(600, 400))
	ax_t = Axis(fig_t[1,1], xlabel="Tension (N)", ylabel="Pos (top→anchor, m)", 
		title="Tension: $(n_rotors) rotors, $(wind_speed) m/s")
	pos = vcat([0.0], cumsum(Float64[spacing for _ in 1:n_rotors]))
	lines!(ax_t, tension, pos, linewidth=3, color=:steelblue)
	scatter!(ax_t, tension, pos, markersize=12, color=:darkblue)
	ylims!(ax_t, pos[end] + 2, -2)
	fig_t
end

# ╔═╡ abc12345-0000-0000-0000-000000000014
md"""
## 3. Viability Report
"""

# ╔═╡ abc12345-0000-0000-0000-000000000015
begin
	rep = viability_report(stack, 1.225, wind_speed)
	
	re_emoji = rep.reynolds_ok ? "✅" : "❌"
	noise_emoji = rep.noise_ok ? "✅" : "❌"
	
	md"""
	| Gate | Status |
	|------|--------|
	| Reynolds (≥ 5×10⁵) | $re_emoji |
	| Noise (≤ 120 m/s) | $noise_emoji |
	| Line weight fraction | $(round(rep.line_weight_fraction, digits=4)) |
	
	$((length(rep.warnings) > 0) ? "⚠️ **Warnings:** " * join(rep.warnings, "; ") : "✅ All gates passed")
	"""
end

# ╔═╡ abc12345-0000-0000-0000-000000000016
md"""
## 4. Quick Sweep
"""

# ╔═╡ abc12345-0000-0000-0000-000000000019
@bind run_sweep PlutoUI.Button("▶ Run Sweep")

# ╔═╡ abc12345-0000-0000-0000-000000000020
begin
	run_sweep
	df_s = parameter_sweep(
		radii=[1.0, 2.0, 3.0],
		stack_counts=[1, 3],
		spacings=[10.0],
		profiles=["uniform", "graded"],
		wind_speeds=[4.0, 8.0, 12.0],
		elevations=[55.0],
	)
	fom_s = compute_figures_of_merit(df_s)
	pf_s = pareto_front(fom_s, :mean_anchor_tension, :tension_per_kg)
	
	fig_s = Figure(size=(700, 450))
	ax_s = Axis(fig_s[1,1], xlabel="Mean Anchor Tension (N)", ylabel="N/kg",
		title="$(nrow(fom_s)) configs, $(nrow(pf_s)) Pareto-optimal")
	scatter!(ax_s, fom_s.mean_anchor_tension, fom_s.tension_per_kg, markersize=8, color=:gray60, alpha=0.5, label="All")
	scatter!(ax_s, pf_s.mean_anchor_tension, pf_s.tension_per_kg, markersize=12, color=:red, label="Pareto")
	axislegend(ax_s, position=:rb)
	fig_s
end

# ╔═╡ Cell order:
# ╠═00000000-0000-0000-0000-000000000000
# ╠═abc12345-0000-0000-0000-000000000001
# ╠═abc12345-0000-0000-0000-000000000003
# ╠═abc12345-0000-0000-0000-000000000005
# ╠═abc12345-0000-0000-0000-000000000006
# ╠═abc12345-0000-0000-0000-000000000007
# ╠═abc12345-0000-0000-0000-000000000008
# ╠═abc12345-0000-0000-0000-000000000009
# ╠═abc12345-0000-0000-0000-000000000010
# ╠═abc12345-0000-0000-0000-000000000011
# ╠═abc12345-0000-0000-0000-000000000012
# ╠═abc12345-0000-0000-0000-000000000013
# ╠═abc12345-0000-0000-0000-000000000014
# ╠═abc12345-0000-0000-0000-000000000015
# ╠═abc12345-0000-0000-0000-000000000016
# ╠═abc12345-0000-0000-0000-000000000019
# ╠═abc12345-0000-0000-0000-000000000020
