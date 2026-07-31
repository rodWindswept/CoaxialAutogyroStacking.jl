#!/usr/bin/env python3
"""bem-pca2-vs-bem: PCA-2 disk model vs BEM v2.1 anchor tension comparison."""
import csv
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from collections import defaultdict

# Load BEM data
bem = {}
with open("../../bem_full_sweep.tsv") as f:
    for r in csv.DictReader(f, delimiter="\t"):
        t = float(r["anchor_tension"])
        key = (float(r["radius"]), int(r["n_rotors"]), r["profile"],
               float(r["elevation"]), float(r["wind_speed"]))
        if key not in bem:
            bem[key] = []
        bem[key].append(t)

# Load PCA-2 data
pca2 = {}
with open("../../bem_full_sweep_pca2.tsv") as f:
    for r in csv.DictReader(f, delimiter="\t"):
        t = float(r["anchor_tension"])
        key = (float(r["radius"]), int(r["n_rotors"]), r["profile"],
               float(r["elevation"]), float(r["wind_speed"]))
        if key not in pca2:
            pca2[key] = []
        pca2[key].append(t)

fig, axes = plt.subplots(2, 2, figsize=(11, 9))
fig.patch.set_facecolor("white")

# Panel 1: scatter — BEM vs PCA-2 tension, all configs
ax = axes[0][0]
ax.set_facecolor("white")
bem_vals = []
pca2_vals = []
colors_scatter = []
for key in bem:
    if key in pca2:
        bm = np.mean(bem[key])
        pc = np.mean(pca2[key])
        bem_vals.append(bm)
        pca2_vals.append(pc)
        colors_scatter.append("#d73027" if key[0] == 1.5 else
                            "#fc8d59" if key[0] == 2.0 else "#4575b4")

ax.scatter(pca2_vals, bem_vals, c=colors_scatter, alpha=0.6, s=30, zorder=3)
max_val = max(max(pca2_vals), max(bem_vals)) * 1.05
ax.plot([0, max_val], [0, max_val], "k--", alpha=0.3, linewidth=1,
        label="1:1 line")
ax.set_xlabel("PCA-2 Anchor Tension (N)", fontsize=10)
ax.set_ylabel("BEM Anchor Tension (N)", fontsize=10)
ax.set_title("BEM vs PCA-2: All Configurations", fontsize=11,
             fontweight="bold")
ax.legend(fontsize=8)
ax.grid(True, alpha=0.3)

# Annotate the gap
ratio = np.mean([b / p for b, p in zip(bem_vals, pca2_vals) if p > 0])
ax.text(0.05, 0.95, f"Mean BEM/PCA-2 = {ratio:.2f}\u00d7",
        transform=ax.transAxes, fontsize=10, va="top",
        bbox=dict(boxstyle="round", facecolor="white", alpha=0.8))

# Panel 2: tension vs wind speed, R=3.0m, N=4, graded
ax = axes[0][1]
ax.set_facecolor("white")
key_filter = {"radius": 3.0, "n": 4, "profile": "graded", "elevation": 45.0}
winds = [6, 8, 10, 12]

bem_by_wind = defaultdict(list)
pca2_by_wind = defaultdict(list)
for key in bem:
    if (key[0] == key_filter["radius"] and key[1] == key_filter["n"]
        and key[2] == key_filter["profile"]
        and key[3] == key_filter["elevation"]):
        bem_by_wind[key[4]].extend(bem[key])
for key in pca2:
    if (key[0] == key_filter["radius"] and key[1] == key_filter["n"]
        and key[2] == key_filter["profile"]
        and key[3] == key_filter["elevation"]):
        pca2_by_wind[key[4]].extend(pca2[key])

bem_means = [np.mean(bem_by_wind[w]) for w in winds]
pca2_means = [np.mean(pca2_by_wind[w]) for w in winds]

ax.plot(winds, pca2_means, "s-", color="#d73027", linewidth=2, markersize=8,
        label="PCA-2 disk model")
ax.plot(winds, bem_means, "o-", color="#4575b4", linewidth=2, markersize=8,
        label="BEM v2.1")
ax.fill_between(winds, pca2_means, bem_means, alpha=0.1, color="gray")
ax.set_xlabel("Wind Speed (m/s)", fontsize=10)
ax.set_ylabel("Anchor Tension (N)", fontsize=10)
ax.set_title(f"R={key_filter['radius']:.0f}m, N={key_filter['n']}, "
             f"{key_filter['profile']}, {key_filter['elevation']:.0f}\u00b0",
             fontsize=11, fontweight="bold")
ax.legend(fontsize=9)
ax.grid(True, alpha=0.3)

# Panel 3: ratio BEM/PCA-2 by radius
ax = axes[1][0]
ax.set_facecolor("white")
radii = [1.5, 2.0, 3.0]
colors_r = {1.5: "#d73027", 2.0: "#fc8d59", 3.0: "#4575b4"}
x_positions = []

for rad in radii:
    ratios = []
    for key in bem:
        if key[0] == rad and key in pca2:
            bm = np.mean(bem[key])
            pc = np.mean(pca2[key])
            if pc > 0:
                ratios.append(bm / pc)
    if ratios:
        x_positions.append(rad)
        ax.bar(rad, np.mean(ratios), width=0.3, color=colors_r[rad],
               edgecolor="white", alpha=0.85)
        ax.text(rad, np.mean(ratios) + 0.01, f"{np.mean(ratios):.2f}\u00d7",
                ha="center", fontsize=9, fontweight="bold")

ax.axhline(1.0, color="black", linestyle="--", alpha=0.3, linewidth=1)
ax.set_xlabel("Rotor Radius (m)", fontsize=10)
ax.set_ylabel("Mean BEM / PCA-2 Tension Ratio", fontsize=10)
ax.set_title("Gap by Rotor Radius", fontsize=11, fontweight="bold")
ax.set_xticks(radii)
ax.grid(True, alpha=0.3, axis="y")

# Panel 4: ratio BEM/PCA-2 by stack count
ax = axes[1][1]
ax.set_facecolor("white")
n_vals = [1, 2, 3, 4]
colors_n = {1: "#1a9850", 2: "#4575b4", 3: "#fc8d59", 4: "#d73027"}

for n in n_vals:
    ratios = []
    for key in bem:
        if key[1] == n and key[0] in [2.0, 3.0] and key in pca2:
            bm = np.mean(bem[key])
            pc = np.mean(pca2[key])
            if pc > 0:
                ratios.append(bm / pc)
    if ratios:
        ax.bar(n, np.mean(ratios), width=0.3, color=colors_n[n],
               edgecolor="white", alpha=0.85)
        ax.text(n, np.mean(ratios) + 0.01, f"{np.mean(ratios):.2f}\u00d7",
                ha="center", fontsize=9, fontweight="bold")

ax.axhline(1.0, color="black", linestyle="--", alpha=0.3, linewidth=1)
ax.set_xlabel("Stack Count", fontsize=10)
ax.set_ylabel("Mean BEM / PCA-2 Tension Ratio", fontsize=10)
ax.set_title("Gap by Stack Count (R=2.0, 3.0m)", fontsize=11,
             fontweight="bold")
ax.set_xticks(n_vals)
ax.grid(True, alpha=0.3, axis="y")

fig.suptitle("PCA-2 Disk Model vs BEM v2.1: What Did We Gain?\n"
             "Identical Configurations, Different Aerodynamic Models",
             fontsize=13, fontweight="bold")

caption = (
    "IMPLICATIONS: The PCA-2 disk model systematically overestimates forces by "
    f"~{1/ratio:.0f}\u00d7 compared to BEM v2.1. The gap is largest at R=1.5m "
    f"(~{1/np.mean([np.mean(bem[k])/np.mean(pca2[k]) for k in bem if k[0]==1.5 and k in pca2 and np.mean(pca2[k])>0]):.0f}\u00d7) "
    "and narrows at R=3.0m. This is the solidity + 2-D/3-D averaging gap "
    "(see DECISIONS.md D1). The PCA-2 empirical data represents a high-solidity "
    "disk (\u03c3\u22480.098) while BEM models our low-solidity blades (\u03c3\u22480.032). "
    "BEM is the design truth for our configuration. Data: identical sweep grid, "
    "45\u00b0 and 55\u00b0 elevation."
)
fig.text(0.06, 0.01, caption, fontsize=8, color="#444444",
         ha="left", va="bottom", style="italic", wrap=True)
plt.subplots_adjust(left=0.06, right=0.96, top=0.90, bottom=0.15,
                    hspace=0.40, wspace=0.35)
fig.savefig("bem-pca2-vs-bem.png", dpi=300, facecolor="white",
            bbox_inches="tight")
fig.savefig("bem-pca2-vs-bem.pdf", facecolor="white", bbox_inches="tight")
plt.close()
print("bem-pca2-vs-bem.png + .pdf generated")
