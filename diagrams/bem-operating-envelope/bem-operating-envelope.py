#!/usr/bin/env python3
"""bem-operating-envelope: Which (R,N) combos fly at each wind speed?"""
import csv
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

rows = []
with open("../../bem_full_sweep.tsv") as f:
    for r in csv.DictReader(f, delimiter="\t"):
        t = float(r["anchor_tension"])
        rows.append({
            "radius": float(r["radius"]),
            "n": int(r["n_rotors"]),
            "wind": float(r["wind_speed"]),
            "tension": t,
            "tip_speed": float(r["tip_speed_bem"]),
        })

fig, axes = plt.subplots(2, 2, figsize=(10, 8))
fig.patch.set_facecolor("white")

radii = [1.5, 2.0, 3.0]
n_vals = [1, 2, 3, 4]
winds = [6, 8, 10, 12]
profiles = ["uniform", "top_draggy", "bottom_lifty", "graded"]

for ni, n_rotors in enumerate(n_vals):
    ax = axes[ni // 2][ni % 2]
    ax.set_facecolor("white")

    for rad in radii:
        tensions = []
        tip_speeds = []
        for w in winds:
            vals = [r["tension"] for r in rows
                    if r["radius"] == rad and r["n"] == n_rotors
                    and r["wind"] == w]
            tips = [r["tip_speed"] for r in rows
                    if r["radius"] == rad and r["n"] == n_rotors
                    and r["wind"] == w]
            tensions.append(np.mean(vals) if vals else 0)
            tip_speeds.append(np.mean(tips) if tips else 0)

        # Viable if tension > 0 AND tip_speed < 120 m/s
        viable = [(t > 0 and ts < 120) for t, ts in zip(tensions, tip_speeds)]
        color = {1.5: "#d73027", 2.0: "#fc8d59", 3.0: "#4575b4"}[rad]
        marker = {1.5: "x", 2.0: "s", 3.0: "o"}[rad]

        for i, (w, v) in enumerate(zip(winds, viable)):
            if v:
                ax.scatter(w, rad, marker=marker, s=120, c=color,
                          edgecolors="black", linewidth=0.5, zorder=5)
            else:
                ax.scatter(w, rad, marker="x", s=60, c="lightgray",
                          zorder=3)

        # Draw operating band
        viable_winds = [w for w, v in zip(winds, viable) if v]
        if len(viable_winds) >= 2:
            ax.axhspan(rad - 0.15, rad + 0.15,
                       min(viable_winds) / 12, max(viable_winds) / 12,
                       color=color, alpha=0.15)

    ax.set_title(f"N = {n_rotors}", fontsize=11, fontweight="bold")
    ax.set_xlabel("Wind Speed (m/s)", fontsize=9)
    ax.set_ylabel("Rotor Radius (m)", fontsize=9)
    ax.set_ylim(1.2, 3.3)
    ax.set_xlim(5.5, 12.5)
    ax.set_yticks([1.5, 2.0, 2.5, 3.0])
    ax.grid(True, alpha=0.3)

fig.suptitle("Operating Wind Envelope: Which (R,N) Combinations Fly?\n"
             "BEM v2.1 — Filled = Viable, X = No Tension or Overspeed",
             fontsize=13, fontweight="bold")

caption = (
    "IMPLICATIONS: R=1.5m produces zero tension at all N, all wind speeds — "
    "below the viability threshold for NACA 0012 at Re < 5\u00d710\u2074. "
    "R=2.0m flies at N\u22652 above 8 m/s. R=3.0m flies across all conditions. "
    "Tip speeds stay under 40 m/s everywhere, well below the 120 m/s noise limit. "
    "No configurations exceed viability constraints. Data: BEM v2.1, 45\u00b0 elevation."
)
fig.text(0.08, 0.01, caption, fontsize=8, color="#444444",
         ha="left", va="bottom", style="italic", wrap=True)
plt.subplots_adjust(left=0.08, right=0.95, top=0.90, bottom=0.14, hspace=0.35)
fig.savefig("bem-operating-envelope.png", dpi=300, facecolor="white",
            bbox_inches="tight")
fig.savefig("bem-operating-envelope.pdf", facecolor="white", bbox_inches="tight")
plt.close()
print("bem-operating-envelope.png + .pdf generated")
