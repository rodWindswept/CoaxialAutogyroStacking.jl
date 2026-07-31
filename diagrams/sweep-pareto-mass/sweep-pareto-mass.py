#!/usr/bin/env python3
"""sweep-pareto-mass: PCA-2 Pareto: Tension vs mass efficiency."""
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
            "radius": float(r["radius"]), "n": n,
            "profile": r["profile"], "tension": t,
            "nkg": t / (n * ROTOR_MASS),
        })

fig, ax = plt.subplots(figsize=(8, 6))
fig.patch.set_facecolor("white"); ax.set_facecolor("white")

radii = [1.5, 2.0, 3.0]
colors = {1.5: "#d73027", 2.0: "#fc8d59", 3.0: "#4575b4"}

for rad in radii:
    xs = [r["nkg"] for r in rows if r["radius"] == rad]
    ys = [r["tension"] for r in rows if r["radius"] == rad]
    ax.scatter(xs, ys, c=colors[rad], s=25, alpha=0.5,
              label=f"R={rad:.1f}m", edgecolors="none")

# Pareto frontier
pts = sorted([(r["nkg"], r["tension"]) for r in rows])
px = []
py = []
my = 0
for nkg, t in pts:
    if t > my:
        my = t
        px.append(nkg)
        py.append(t)
ax.plot(px, py, "k-", linewidth=2, alpha=0.5, label="Pareto front")

ax.set_xlabel("Tension per Rotor Mass (N/kg)", fontsize=11)
ax.set_ylabel("Anchor Tension (N)", fontsize=11)
ax.set_title("PCA-2 Pareto: Tension vs Mass Efficiency\n"
             "PCA-2 Disk Model — All (N,profile,elevation) Combinations",
             fontsize=12, fontweight="bold")
ax.legend(fontsize=9)
ax.grid(True, alpha=0.3)

caption = (
    "The PCA-2 disk model shows a clear Pareto frontier. R=3.0m dominates "
    "absolute tension. R=1.5m achieves the highest N/kg. "
    "Compare with bem-pareto-radius (BEM v2.1) to see the fidelity difference. "
    "PCA-2 overestimates forces \u2014 the BEM version is the design truth. "
    "Data: PCA-2 disk model, 384 configs."
)
fig.text(0.10, 0.02, caption, fontsize=8, color="#444444",
         ha="left", va="bottom", style="italic", wrap=True)
plt.subplots_adjust(left=0.10, right=0.94, top=0.92, bottom=0.22)
fig.savefig("sweep-pareto-mass.png", dpi=300, facecolor="white", bbox_inches="tight")
fig.savefig("sweep-pareto-mass.pdf", facecolor="white", bbox_inches="tight")
plt.close()
print("sweep-pareto-mass.png + .pdf generated")
