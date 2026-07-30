#!/usr/bin/env python3
"""bem-stack-efficiency: Anchor tension vs stack count at fixed radius."""
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

fig, ax = plt.subplots(figsize=(8, 5))
fig.patch.set_facecolor("white")
ax.set_facecolor("white")

colors = {1.5: "#d73027", 2.0: "#fc8d59", 3.0: "#4575b4"}
markers = {6: "v", 8: "o", 10: "s", 12: "D"}

for rad in [2.0, 3.0]:
    for ws in [6, 8, 10, 12]:
        pts = defaultdict(list)
        for r in rows:
            if r["radius"] == rad and r["wind"] == ws:
                pts[r["n"]].append(r["tension"])
        ns = sorted(pts)
        means = [np.mean(pts[n]) for n in ns]
        lbl = f"R={rad:.0f}m, {ws} m/s" if rad == 3.0 else None
        ax.plot(ns, means, "-", color=colors[rad], alpha=0.3 + ws / 20,
                linewidth=1.5, marker=markers[ws], markersize=7,
                label=lbl)
        if rad == 2.0:
            ax.plot(ns, means, "-", color=colors[rad], alpha=0.3 + ws / 20,
                    linewidth=1.5, marker=markers[ws], markersize=7)

ax.set_xlabel("Number of Rotors in Stack", fontsize=11)
ax.set_ylabel("Anchor Tension (N)", fontsize=11)
ax.set_title("Stack Efficiency: Does Adding Rotors Scale Linearly?\n"
             "BEM v2.1 — Graded Tilt, 45° Elevation",
             fontsize=12, fontweight="bold")
ax.set_xticks([1, 2, 3, 4])

# Legend: wind speeds
from matplotlib.lines import Line2D
legend_ws = [Line2D([0], [0], color="black", marker=m, linestyle="-",
                    label=f"{w} m/s") for w, m in markers.items()]
ax.legend(handles=legend_ws, fontsize=9, title="Wind Speed",
          title_fontsize=9, framealpha=0.9)
ax.grid(True, alpha=0.3)

caption = (
    "IMPLICATIONS: Anchor tension scales linearly with stack count at R=2.0m. "
    "At R=3.0m, N=1 struggles to autorotate at low wind but N≥2 scales well. "
    "Each additional rotor adds 150–320 N of tension depending on wind speed. "
    "The stack does not saturate at N=4 — more rotors would add more lift. "
    "Practical limits: line weight, cost, and tower height. "
    "Data: BEM v2.1, graded profile, 45° elevation. See SPEC.md §6.6."
)
fig.text(0.10, 0.02, caption, fontsize=8, color="#444444",
         ha="left", va="bottom", style="italic", wrap=True)
plt.subplots_adjust(left=0.10, right=0.94, top=0.92, bottom=0.22)
fig.savefig("bem-stack-efficiency.png", dpi=300, facecolor="white",
            bbox_inches="tight")
fig.savefig("bem-stack-efficiency.pdf", facecolor="white", bbox_inches="tight")
plt.close()
print("bem-stack-efficiency.png + .pdf generated")
