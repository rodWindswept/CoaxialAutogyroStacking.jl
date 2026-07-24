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
	CairoMakie.activate!(type="png")          # headless rendering
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
	
	anchor = round(Int, tension[end])
	per_rotor = round(Int, anchor / s_n)
	lift_sum = round(Int, sum(
		first(rotor_force_along_line(r, 1.225, r_wind, r_elev))
		for r in rotors))
	
	rows = join(["| Rotor $i | $(round(Int, tension[i])) N |" for i in 1:s_n], "\n")
	Markdown.parse("""
	**$s_n rotors, $(Int(r_wind)) m/s wind, $(Int(r_elev))° elevation**
	
	| Position | Tension |
	|----------|---------|
	$rows
	| **Anchor** | **$anchor N** |
	
	| Summary | |
	|---------|---|
	| Anchor tension | $anchor N |
	| Per rotor | $per_rotor N |
	| Total rotor lift | $lift_sum N |
	""")
end

# ╔═╡ 10000000-0000-0000-0000-000000000004
md"""
## 3. Viability
"""

# ╔═╡ 40000000-0000-0000-0000-000000000001
begin
	rep = viability_report(stk, 1.225, r_wind)
	re_icon = rep.reynolds_ok ? "PASS" : "FAIL"
	noise_icon = rep.noise_ok ? "PASS" : "FAIL"
	lwf = round(rep.line_weight_fraction, digits=4)
	Markdown.parse("""
	| Gate | Status |
	|------|--------|
	| Reynolds >= 5e5 | $re_icon |
	| Tip speed <= 120 | $noise_icon |
	| Line weight fraction | $lwf |
	""")
end

# ╔═╡ Cell order:
# ╠═00000000-0000-0000-0000-000000000000
# ╠═10000000-0000-0000-0000-000000000001
# ╠═10000000-0000-0000-0000-000000000002
# ╠═20000000-0000-0000-0000-000000000001
# ╠═20000000-0000-0000-0000-000000000002
# ╠═20000000-0000-0000-0000-000000000003
# ╠═20000000-0000-0000-0000-000000000004
# ╠═20000000-0000-0000-0000-000000000005
# ╠═10000000-0000-0000-0000-000000000003
# ╠═30000000-0000-0000-0000-000000000001
# ╠═30000000-0000-0000-0000-000000000002
# ╠═30000000-0000-0000-0000-000000000003
# ╠═10000000-0000-0000-0000-000000000004
# ╠═40000000-0000-0000-0000-000000000001
