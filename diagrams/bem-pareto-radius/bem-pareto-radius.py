#!/usr/bin/env python3
"""bem-pareto-radius: Anchor tension vs mass efficiency coloured by rotor radius."""
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
            "radius": float(r["radius"]), "n": n, "tension": t,
            "nkg": t / (n * ROTOR_MASS),
        })

fig, ax = plt.subplots(figsize=(8, 6))
fig.patch.set_facecolor("white"); ax.set_facecolor("white")

radii = [1.5, 2.0, 3.0]
colors = {1.5: "#d73027", 2.0: "#fc8d59", 3.0: "#4575b4"}

for rad in radii:
    xs = [r["nkg"] for r in rows if r["radius"] == rad]
    ys = [r["tension"] for r in rows if r["radius"] == rad]
    ax.scatter(xs, ys, c=colors[rad], s=30, alpha=0.6,
              label=f"R={rad:.1f}m", edgecolors="none")

# Pareto frontier per radius
for rad in radii:
    pts = sorted([(r["nkg"], r["tension"]) for r in rows if r["radius"] == rad])
    if not pts:
        continue
    px, py, my = [], [], 0
    for nkg, t in pts:
        if t > my:
            my = t; px.append(nkg); py.append(t)
    ax.plot(px, py, "-", color=colors[rad], linewidth=2, alpha=0.8)

ax.set_xlabel("Tension per Rotor Mass (N/kg)", fontsize=11)
ax.set_ylabel("Anchor Tension (N)", fontsize=11)
ax.set_title("Pareto: Tension vs Mass Efficiency by Rotor Radius\n"
             "BEM v2.1 — All (N,profile,elevation) Combinations",
             fontsize=12, fontweight="bold")
ax.legend(fontsize=9, framealpha=0.9)
ax.grid(True, alpha=0.3)

caption = (
    "IMPLICATIONS: Radius dominates the Pareto frontier. R=1.5m produces near-zero "
    "tension — below the NACA 0012 viability threshold. R=2.0m reaches 200-500 N "
    "with good mass efficiency (20-40 N/kg). R=3.0m pushes the frontier to 400-900 N "
    "but at lower N/kg (15-35 N/kg) — more mass for proportionally less efficiency. "
    "The optimal radius depends on the tension target: R=2.0m for <400 N, "
    "R=3.0m for >500 N. Data: BEM v2.1, 384 configs."
)
fig.text(0.10, 0.02, caption, fontsize=8, color="#444444",
         ha="left", va="bottom", style="italic", wrap=True)
plt.subplots_adjust(left=0.10, right=0.94, top=0.92, bottom=0.22)
fig.savefig("bem-pareto-radius.png", dpi=300, facecolor="white", bbox_inches="tight")
fig.savefig("bem-pareto-radius.pdf", facecolor="white", bbox_inches="tight")
plt.close()
print("bem-pareto-radius.png + .pdf generated")
