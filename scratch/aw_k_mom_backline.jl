# scratch/aw_k_mom_backline.jl — aero-worker: derive k_mom from the backline geometry
# Open item (handover-2026-10-06-sky-anchor-node.md §7):
#   "Derive k_mom from the backline geometry (profile[1], segment lengths,
#    backline lever) instead of taking it as an input number."
#
# Side-of-band ruling input.  Machine pins (n_b = 3 re-base):
#   - fail band (0.21, 7.41) * I_t * omega^2  (aero-validator, replicated)
#   - 45 rpm: (58.80, 2073.34) N m/rad
#   - 121 rpm: (424.84, 14990.52) N m/rad
#   - slow root = 1P at k_mom = 3 * I_t * omega^2
#
# Geometry sources:
#   - schematics/DIMENSIONS.md: R = 3.0 m, rotor unit 4.2 kg, 4-stack anchor
#     tension 5,065 N, F_line = 1,294 N at the operating point.
#   - test/test_sky_anchor.jl: 6 mm Dyneema backline, L_b0 = 20 m,
#     EA_b = 1e6 N (soft 250 kN), anchor_mass = 50 kg, I_t = 12.6.
#   - The tube tie-rod is 0.8 m (DIMENSIONS.md).  The anchor segment lever
#     L_a is the node-to-rotor distance.  Parameterise it.
#
# v1 scope: first-order terms only.  Disk mounts rigidly on the segment
# (delta = 10 deg fixed).  Lines are vertical or near-vertical.  Geometric
# (taut-string) terms use small-angle force balance.

using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
using CoaxialAutogyroStacking

println("== replicate the n_b=3 pins ==")
I_t = 12.6
for rpm in (45.0, 121.0)
    k_stiff = whirl_stiffness_required(I_t, rpm; n_blades=3)
    println("  ", rpm, " rpm: k_stiff = ", round(k_stiff, digits=4))
end

# Band edges from the free side (c = 0.21) and the stiff side (c = 7.41).
println("== band edges and 1P slow-root limit ==")
for rpm in (45.0, 121.0)
    om = 2pi * rpm / 60.0
    k_free = 0.21 * I_t * om^2
    k_stiff = 7.41 * I_t * om^2
    k_1p = 3.0 * I_t * om^2
    println("  ", rpm, " rpm: free rail ", round(k_free, digits=2),
            " | stiff rail ", round(k_stiff, digits=2),
            " | slow root = 1P at ", round(k_1p, digits=2))
end

println("== free-pivot separation at n_b=3 ==")
for rpm in (45.0, 121.0)
    f0 = whirl_frequency(0.0, I_t, rpm)
    bpf = blade_passing_frequency(rpm; n_blades=3)
    sep = abs(f0 - bpf) / bpf
    println("  ", rpm, " rpm: f_whirl(0) = ", round(f0, digits=4),
            " Hz, BPF = ", bpf, " Hz, sep = ", round(sep, digits=5))
end

println("== slow root at the stiff rail (n_b=3) ==")
for rpm in (45.0, 121.0)
    om = 2pi * rpm / 60.0
    k_stiff = 7.41 * I_t * om^2
    f_slow = whirl_precession_frequency(k_stiff, I_t, rpm)
    println("  ", rpm, " rpm: f_slow = ", round(f_slow, digits=4),
            " Hz = ", round(f_slow / (rpm / 60.0), digits=2), "/rev")
end

# ---------------------------------------------------------------------------
# Derivation 1: the CoAx auto-gyro stack backline as modeled.
#
# The disk mounts rigidly on the hub.  The hub hangs below the node A on the
# anchor segment (lever L_a).  A string segment has no bending stiffness.
# The rocking stiffness about the node comes from three first-order terms:
#
#   1. k_pend  = m_rotor * g * L_a
#      Gravity pendulum of the tilting rotor unit about the node.
#   2. k_stack = T_below * L_a^2 / H
#      The taut stack line below R1 resists the hub's lateral offset
#      rho = L_a * beta with transverse stiffness T_below / H.
#   3. k_back  = (T_b0 / L_b0) * L_a^2
#      The taut backline resists the node's own lateral motion; the lever
#      to the hub converts it to a moment about the node.
# ---------------------------------------------------------------------------
function backline_k_mom(; m_rotor=4.2, L_a=0.8, T_below=1270.0, H=25.0,
                        T_b0=490.0, L_b0=20.0)
    k_pend = m_rotor * 9.81 * L_a
    k_stack = T_below * L_a^2 / H
    k_back = (T_b0 / L_b0) * L_a^2
    return (; k_pend, k_stack, k_back, k_total=k_pend + k_stack + k_back)
end

println("== derived backline k_mom (auto-gyro stack) ==")
# T_below just under R1: profile[2] of the test stack at v = 8 m/s.
r = AutogyroRotor(3.0, 0.05, 2, 0.15, 10.0, 0.0, 5.0)
st = AutogyroStack([r, r], [10.0, 15.0], 0.004, 55.0)
prof = stack_tension_profile(st, 1.225, 8.0)
T_below = prof[2]
println("  test-stack T_below (profile[2]) = ", round(T_below, digits=1), " N")

for L_a in (0.4, 0.8, 2.0)
    bk = backline_k_mom(L_a=L_a, T_below=T_below)
    println("  L_a = ", L_a, " m: k_pend ", round(bk.k_pend, digits=1),
            " | k_stack ", round(bk.k_stack, digits=1),
            " | k_back ", round(bk.k_back, digits=1),
            " | total ", round(bk.k_total, digits=1), " N m/rad")
end

println("== gate verdict for the derived k_mom ==")
for (L_a, rpm) in ((0.4, 45.0), (0.8, 45.0), (2.0, 45.0),
                   (0.4, 121.0), (0.8, 121.0), (2.0, 121.0))
    bk = backline_k_mom(L_a=L_a, T_below=T_below)
    f_w = whirl_frequency(bk.k_total, I_t, rpm)
    bpf = blade_passing_frequency(rpm; n_blades=3)
    sep = abs(f_w - bpf) / bpf
    verdict = sep >= 0.3 ? "pass" : "FAIL"
    println("  L_a=", L_a, " m @ ", rpm, " rpm: k = ", round(bk.k_total, digits=1),
            " N m/rad, sep = ", round(sep, digits=4), " -> ", verdict)
end

# ---------------------------------------------------------------------------
# Derivation 2: the polygon ring transmission as the backline (hex, n = 6).
#
# A bay of the polygon chain connects ring A (radius R) to ring B (radius R)
# with n vertical lines of length s, axial stiffness EA each.  Tilt ring A
# by beta about a diameter: vertex i moves R sin(theta_i) beta along the
# axis, stretching line i.  The restoring moment is
#
#   M = sum_i (EA / s) (R sin theta_i beta) (R sin theta_i)
#     = (EA / s) R^2 beta sum_i sin^2 theta_i
#     = (n / 2) EA R^2 beta / s
#
# so one bay has k_bay = (n/2) EA R^2 / s.  N bays in series
# (cantilever from the ground anchor) give
#
#   k_tip = k_bay / N = (n / 2) EA R^2 / H_chain,  H_chain = s N.
#
# The factor sum sin^2 = 0 (n=2), 3/2 (n=3), 3 (n=6) matches the
# science-worker geometry.  Rod's tested stable machine is the 6-line hex.
# ---------------------------------------------------------------------------
function hex_k_mom(; n_lines=6, EA=2.5e5, R=3.0, H_chain=25.0)
    return (n_lines / 2.0) * EA * R^2 / H_chain
end

println("== hex transmission k_tip ==")
for (EA, label) in ((2.5e5, "soft 250 kN"), (1.0e6, "elastic 1 MN"))
    for H in (25.0, 60.0, 200.0)
        k = hex_k_mom(EA=EA, H_chain=H)
        println("  ", label, ", H_chain = ", H, " m: k_tip = ",
                round(k / 1.0e3, digits=2), " kN m/rad")
    end
end

println("== hex crossing lengths (k_tip = stiff rail) ==")
for rpm in (45.0, 121.0)
    om = 2pi * rpm / 60.0
    k_req = whirl_stiffness_required(I_t, rpm; n_blades=3)
    H_soft = hex_k_mom(EA=2.5e5, H_chain=1.0) / k_req
    H_el = hex_k_mom(EA=1.0e6, H_chain=1.0) / k_req
    println("  ", rpm, " rpm (k_req = ", round(k_req, digits=2),
            "): soft clears below ", round(H_soft, digits=1),
            " m, elastic below ", round(H_el, digits=1), " m")
end

println("== hex machine: whirl + slow root at both rates ==")
for rpm in (45.0, 121.0)
    om = 2pi * rpm / 60.0
    k = hex_k_mom(EA=2.5e5, H_chain=25.0)
    f_w = whirl_frequency(k, I_t, rpm)
    f_s = whirl_precession_frequency(k, I_t, rpm)
    bpf = blade_passing_frequency(rpm; n_blades=3)
    sep = abs(f_w - bpf) / bpf
    println("  ", rpm, " rpm: k = ", round(k / 1.0e3, digits=1),
            " kN m/rad, f_whirl = ", round(f_w, digits=2),
            " Hz (", round(f_w / (rpm / 60.0), digits=2), "/rev), sep = ",
            round(sep, digits=3), " -> ", sep >= 0.3 ? "pass" : "FAIL",
            ", f_slow = ", round(f_s, digits=2), " Hz")
end
