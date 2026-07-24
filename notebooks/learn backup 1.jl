### A Pluto.jl notebook ###
# v0.20.5

using Markdown
using InteractiveUtils

# ╔═╡ 00000000-0000-0000-0000-000000000000
begin
	import Pkg
	Pkg.activate(raw"/home/cameron-read/Documents/GitHub/CoaxialAutogyroStacking.jl")
	using CoaxialAutogyroStacking
	using DataFrames
	using Statistics
	using CairoMakie
	using PlutoUI
	md"✅ Loaded! Ready to explore."
end

# ╔═╡ 10000000-0000-0000-0000-000000000001
md"""
# 🪁 Coaxial Autogyro Stacking

*Your model, live and interactive.* 
Change any slider — everything recalculates instantly.
"""

# ╔═╡ 10000000-0000-0000-0000-000000000002
md"""
## 1. Single Rotor
"""

# ╔═╡ 20000000-0000-0000-0000-000000000001
@bind r_radius PlutoUI.Slider(0.5:0.1:3.0; default=1.5, show_value=true)

# ╔═╡ 20000000-0000-0000-0000-000000000002
@bind r_tilt PlutoUI.Slider(0:30; default=10, show_value=true)

# ╔═╡ 20000000-0000-0000-0000-000000000003
@bind r_wind PlutoUI.Slider(2:12; default=8, show_value=true)

# ╔═╡ 20000000-0000-0000-0000-000000000004
@bind r_elev PlutoUI.Slider(30:5:80; default=55, show_value=true)

# ╔═╡ 20000000-0000-0000-0000-000000000005
begin
	rotor = AutogyroRotor(r_radius, 0.05, 2, 0.15, r_tilt, 0.0, 5.0)
	F_line, F_lift, F_drag, alpha, rpm = rotor_force_along_line(rotor, 1.225, r_wind, r_elev)
	tip = rotor_tip_speed(rotor, r_wind, effective_alpha(rotor, r_elev))
	re_n = rotor_reynolds_number(rotor, 1.225, r_wind, effective_alpha(rotor, r_elev))
	
	md"""
	| Metric | Value |
	|--------|-------|
	| F_line | **$(round(F_line)) N** |
	| F_lift | $(round(F_lift)) N |
	| F_drag | $(round(F_drag)) N |
	| AoA | $(round(alpha, digits=1))° |
	| RPM | $(round(rpm)) |
	| Tip speed | $(round(tip, digits=1)) m/s |
	| Tip Re | $(round(re_n, sigdigits=2)) |
	"""
end

# ╔═╡ 10000000-0000-0000-0000-000000000003
md"""
## 2. Rotor Stack
"""

# ╔═╡ 30000000-0000-0000-0000-000000000001
@bind s_n PlutoUI.Slider(1:6; default=3, show_value=true)

# ╔═╡ 30000000-0000-0000-0000-000000000002
@bind s_spacing PlutoUI.Slider(5:5:30; default=10, show_value=true)

# ╔═╡ 30000000-0000-0000-0000-000000000003
begin
	rotors = [AutogyroRotor(r_radius, 0.05, 2, 0.15, r_tilt, 0.0, 5.0) for _ in 1:s_n]
	stk = AutogyroStack(rotors, fill(Float64(s_spacing), s_n), 0.004, Float64(r_elev))
	tension = stack_tension_profile(stk, 1.225, r_wind)
	
	fig = Figure(size=(550, 380))
	ax = Axis(fig[1,1], xlabel="Tension (N)", ylabel="Pos (m, top→anchor)",
		title="$(s_n) rotors, $(r_wind) m/s")
	pos = vcat([0.0], cumsum(Float64[s_spacing for _ in 1:s_n]))
	lines!(ax, tension, pos, lw=3, color=:steelblue)
	scatter!(ax, tension, pos, ms=12, color=:darkblue)
	ylims!(ax, pos[end]+2, -2)
	fig
end

# ╔═╡ 10000000-0000-0000-0000-000000000004
md"""
## 3. Viability
"""

# ╔═╡ 40000000-0000-0000-0000-000000000001
begin
	rep = viability_report(stk, 1.225, r_wind)
	md"""
	| Gate | |
	|------|--|
	| Reynolds ≥ 5×10⁵ | $(rep.reynolds_ok ? "✅" : "❌") |
	| Tip speed ≤ 120 | $(rep.noise_ok ? "✅" : "❌") |
	| Line weight fraction | $(round(rep.line_weight_fraction, digits=4)) |
	"""
end
