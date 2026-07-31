#!/usr/bin/env python3
"""sweep-profile-nkg + sweep-profile-cv: Bar charts by tilt profile (PCA-2)."""
import csv, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from collections import defaultdict

ROTOR_MASS = 5.0

rows = []
with open("../../bem_full_sweep_pca2.tsv") as f:
    for r in csv.DictReader(f, delimiter="\t"):
        t = float(r["anchor_tension"])
        if t <= 0:
            continue
        n = int(r["n_rotors"])
        rows.append({
            "profile": r["profile"], "n": n, "tension": t,
            "wind": float(r["wind_speed"]),
            "nkg": t / (n * ROTOR_MASS),
        })

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(10, 5))
fig.patch.set_facecolor("white")
ax1.set_facecolor("white"); ax2.set_facecolor("white")

profiles = ["uniform", "top_draggy", "bottom_lifty", "graded"]
colors = {"uniform": "#4575b4", "top_draggy": "#d73027",
          "bottom_lifty": "#1a9850", "graded": "#fc8d59"}

# Left: N/kg by profile
nkg_means = [np.mean([r["nkg"] for r in rows if r["profile"] == p]) for p in profiles]
bars1 = ax1.bar(range(4), nkg_means, color=[colors[p] for p in profiles],
                edgecolor="white")
for b, v in zip(bars1, nkg_means):
    ax1.text(b.get_x() + b.get_width() / 2, b.get_height() + 0.5,
             f"{v:.1f}", ha="center", fontsize=10, fontweight="bold")
ax1.set_xticks(range(4))
ax1.set_xticklabels(profiles, rotation=15, fontsize=8)
ax1.set_ylabel("Tension per Rotor Mass (N/kg)", fontsize=10)
ax1.set_title("Mass Efficiency by Tilt Profile", fontsize=11, fontweight="bold")
ax1.grid(True, alpha=0.3, axis="y")

# Right: CV by profile
groups = defaultdict(list)
for r in rows:
    groups[(r["profile"], r["wind"])].append(r["tension"])

# Compute CV per profile across wind speeds
cv_data = {}
for prof in profiles:
    means_by_wind = []
    for w in [6, 8, 10, 12]:
        vals = [r["tension"] for r in rows if r["profile"] == prof and r["wind"] == w]
        if vals:
            means_by_wind.append(np.mean(vals))
    cv_data[prof] = np.std(means_by_wind) / np.mean(means_by_wind) * 100 if means_by_wind and np.mean(means_by_wind) > 0 else 0

cv_vals = [cv_data[p] for p in profiles]
bars2 = ax2.bar(range(4), cv_vals, color=[colors[p] for p in profiles],
                edgecolor="white")
for b, v in zip(bars2, cv_vals):
    ax2.text(b.get_x() + b.get_width() / 2, b.get_height() + 0.2,
             f"{v:.1f}%", ha="center", fontsize=10, fontweight="bold")
ax2.set_xticks(range(4))
ax2.set_xticklabels(profiles, rotation=15, fontsize=8)
ax2.set_ylabel("CV of Tension Across Wind Speeds (%)", fontsize=10)
ax2.set_title("Gust Stability by Tilt Profile\n(lower is better)",
              fontsize=11, fontweight="bold")
ax2.grid(True, alpha=0.3, axis="y")

fig.suptitle("PCA-2: Tilt Profile Comparison — Mass Efficiency & Gust Stability\n"
             "PCA-2 Disk Model — Mean Across All (R,N,elevation)",
             fontsize=13, fontweight="bold")

caption = (
    "IMPLICATIONS: The PCA-2 model shows small differences between tilt profiles "
    "in both N/kg (<3% spread) and CV (<2% spread). The tilt profile is a "
    "second-order effect in the PCA-2 disk model. BEM v2.1 with polygon line "
    "geometry shows larger profile effects because segment angle coupling "
    "amplifies tilt differences. Data: PCA-2 disk model."
)
fig.text(0.08, 0.02, caption, fontsize=8, color="#444444",
         ha="left", va="bottom", style="italic", wrap=True)
plt.subplots_adjust(left=0.06, right=0.96, top=0.88, bottom=0.18, wspace=0.30)

# Save as two separate PNGs for the one-diagram-per-figure rule
# sweep-profile-nkg
extent1 = ax1.get_window_extent().transformed(fig.dpi_scale_trans.inverted())
fig.savefig("sweep-profile-nkg.png", dpi=300, facecolor="white",
            bbox_inches=extent1.expanded(1.3, 1.3))
# sweep-profile-cv
extent2 = ax2.get_window_extent().transformed(fig.dpi_scale_trans.inverted())
fig.savefig("sweep-profile-cv.png", dpi=300, facecolor="white",
            bbox_inches=extent2.expanded(1.3, 1.3))

fig.savefig("sweep-profile-comparison.png", dpi=300, facecolor="white",
            bbox_inches="tight")
plt.close()
print("sweep-profile-nkg.png + sweep-profile-cv.png generated")
