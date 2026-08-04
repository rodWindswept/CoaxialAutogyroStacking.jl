# IMPLICATIONS.md — bem-cost-per-newton

Cost per newton improves with both rotor radius and stack count in the
BEM v2.1 graded-profile sweep. The best configuration is R=3.0 m, N=4
at $9.44/N — 18% cheaper per newton than the best single-rotor design
(R=2.0 m, N=1 at $11.57/N). Single rotors are the least cost-efficient
at every radius tested because the fixed $500 assembly overhead is not
shared across multiple units. N=2 is the threshold where larger rotors
become cheaper per newton than smaller ones — at N=1, R=2.0 m ($11.57/N)
is slightly cheaper than R=3.0 m ($11.72/N), but from N=2 upward,
R=3.0 m dominates. For manufacturing planning, the conclusion is clear:
build the largest practical rotor and stack as many as the line can
support. Every additional rotor improves the cost-per-newton figure.
The cost model is simplified and excludes labour, volume discounts,
and mixed-radius stacks. Real costs may differ by a factor of 2-3,
but the rank ordering across configurations should hold.
