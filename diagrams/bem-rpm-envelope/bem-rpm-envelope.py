#!/usr/bin/env python3
"""bem-rpm-envelope: Autorotation RPM vs wind speed by rotor radius."""
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
        rpm = float(r["autorotation_rpm"])
        if t <= 0 or rpm <= 0:
            continue
        rows.append({
            "radius": float(r["radius"]),
            "n_rotors": int(r["n_rotors"]),
            "wind": float(r["wind_speed"]),
            "rpm": rpm,
        })

radii = sorted(set(r["radius"] for r in rows))
colors = {1.5: "#d73027", 2.0: "#fc8d59", 3.0: "#4575b4"}
ls = {1.5: ":", 2.0: "--", 3.0: "-"}

fig, ax = plt.subplots(figsize=(8, 5))
fig.patch.set_facecolor("white")
ax.set_facecolor("white")

for rad in radii:
    pts = defaultdict(list)
    for r in rows:
        if r["radius"] == rad:
            pts[r["wind"]].append(r["rpm"])
    winds = sorted(pts)
    means = [np.mean(pts[w]) for w in winds]
    lbl = f"R={rad:.1f}m" + (" (stalled)" if rad == 1.5 else "")
    ax.plot(winds, means, ls[rad], color=colors[rad], linewidth=2.2,
            marker="o", markersize=6, label=lbl)

ax.axhline(10, color="#999999", linestyle=":", linewidth=0.8)
ax.text(12.5, 12, "RPM floor", fontsize=8, color="#999999")

ax.set_xlabel("Wind Speed (m/s)", fontsize=11)
ax.set_ylabel("Autorotation RPM", fontsize=11)
ax.set_title("RPM Operating Envelope by Rotor Radius\nBEM v2.1 — All Stack Counts & Profiles",
             fontsize=12, fontweight="bold")
ax.legend(fontsize=9, framealpha=0.9)
ax.grid(True, alpha=0.3)

caption = (
    "IMPLICATIONS: R=1.5m rotors are stalled — RPM sits at the 10 RPM floor. "
    "R=2.0m+ rotors self-regulate via BEM torque equilibrium. R=3.0m reaches "
    "78–93 RPM at 8–12 m/s. RPM scales linearly with wind speed for R≥2.0m. "
    "Stack count and tilt profile have negligible effect on RPM — the autorotation "
    "speed is set by the torque balance at a given wind speed and radius. "
    "Data: BEM v2.1, corrected polygon solver. See SPEC.md §6.6."
)
fig.text(0.10, 0.02, caption, fontsize=8, color="#444444",
         ha="left", va="bottom", style="italic", wrap=True)
plt.subplots_adjust(left=0.10, right=0.94, top=0.92, bottom=0.22)
fig.savefig("bem-rpm-envelope.png", dpi=300, facecolor="white",
            bbox_inches="tight")
fig.savefig("bem-rpm-envelope.pdf", facecolor="white", bbox_inches="tight")
plt.close()
print("bem-rpm-envelope.png + .pdf generated")
