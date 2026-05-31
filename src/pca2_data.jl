# src/pca2_data.jl — PCA-2 empirical autogyro rotor disk data
# Data from NASA TM 20080022367: PCA-2 autogyro wind tunnel tests
# CL and CD normalised to disk area and freestream dynamic pressure

const PCA2_ALPHA = [0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 30.0, 35.0, 40.0,
                    45.0, 50.0, 60.0, 70.0, 80.0, 90.0]
const PCA2_CL    = [0.00, 0.15, 0.30, 0.45, 0.60, 0.75, 0.85, 0.92, 0.95,
                    0.90, 0.82, 0.65, 0.45, 0.25, 0.00]
const PCA2_CD    = [0.01, 0.03, 0.06, 0.10, 0.16, 0.24, 0.35, 0.48, 0.62,
                    0.75, 0.86, 0.96, 1.05, 1.15, 1.25]

"""
    pca2_interp(alpha_deg)

Linearly interpolates the PCA-2 empirical CL and CD values for a given
disk angle of attack α in degrees.  Input is clamped to [0°, 90°].

Returns `(cl, cd)`.
"""
function pca2_interp(alpha_deg)
    a = clamp(alpha_deg, 0.0, 90.0)
    for i in 1:(length(PCA2_ALPHA) - 1)
        if a <= PCA2_ALPHA[i+1]
            t = (a - PCA2_ALPHA[i]) / (PCA2_ALPHA[i+1] - PCA2_ALPHA[i])
            return PCA2_CL[i] + t * (PCA2_CL[i+1] - PCA2_CL[i]),
                   PCA2_CD[i] + t * (PCA2_CD[i+1] - PCA2_CD[i])
        end
    end
    return PCA2_CL[end], PCA2_CD[end]
end
