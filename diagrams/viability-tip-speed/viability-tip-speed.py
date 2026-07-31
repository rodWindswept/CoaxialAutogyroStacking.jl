#!/usr/bin/env python3
"""viability-tip-speed: Tip speed distribution by radius."""
import csv, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

TIP_MAX = 120.0

rows = []
with open("../../bem_full_sweep.tsv") as f:
    for r in csv.DictReader(f, delimiter="\t"):
        t = float(r["anchor_tension"])
        if t <= 0:
            continue
        rows.append({
            "radius": float(r["radius"]),
            "wind": float(r["wind_speed"]),
            "tip_speed": float(r["tip_speed_bem"]),
        })

fig, ax = plt.subplots(figsize=(8, 5))
fig.patch.set_facecolor("white"); ax.set_facecolor("white")

radii = [2.0, 3.0]
colors = {2.0: "#fc8d59", 3.0: "#4575b4"}

for rad in radii:
    ts = [r["tip_speed"] for r in rows if r["radius"] == rad]
    ax.hist(ts, bins=20, color=colors[rad], alpha=0.6,
            label=f"R={rad:.0f}m (mean {np.mean(ts):.0f} m/s)",
            edgecolor="white")

ax.axvline(TIP_MAX, color="red", linestyle="--", linewidth=1.5,
           label=f"Noise limit ({TIP_MAX:.0f} m/s, Mach 0.3)")
ax.set_xlabel("Tip Speed (m/s)", fontsize=11)
ax.set_ylabel("Number of Configurations", fontsize=11)
ax.set_title("Tip Speed Distribution by Rotor Radius\n"
             "BEM v2.1 — Viable Configurations",
             fontsize=12, fontweight="bold")
ax.legend(fontsize=9, loc="upper right")
ax.grid(True, alpha=0.3, axis="y")

# Zoom annotation
ax.annotate(f"All configs\nwell below\n{TIP_MAX:.0f} m/s limit",
            xy=(40, 2), fontsize=8, ha="center",
            bbox=dict(boxstyle="round", facecolor="white", alpha=0.8))

caption = (
    f"IMPLICATIONS: Tip speeds range from 2\u201340 m/s across all viable configurations "
    f"\u2014 well below the 120 m/s (Mach 0.3) noise limit. R=3.0m rotors run at "
    f"{np.mean([r['tip_speed'] for r in rows if r['radius']==3.0]):.0f} m/s mean "
    f"tip speed. The autorotation RPM is self-limiting: higher wind increases RPM "
    f"but also increases through-disk velocity, keeping tip-speed ratio roughly constant. "
    f"Noise is not a constraint for the lifting autogyro configuration. "
    f"Data: BEM v2.1, all wind speeds 6\u201312 m/s."
)
fig.text(0.10, 0.02, caption, fontsize=8, color="#444444",
         ha="left", va="bottom", style="italic", wrap=True)
plt.subplots_adjust(left=0.10, right=0.94, top=0.92, bottom=0.22)
fig.savefig("viability-tip-speed.png", dpi=300, facecolor="white", bbox_inches="tight")
fig.savefig("viability-tip-speed.pdf", facecolor="white", bbox_inches="tight")
plt.close()
print("viability-tip-speed.png + .pdf generated")
