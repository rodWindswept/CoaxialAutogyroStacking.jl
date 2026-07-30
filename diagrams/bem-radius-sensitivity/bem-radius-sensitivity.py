#!/usr/bin/env python3
"""bem-radius-sensitivity: Anchor tension vs rotor radius at fixed stack count."""
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

colors = {1: "#fee090", 2: "#fc8d59", 3: "#d73027", 4: "#4575b4"}
markers = {6: "v", 8: "o", 10: "s", 12: "D"}

for n in [1, 2, 3, 4]:
    for ws in [6, 8, 10, 12]:
        pts = defaultdict(list)
        for r in rows:
            if r["n"] == n and r["wind"] == ws:
                pts[r["radius"]].append(r["tension"])
        rads = sorted(pts)
        means = [np.mean(pts[rad]) for rad in rads]
        lbl = f"N={n}, {ws} m/s" if ws == 8 else None
        if ws == 8:
            ax.plot(rads, means, "o-", color=colors[n], linewidth=2,
                    markersize=8, label=lbl)

# Add R² reference line
r2_ref = np.array([1.5, 2.0, 3.0])
ax.plot(r2_ref, [180, 320, 720], "k--", linewidth=1, alpha=0.4,
        label="R² reference")

ax.set_xlabel("Rotor Radius (m)", fontsize=11)
ax.set_ylabel("Anchor Tension at 8 m/s (N)", fontsize=11)
ax.set_title("Radius Sensitivity: Tension vs Rotor Radius\n"
             "BEM v2.1 — Graded Tilt, 8 m/s, 45° Elevation",
             fontsize=12, fontweight="bold")
ax.legend(fontsize=9, framealpha=0.9)
ax.grid(True, alpha=0.3)

caption = (
    "IMPLICATIONS: Anchor tension scales faster than disk area (R²). "
    "R=3.0m delivers 4.5× the tension of R=2.0m at the same N=4. "
    "R=1.5m produces zero tension — below autorotation threshold. "
    "The scaling is super-linear: BEM induction captures the nonlinear "
    "benefit of higher Reynolds numbers on larger rotors. "
    "Data: BEM v2.1, graded profile, 8 m/s, 45° elevation. See SPEC.md §6.6."
)
fig.text(0.10, 0.02, caption, fontsize=8, color="#444444",
         ha="left", va="bottom", style="italic", wrap=True)
plt.subplots_adjust(left=0.10, right=0.94, top=0.92, bottom=0.22)
fig.savefig("bem-radius-sensitivity.png", dpi=300, facecolor="white",
            bbox_inches="tight")
fig.savefig("bem-radius-sensitivity.pdf", facecolor="white", bbox_inches="tight")
plt.close()
print("bem-radius-sensitivity.png + .pdf generated")
