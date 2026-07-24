### A Pluto.jl notebook ###
# v0.20.5

using Markdown
using InteractiveUtils

# ╔═╡ abc12345-0000-0000-0000-000000000001
md"""
# Coaxial Autogyro Stacking — Interactive Explorer
*Your model, live and interactive.*

Change any number below and watch everything update instantly. This is the code you built — running right here.
"""

# ╔═╡ abc12345-0000-0000-0000-000000000002
begin
	using CoaxialAutogyroStacking
	using DataFrames
	using CairoMakie
	using Statistics
	println("Loaded!")
end

# ╔═╡ abc12345-0000-0000-0000-000000000003
md"""
## 1. Single Rotor Forces

Build one rotor and see what forces it produces.

**Try this:** Bump `rotor_radius` from 1.5 to 3.0. What happens to lift?
"""

# ╔═╡ abc12345-0000-0000-0000-000000000004
md"""
**Rotor parameters:**
"""

# ╔═╡ abc12345-0000-0000-0000-000000000005
@bind rotor_radius Scrubbable(0.5:0.1:3.0; default=1.5)

# ╔═╡ abc12345-0000-0000-0000-000000000006
@bind tilt_deg Scrubbable(0:30; default=10)

# ╔═╡ abc12345-0000-0000-0000-000000000007
@bind wind_speed Scrubbable(2:12; default=8)

# ╔═╡ abc12345-0000-0000-0000-000000000008
@bind elevation Scrubbable(30:5:80; default=55)

# ╔═╡ abc12345-0000-0000-0000-000000000009
begin
	r = AutogyroRotor(rotor_radius, 0.05, 2, 0.15, tilt_deg, 0.0, 5.0)
	F_line, F_lift, F_drag, alpha, rpm = rotor_force_along_line(r, 1.225, wind_speed, elevation)
	md"""
	**Results at $(wind_speed) m/s, $(elevation)° elevation:**

	| Force | Value |
	|-------|-------|
	| F_line (along Dyneema) | **$(round(F_line, digits=0)) N** |
	| F_lift (⊥ wind) | $(round(F_lift, digits=0)) N |
	| F_drag (∥ wind) | $(round(F_drag, digits=0)) N |
	| Effective AoA | $(round(alpha, digits=1))° |
	| Estimated RPM | $(round(rpm, digits=0)) |
	| Tip speed | $(round(rotor_tip_speed(r, wind_speed, effective_alpha(r, elevation)), digits=1)) m/s |
	| Tip Reynolds | $(round(rotor_reynolds_number(r, 1.225, wind_speed, effective_alpha(r, elevation)), sigdigits=2)) |
	"""
end

# ╔═╡ abc12345-0000-0000-0000-000000000010
md"""
## 2. Stack Tension Profile

Now stack multiple rotors on one line. Tension accumulates top→bottom.
"""

# ╔═╡ abc12345-0000-0000-0000-000000000011
@bind n_rotors Scrubbable(1:6; default=3)

# ╔═╡ abc12345-0000-0000-0000-000000000012
@bind spacing Scrubbable(5:5:30; default=10)

# ╔═╡ abc12345-0000-0000-0000-000000000013
begin
	stack_rotors = [AutogyroRotor(rotor_radius, 0.05, 2, 0.15, tilt_deg, 0.0, 5.0) for _ in 1:n_rotors]
	stack = AutogyroStack(stack_rotors, fill(Float64(spacing), n_rotors), 0.004, Float64(elevation))
	tension = stack_tension_profile(stack, 1.225, wind_speed)
	
	fig_tension = Figure(size=(600, 400))
	ax_t = Axis(fig_tension[1,1], xlabel="Tension (N)", ylabel="Position (top → anchor)", title="Tension Profile ($(n_rotors) rotors)")
	pos = vcat([0.0], cumsum([Float64(spacing) for _ in 1:n_rotors]))
	lines!(ax_t, tension, pos, linewidth=3, color=:steelblue)
	scatter!(ax_t, tension, pos, markersize=12, color=:darkblue)
	ylims!(ax_t, pos[end] + 2, -2)
	fig_tension
end

# ╔═╡ abc12345-0000-0000-0000-000000000014
md"""
## 3. Viability Report

Check if this configuration passes the physics gates.
"""

# ╔═╡ abc12345-0000-0000-0000-000000000015
begin
	rep = viability_report(stack, 1.225, wind_speed)
	if rep.reynolds_ok && rep.noise_ok
		md"""
		✅ **All gates passed.**

		- Re gate: ✅ ($(round(rep.reynolds_ok ? 1e6 : 0, sigdigits=1)))
		- Noise gate: ✅
		- Line weight fraction: $(round(rep.line_weight_fraction, digits=3))
		"""
	elseif length(rep.warnings) > 0
		md"""
		⚠️ **$(length(rep.warnings)) warning(s):**
		$(join(["  - $w" for w in rep.warnings], "\n"))
		
		- Line weight fraction: $(round(rep.line_weight_fraction, digits=3))
		"""
	else
		md"Unknown state"
	end
end

# ╔═╡ abc12345-0000-0000-0000-000000000016
md"""
## 4. Quick Sweep

Run a small sweep and see which configs are Pareto-optimal.
"""

# ╔═╡ abc12345-0000-0000-0000-000000000017
@bind sweep_radii MultiSelect([1.0, 2.0, 3.0]; default=[1.0, 3.0])

# ╔═╡ abc12345-0000-0000-0000-000000000018
@bind sweep_n MultiSelect([1, 3]; default=[1, 3])

# ╔═╡ abc12345-0000-0000-0000-000000000019
begin
	sweep_button = @bind run_sweep Button("▶ Run Sweep")
	sweep_button
end

# ╔═╡ abc12345-0000-0000-0000-000000000020
begin
	run_sweep  # trigger on button press
	df_s = parameter_sweep(
		radii=sweep_radii,
		stack_counts=sweep_n,
		spacings=[10.0],
		profiles=["uniform", "graded"],
		wind_speeds=[4.0, 8.0, 12.0],
		elevations=[55.0],
	)
	fom_s = compute_figures_of_merit(df_s)
	pf_s = pareto_front(fom_s, :mean_anchor_tension, :tension_per_kg)
	
	fig_sweep = Figure(size=(700, 450))
	ax_s = Axis(fig_sweep[1,1], xlabel="Mean Anchor Tension (N)", ylabel="Tension per kg (N/kg)", title="Sweep: $(nrow(fom_s)) configs, $(nrow(pf_s)) Pareto-optimal")
	scatter!(ax_s, fom_s.mean_anchor_tension, fom_s.tension_per_kg, markersize=8, color=:gray60, alpha=0.5, label="All")
	scatter!(ax_s, pf_s.mean_anchor_tension, pf_s.tension_per_kg, markersize=12, color=:red, label="Pareto")
	axislegend(ax_s, position=:rb)
	fig_sweep
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
# ╠═╡ show_logs = false
# ╠═╡ skip_as_script = true
#=╠═╡
md"""
## Done!

You built the sweep code, the viability gates, and the Pareto filter. Now you can explore it interactively.

**Things to try:**
- Change wind speed to 4 m/s — watch the Re gate fail
- Set n_rotors=6 — see tension accumulate  
- Compare graded vs uniform profiles in the sweep
"""
  ╠═╡ =#
