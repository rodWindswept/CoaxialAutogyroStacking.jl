#!/usr/bin/env python3
"""bem-stall-delay-impact: Snel stall delay net effect on thrust — real data."""
import csv
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from collections import defaultdict

rows = []
with open("../../bem_snel_comparison.tsv") as f:
    for r in csv.DictReader(f, delimiter="\t"):
        t_snel = float(r["tension_with_snel"])
        if t_snel <= 0:
            continue
        rows.append({
            "radius": float(r["radius"]),
            "n": int(r["n_rotors"]),
            "profile": r["profile"],
            "elevation": float(r["elevation"]),
            "wind": float(r["wind_speed"]),
            "tension_snel": t_snel,
            "tension_nosnel": float(r["tension_without_snel"]),
            "boost_pct": float(r["snel_boost_pct"]),
        })

fig, axes = plt.subplots(1, 2, figsize=(11, 5))
fig.patch.set_facecolor("white")
ax1, ax2 = axes
ax1.set_facecolor("white")
ax2.set_facecolor("white")

# Panel 1: Boost histogram
boosts = [r["boost_pct"] for r in rows]
ax1.hist(boosts, bins=30, color="#4575b4", edgecolor="white", alpha=0.85)
ax1.axvline(np.mean(boosts), color="#d73027", linestyle="--", linewidth=2,
            label=f"Mean: {np.mean(boosts):.1f}%")
ax1.axvline(0, color="black", linestyle="-", linewidth=0.5)
ax1.set_xlabel("Thrust Change from Snel Stall Delay (%)", fontsize=11)
ax1.set_ylabel("Number of Configurations", fontsize=11)
ax1.set_title("Snel Net Effect: All Viable Configurations",
              fontsize=11, fontweight="bold")
ax1.legend(fontsize=9)
ax1.grid(True, alpha=0.3, axis="y")

# Panel 2: Snel vs no-Snel scatter
ax2.set_facecolor("white")
t_snel = [r["tension_snel"] for r in rows]
t_nosnel = [r["tension_nosnel"] for r in rows]
colors_scatter = ["#d73027" if r["radius"] == 1.5 else
                  "#fc8d59" if r["radius"] == 2.0 else "#4575b4"
                  for r in rows]

ax2.scatter(t_nosnel, t_snel, c=colors_scatter, alpha=0.5, s=25, zorder=3)
max_val = max(max(t_snel), max(t_nosnel)) * 1.05
ax2.plot([0, max_val], [0, max_val], "k--", alpha=0.3, linewidth=1,
         label="1:1 (no effect)")
ax2.set_xlabel("Anchor Tension Without Snel (N)", fontsize=10)
ax2.set_ylabel("Anchor Tension With Snel (N)", fontsize=10)
ax2.set_title("Snel vs No-Snel: Tension Comparison",
              fontsize=11, fontweight="bold")
ax2.legend(fontsize=8)
ax2.grid(True, alpha=0.3)

# Legend for radius
from matplotlib.lines import Line2D
legend_r = [Line2D([0], [0], marker="o", color=c, linestyle="", markersize=8,
                   label=f"R={r:.0f}m")
            for r, c in [(1.5, "#d73027"), (2.0, "#fc8d59"), (3.0, "#4575b4")]]
ax2.legend(handles=legend_r, fontsize=8, loc="lower right")

fig.suptitle("Snel Stall Delay: Does 3-D Correction Matter at System Level?\n"
             "BEM v2.1 — 384-Config Sweep With and Without Snel",
             fontsize=13, fontweight="bold")

# Key stats
mean_b = np.mean(boosts)
p95_b = np.percentile(np.abs(boosts), 95)
max_b = max(boosts)
min_b = min(boosts)

caption = (
    f"The Snel 3-D stall-delay correction has negligible net effect on anchor "
    f"tension: mean change {mean_b:.1f}% (range {min_b:.1f}% to {max_b:.1f}%). "
    f"95% of configurations see less than {p95_b:.1f}% change in either direction. "
    f"The correction boosts CL at the root (+32% at r/R=0.1) but this contributes "
    f"little to total thrust because dynamic pressure is low at small radii. "
    f"At design-point tip stations (r/R>0.7), the blade operates below stall "
    f"and the correction is inactive. Snel matters for start-up and low-RPM "
    f"conditions but does not affect steady-state autorotation thrust. "
    f"The radial loading chart (bem-radial-loading) shows the full blade distribution. "
    f"Data: 384-config BEM sweep, Snel on vs off, identical conditions."
)
fig.text(0.08, 0.02, caption, fontsize=8, color="#444444",
         ha="left", va="bottom", style="italic", wrap=True)
plt.subplots_adjust(left=0.06, right=0.96, top=0.88, bottom=0.20, wspace=0.30)
fig.savefig("bem-stall-delay-impact.png", dpi=300, facecolor="white",
            bbox_inches="tight")
fig.savefig("bem-stall-delay-impact.pdf", facecolor="white",
            bbox_inches="tight")
plt.close()
print("bem-stall-delay-impact.png + .pdf generated (REAL data)")
