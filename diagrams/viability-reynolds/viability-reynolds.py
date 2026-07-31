#!/usr/bin/env python3
"""viability-reynolds: Reynolds number distribution by radius."""
import csv, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

CHORD = 0.15; NU = 1.5e-5; RE_MIN = 5e4

rows = []
with open("../../bem_full_sweep.tsv") as f:
    for r in csv.DictReader(f, delimiter="\t"):
        t = float(r["anchor_tension"])
        if t <= 0:
            continue
        ts = float(r["tip_speed_bem"])
        rows.append({
            "radius": float(r["radius"]),
            "re": ts * CHORD / NU,
        })

fig, ax = plt.subplots(figsize=(8, 5))
fig.patch.set_facecolor("white"); ax.set_facecolor("white")

radii = [2.0, 3.0]
colors = {2.0: "#fc8d59", 3.0: "#4575b4"}

for rad in radii:
    re_vals = [r["re"] for r in rows if r["radius"] == rad]
    ax.hist(re_vals, bins=20, color=colors[rad], alpha=0.6,
            label=f"R={rad:.0f}m (mean {np.mean(re_vals):.0f})",
            edgecolor="white")

ax.axvline(RE_MIN, color="red", linestyle="--", linewidth=1.5,
           label=f"Re threshold ({RE_MIN:.0e})")
ax.set_xlabel("Tip Reynolds Number", fontsize=11)
ax.set_ylabel("Number of Configurations", fontsize=11)
ax.set_title("Reynolds Number Distribution by Rotor Radius\n"
             "BEM v2.1 — Viable Configurations",
             fontsize=12, fontweight="bold")
ax.legend(fontsize=9)
ax.grid(True, alpha=0.3, axis="y")

caption = (
    f"IMPLICATIONS: R=3.0m operates at Re = {np.mean([r['re'] for r in rows if r['radius']==3.0]):.0f} "
    f"(mean), comfortably above the {RE_MIN:.0e} transitional threshold. "
    f"R=2.0m operates at Re = {np.mean([r['re'] for r in rows if r['radius']==2.0]):.0f} "
    f"\u2014 marginal but viable at higher wind speeds. "
    f"R=1.5m (not shown) produces zero tension across all conditions. "
    f"The NACA 0012 data at Re = 10\u2075 is the lowest reliable table; "
    f"below this, laminar separation bubble effects are unpredictable. "
    f"Data: BEM v2.1, all wind speeds."
)
fig.text(0.10, 0.02, caption, fontsize=8, color="#444444",
         ha="left", va="bottom", style="italic", wrap=True)
plt.subplots_adjust(left=0.10, right=0.94, top=0.92, bottom=0.22)
fig.savefig("viability-reynolds.png", dpi=300, facecolor="white", bbox_inches="tight")
fig.savefig("viability-reynolds.pdf", facecolor="white", bbox_inches="tight")
plt.close()
print("viability-reynolds.png + .pdf generated")
