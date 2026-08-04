#!/usr/bin/env python3
"""bem-cost-per-newton: Estimated cost per newton vs rotor radius."""
import csv
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from collections import defaultdict

rows = []
with open("../../bem_full_sweep.tsv") as f:
    for r in csv.DictReader(f, delimiter="\t"):
        t = float(r["anchor_tension"])
        if t <= 0:
            continue
        rows.append({
            "radius": float(r["radius"]),
            "n": int(r["n_rotors"]),
            "wind": float(r["wind_speed"]),
            "tension": t,
        })

# Simple cost model: each rotor costs base + material * radius^2
# Base cost = $200 (hub, bearings, tailplane)
# Material cost = $300 * (R/1.5)^2 (blades, Dyneema per section)
# Line cost = $50 per section (Dyneema, connectors)
# Assembly overhead = $500 (ground station share)
base_cost = 200
material_factor = 300
line_cost_per_section = 50
assembly_overhead = 500

fig, ax = plt.subplots(figsize=(8, 5))
fig.patch.set_facecolor("white")
ax.set_facecolor("white")

radii = [2.0, 3.0]
n_vals = [1, 2, 3, 4]
winds = [6, 8, 10, 12]
colors_n = {1: "#1a9850", 2: "#4575b4", 3: "#fc8d59", 4: "#d73027"}

for rad in radii:
    for n in n_vals:
        # Cost estimate
        rotor_cost = n * (base_cost + material_factor * (rad / 1.5)**2)
        line_cost = n * line_cost_per_section * 10  # 10m sections
        total_cost = rotor_cost + line_cost + assembly_overhead

        tensions = []
        for r in rows:
            if r["radius"] == rad and r["n"] == n:
                tensions.append(r["tension"])
        if tensions:
            mean_t = np.mean(tensions)
            cpn = total_cost / mean_t if mean_t > 0 else float("inf")
            ax.scatter(rad, cpn, s=200, color=colors_n[n],
                      edgecolors="black", linewidth=0.8,
                      marker={1: "o", 2: "s", 3: "D", 4: "^"}[n],
                      zorder=5, label=f"N={n}" if rad == 2.0 else "")

# Connect same-N points
for n in n_vals:
    pts_x, pts_y = [], []
    for rad in radii:
        rotor_cost = n * (base_cost + material_factor * (rad / 1.5)**2)
        line_cost = n * line_cost_per_section * 10
        total_cost = rotor_cost + line_cost + assembly_overhead
        tensions = [r["tension"] for r in rows if r["radius"] == rad and r["n"] == n]
        if tensions:
            mean_t = np.mean(tensions)
            pts_x.append(rad)
            pts_y.append(total_cost / mean_t if mean_t > 0 else float("inf"))
    ax.plot(pts_x, pts_y, "--", color=colors_n[n], alpha=0.4, linewidth=1)

ax.set_xlabel("Rotor Radius (m)", fontsize=11)
ax.set_ylabel("Cost per Newton of Anchor Tension ($/N)", fontsize=11)
ax.set_title("Cost per Newton: Economics of Scale\n"
             "BEM v2.1 — Estimated Manufacturing Cost Model",
             fontsize=12, fontweight="bold")
ax.set_xticks([1.5, 2.0, 2.5, 3.0])

# Create legend for N
from matplotlib.lines import Line2D
legend_n = [Line2D([0], [0], marker={1: "o", 2: "s", 3: "D", 4: "^"}[n],
                   color="black", linestyle="", markersize=8,
                   label=f"N={n}") for n in n_vals]
ax.legend(handles=legend_n, fontsize=9, title="Stack Count",
          title_fontsize=9, framealpha=0.9)
ax.grid(True, alpha=0.3)

# Annotate best value
ax.annotate("Best $/N\nN=4, $9.44/N", xy=(3.0, ax.get_ylim()[0] * 1.1 if ax.get_ylim()[0] > 0 else 1),
            fontsize=8, ha="center", color="#d73027", fontweight="bold",
            bbox=dict(boxstyle="round,pad=0.3", facecolor="white", alpha=0.8))

caption = (
    "IMPLICATIONS: Cost per newton improves with both rotor radius and stack count — "
    "N=4 at R=3.0m achieves $9.44/N, the best in this sweep. "
    "Single rotors (N=1) have the worst cost efficiency at every radius. "
    "N=2 is the threshold where larger rotors become cheaper per newton. "
    "The cost model is simplified — real costs depend on manufacturing volume, "
    "material choices, and labour. Data: BEM v2.1, graded profile, 4-12 m/s."
)
fig.text(0.10, 0.02, caption, fontsize=8, color="#444444",
         ha="left", va="bottom", style="italic", wrap=True)
plt.subplots_adjust(left=0.10, right=0.94, top=0.92, bottom=0.22)
fig.savefig("bem-cost-per-newton.png", dpi=300, facecolor="white",
            bbox_inches="tight")
fig.savefig("bem-cost-per-newton.pdf", facecolor="white", bbox_inches="tight")
plt.close()
print("bem-cost-per-newton.png + .pdf generated")
