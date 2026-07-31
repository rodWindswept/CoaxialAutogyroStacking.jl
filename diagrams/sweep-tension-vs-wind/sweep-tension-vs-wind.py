#!/usr/bin/env python3
"""sweep-tension-vs-wind: PCA-2 anchor tension vs wind speed by radius."""
import csv, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from collections import defaultdict

rows = []
with open("../../bem_full_sweep_pca2.tsv") as f:
    for r in csv.DictReader(f, delimiter="\t"):
        t = float(r["anchor_tension"])
        if t <= 0:
            continue
        rows.append({
            "radius": float(r["radius"]), "n": int(r["n_rotors"]),
            "profile": r["profile"], "wind": float(r["wind_speed"]),
            "tension": t,
        })

fig, ax = plt.subplots(figsize=(8, 5))
fig.patch.set_facecolor("white"); ax.set_facecolor("white")

radii = [1.5, 2.0, 3.0]
colors = {1.5: "#d73027", 2.0: "#fc8d59", 3.0: "#4575b4"}
winds = [6, 8, 10, 12]

for rad in radii:
    for n in [2, 4]:
        means = []
        for w in winds:
            vals = [r["tension"] for r in rows
                   if r["radius"] == rad and r["n"] == n
                   and r["profile"] == "graded" and r["wind"] == w]
            means.append(np.mean(vals) if vals else 0)
        ls = "-" if n == 4 else "--"
        ax.plot(winds, means, ls, color=colors[rad], linewidth=1.8,
               marker="o" if n == 4 else "s", markersize=7,
               label=f"R={rad:.1f}m, N={n}")

ax.set_xlabel("Wind Speed (m/s)", fontsize=11)
ax.set_ylabel("Anchor Tension (N)", fontsize=11)
ax.set_title("PCA-2: Anchor Tension vs Wind Speed\n"
             "PCA-2 Disk Model — Graded Profile, 45\u00b0 Elevation",
             fontsize=12, fontweight="bold")
ax.legend(fontsize=9)
ax.grid(True, alpha=0.3)

caption = (
    "IMPLICATIONS: PCA-2 tension follows the expected v\u00b2 scaling (parabolic shape). "
    "R=3.0m, N=4 reaches >4000 N at 12 m/s in the PCA-2 model \u2014 compare with BEM "
    "which predicts ~800 N. The PCA-2 model assumes a high-solidity disk (\u03c3\u22480.098) "
    "while BEM resolves our low-solidity blades (\u03c3\u22480.032). "
    "Data: PCA-2 disk model, graded profile."
)
fig.text(0.10, 0.02, caption, fontsize=8, color="#444444",
         ha="left", va="bottom", style="italic", wrap=True)
plt.subplots_adjust(left=0.10, right=0.94, top=0.92, bottom=0.22)
fig.savefig("sweep-tension-vs-wind.png", dpi=300, facecolor="white", bbox_inches="tight")
fig.savefig("sweep-tension-vs-wind.pdf", facecolor="white", bbox_inches="tight")
plt.close()
print("sweep-tension-vs-wind.png + .pdf generated")
