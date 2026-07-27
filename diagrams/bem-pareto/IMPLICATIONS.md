# IMPLICATIONS.md — bem-pareto

The Pareto front shows that mass efficiency (N/kg) and raw anchor tension (N)
are nearly perfectly co-linear — a single configuration (R=3.0m, N=4, graded,
839 N, 42.0 N/kg) dominates all others on both objectives simultaneously.
This means there is no trade-off to optimize: the configuration that produces
the most lift also produces it most efficiently per kilogram of rotor mass.
The tilt profile has negligible effect at R=3.0m (all four profiles cluster
within 2%), confirming that polygon chain curvature — while physically real
after the solver correction — does not translate into a meaningful force
advantage. For design decisions, this implies: (1) build the largest rotor
radius the mechanical constraints allow, (2) stack as many rotors as the
line tension budget permits, and (3) do not over-invest in tilt profile
optimization — uniform tilt is within 2% of the theoretical optimum.
