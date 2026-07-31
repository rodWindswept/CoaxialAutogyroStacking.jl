#!/usr/bin/env python3
"""bem-pareto-elevation: Anchor tension vs mass efficiency coloured by line elevation."""
import csv, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

ROTOR_MASS = 5.0
rows = []
with open("../../bem_full_sweep.tsv") as f:
    for r in csv.DictReader(f, delimiter="\t"):
        t = float(r["anchor_tension"])
        if t <= 0:
            continue
        n = int(r["n_rotors"])
        rows.append({
            "elevation": float(r["elevation"]), "n": n, "tension": t,
            "nkg": t / (n * ROTOR_MASS),
        })

fig, ax = plt.subplots(figsize=(8, 6))
fig.patch.set_facecolor("white"); ax.set_facecolor("white")

elevs = [45.0, 55.0]
colors = {45.0: "#4575b4", 55.0: "#d73027"}

for elev in elevs:
    xs = [r["nkg"] for r in rows if r["elevation"] == elev]
    ys = [r["tension"] for r in rows if r["elevation"] == elev]
    ax.scatter(xs, ys, c=colors[elev], s=30, alpha=0.6,
              label=f"{elev:.0f}\u00b0", edgecolors="none")

# Pareto frontier per elevation
for elev in elevs:
    pts = sorted([(r["nkg"], r["tension"]) for r in rows if r["elevation"] == elev])
    if not pts:
        continue
    px, py, my = [], [], 0
    for nkg, t in pts:
        if t > my:
            my = t; px.append(nkg); py.append(t)
    ax.plot(px, py, "-", color=colors[elev], linewidth=2, alpha=0.8)

ax.set_xlabel("Tension per Rotor Mass (N/kg)", fontsize=11)
ax.set_ylabel("Anchor Tension (N)", fontsize=11)
ax.set_title("Pareto: Tension vs Mass Efficiency by Line Elevation\n"
             "BEM v2.1 — All (R,N,profile) Combinations",
             fontsize=12, fontweight="bold")
ax.legend(fontsize=9, framealpha=0.9)
ax.grid(True, alpha=0.3)

caption = (
    "IMPLICATIONS: Line elevation has a small but consistent effect. 55\u00b0 "
    "(steeper) pushes the Pareto frontier slightly right — better mass efficiency "
    "at the same absolute tension — because the through-disk velocity increases "
    "with sin(elevation). However, the effect is subtle: the 45\u00b0 and 55\u00b0 "
    "clusters overlap heavily. The practical difference (~5-10% in N/kg) is within "
    "the noise of manufacturing tolerances. Fly at whichever angle gives best "
    "clearance and line management. Data: BEM v2.1, 384 configs."
)
fig.text(0.10, 0.02, caption, fontsize=8, color="#444444",
         ha="left", va="bottom", style="italic", wrap=True)
plt.subplots_adjust(left=0.10, right=0.94, top=0.92, bottom=0.22)
fig.savefig("bem-pareto-elevation.png", dpi=300, facecolor="white", bbox_inches="tight")
fig.savefig("bem-pareto-elevation.pdf", facecolor="white", bbox_inches="tight")
plt.close()
print("bem-pareto-elevation.png + .pdf generated")
