#!/usr/bin/env julia
# compute_radial_loading.jl — extract CL_2D and CL_3D at each BEM station
# Run: julia --project=../.. compute_radial_loading.jl
# Outputs: radial_loading.csv

using CoaxialAutogyroStacking

const RHO = 1.225
const MU = 1.81e-5

# Best config from sweep
r_best = 3.0
n_blades = 2
chord = 0.15
tilt_deg = 5.0  # top rotor tilt
elev_deg = 45.0
v_wind = 8.0

rotor = AutogyroRotor(r_best, r_best * 0.05, n_blades, chord, tilt_deg, 0.0, 5.0)
α_eff = effective_alpha(rotor, elev_deg)
v_through = v_wind * sind(α_eff)

# Get autorotation RPM
rpm = bem_autorotation_rpm(rotor, RHO, v_through)
omega = rpm * 2π / 60.0
v_tip = omega * r_best
tsr = v_tip / v_wind

N_STATIONS = 20
dr = (rotor.radius - rotor.hub_radius) / N_STATIONS

open("radial_loading.csv", "w") do io
    write(io, "r_R,r_local,cl_2d,cl_3d,aoa_deg,re_local\n")
    
    for i in 1:N_STATIONS
        r_i = rotor.hub_radius + (i - 0.5) * dr
        r_R = r_i / rotor.radius
        
        # Local Reynolds
        Re_local = RHO * (omega * r_i) * chord / MU
        
        # Induction iteration (simplified: fixed a=0.3)
        a = 0.3
        for _ in 1:20
            v_rel = v_through / sind(α_eff)  # approx
            phi = atand(v_through * (1 - a), omega * r_i * (1 + a))
            aoa = phi - tilt_deg  # approx: ϕ - blade pitch
            cl_2d = naca0012_cl(aoa, Re_local)
            cd_2d = naca0012_cd(aoa, Re_local)
            
            sigma = rotor.blade_chord * n_blades / (2π * r_i)
            Cn = cl_2d * cosd(phi) + cd_2d * sind(phi)
            Ct = cl_2d * sind(phi) - cd_2d * cosd(phi)
            
            f = sigma * Cn / (4 * sind(phi)^2)
            a_new = f / (1 + f)
            if abs(a_new - a) < 1e-4
                a = a_new
                break
            end
            a = a_new
        end
        
        # Local angle of attack
        phi = atand(v_through * (1 - a), omega * r_i * (1 + a))
        aoa = phi - tilt_deg
        
        # 2D CL
        cl_2d = naca0012_cl(aoa, Re_local)
        
        # 3D CL via Snel correction
        c_over_r = chord / r_i
        local_tsr = omega * r_i / v_through
        cl_3d = snel_cl_3d(cl_2d, aoa, local_tsr, c_over_r)
        
        write(io, "$r_R,$r_i,$cl_2d,$cl_3d,$aoa,$Re_local\n")
    end
end

println("radial_loading.csv written — $N_STATIONS stations, RPM=$rpm")
