#!/usr/bin/env python3
"""pca-manufacturing: (Radius, N) grid overlay on PC1/PC2 space.

Reads ../../bem_full_sweep.tsv, aggregates by configuration, runs PCA,
plots scatter with (R,N) grid lines connecting configurations.
"""
import csv
from collections import defaultdict
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

# ── Load & aggregate ─────────────────────────────────────────────────────
with open("../../bem_full_sweep.tsv") as f:
    rows = list(csv.DictReader(f, delimiter="\t"))

configs = defaultdict(list)
for row in rows:
    key = (float(row["radius"]), int(row["n_rotors"]),
           row["profile"], float(row["elevation"]))
    configs[key].append(row)

records = []
for (radius, n_rotors, profile, elevation), group in configs.items():
    tensions = [float(r["anchor_tension"]) for r in group]
    mt = np.mean(tensions)
    if mt <= 0: continue
    records.append({
        "radius": radius, "n_rotors": n_rotors,
        "profile": profile, "elevation": elevation,
        "mean_tension": mt,
        "tension_per_kg": mt / (n_rotors * 5.0),
        "mean_rpm": np.mean([float(r["autorotation_rpm"]) for r in group]),
        "mean_tip_speed": np.mean([float(r["tip_speed_bem"]) for r in group]),
        "tip_reynolds": 1.225 * np.mean([float(r["tip_speed_bem"]) for r in group]) * 0.15 / 1.81e-5,
    })

# ── PCA ──────────────────────────────────────────────────────────────────
var_names = ["radius", "n_rotors", "mean_tension", "tension_per_kg",
             "mean_rpm", "mean_tip_speed", "tip_reynolds"]
X = np.array([[r[v] for v in var_names] for r in records])
X_std = (X - X.mean(axis=0)) / X.std(axis=0)
U, S, _ = np.linalg.svd(X_std, full_matrices=False)
scores = U[:, :2] * S[:2]
evr = S**2 / np.sum(S**2) * 100

# ── Plot ─────────────────────────────────────────────────────────────────
fig, ax = plt.subplots(figsize=(10, 8))
fig.patch.set_facecolor("white")
ax.set_facecolor("white")

radius_colors = {1.5: "#2166ac", 2.0: "#4daf4a", 3.0: "#b2182b"}
radius_markers = {1.5: "o", 2.0: "s", 3.0: "D"}

# Scatter by radius
for rad in [1.5, 2.0, 3.0]:
    idx = [i for i, r in enumerate(records) if r["radius"] == rad]
    sizes = [records[i]["n_rotors"]**1.5 * 25 for i in idx]
    ax.scatter(scores[idx, 0], scores[idx, 1],
               c=radius_colors[rad], marker=radius_markers[rad],
               s=sizes, alpha=0.8, edgecolors="white", linewidth=0.5,
               label=f"R={rad:.1f}m", zorder=3)

# Grid lines: connect same-(R, elevation, profile) across N
from itertools import product
for rad, elev, prof in product([1.5, 2.0, 3.0], [45.0, 55.0],
                                ["uniform", "top_draggy", "bottom_lifty", "graded"]):
    idx = [i for i, r in enumerate(records)
           if r["radius"] == rad and r["elevation"] == elev and r["profile"] == prof]
    if len(idx) < 2: continue
    pts = scores[idx]
    order = np.argsort([records[i]["n_rotors"] for i in idx])
    ax.plot(pts[order, 0], pts[order, 1], "-",
            color=radius_colors[rad], alpha=0.12, linewidth=0.8, zorder=1)

# Annotate Pareto-optimal points (max tension per kg at each radius)
pareto = {}
for i, r in enumerate(records):
    rad = r["radius"]
    nk = r["tension_per_kg"]
    if rad not in pareto or nk > pareto[rad][0]:
        pareto[rad] = (nk, i)
for rad, (nk, i) in pareto.items():
    ax.annotate(f"R={rad:.1f}m\nN={records[i]['n_rotors']}\n{nk:.0f} N/kg",
                (float(scores[i, 0]), float(scores[i, 1])), xytext=(10, 10), textcoords="offset points",
                fontsize=8, fontweight="bold", color=radius_colors[rad],
                bbox=dict(boxstyle="round,pad=0.2", facecolor="white",
                          edgecolor=radius_colors[rad], alpha=0.9),
                arrowprops=dict(arrowstyle="->", color=radius_colors[rad], lw=1),
                zorder=5)

# Size legend
sx = scores[:, 0].min() * 0.85
sy = scores[:, 1].max() * 1.2
for n in [1, 2, 3, 4]:
    sz = n**1.5 * 25
    ax.scatter([sx + (n-1) * 0.6], [sy], s=sz, c="#888888",
               edgecolors="white", linewidth=0.5, alpha=0.7)
    ax.text(sx + (n-1) * 0.6 + 0.2, sy, f"N={n}",
            fontsize=8, color="#555555", va="center")
ax.text(sx + 1.2, sy + 0.4, "Marker size ∝ N", fontsize=7, color="#888888", ha="center")

ax.set_xlabel(f"PC1 — Physical Scale & Performance ({evr[0]:.0f}% variance)", fontsize=11)
ax.set_ylabel(f"PC2 — Rotor Count ({evr[1]:.0f}% variance)", fontsize=11)
ax.set_title("Manufacturing Map: (Radius, N) Grid in PC Space",
             fontsize=13, fontweight="bold", pad=12)
ax.legend(loc="lower right", fontsize=9, framealpha=0.9, edgecolor="#cccccc")
ax.grid(True, alpha=0.3, linestyle="--")

# ── Caption ───────────────────────────────────────────────────────────────
caption = (
    "IMPLICATIONS: The (R,N) grid forms three parallel tracks in PC space — "
    "one per radius. Within each track, increasing N moves configurations "
    "vertically (PC2) without affecting PC1. Grid lines are nearly straight "
    "and parallel, confirming that rotor count and radius are independent "
    "design levers. Pareto-optimal points (annotated) show the best N/kg at "
    "each radius. Manufacturing strategy: tool for 3 rotor sizes (R=1.5, "
    "2.0, 3.0m), offer 1–4 stacking options per size. The 96-configuration "
    "space reduces to a 3×4 product matrix. "
    f"Data: {len(records)} configurations from BEM v2.0 sweep."
)
fig.text(0.08, -0.02, caption, fontsize=8, color="#444444",
         ha="left", va="top", style="italic", family="serif", wrap=True)

plt.subplots_adjust(left=0.11, right=0.93, top=0.91, bottom=0.19)
fig.savefig("pca-manufacturing.png", dpi=300, facecolor="white",
            edgecolor="none", bbox_inches="tight")
fig.savefig("pca-manufacturing.pdf", facecolor="white", edgecolor="none",
            bbox_inches="tight")
plt.close()

print(f"pca-manufacturing.png + pca-manufacturing.pdf generated")
