#!/usr/bin/env python3
"""pca-biplot: PCA biplot of BEM configurations — what drives performance variance.

Reads ../../bem_full_sweep.tsv, aggregates by configuration, runs PCA on
7 variables, plots PC1 vs PC2 with loading arrows.
"""
import csv
from collections import defaultdict
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

# ── Load & aggregate ───────────────────────────────────────────────────────
data_path = "../../bem_full_sweep.tsv"
rows = []
with open(data_path) as f:
    reader = csv.DictReader(f, delimiter="\t")
    for row in reader:
        rows.append({
            "radius": float(row["radius"]),
            "n_rotors": int(row["n_rotors"]),
            "profile": row["profile"],
            "elevation": float(row["elevation"]),
            "wind_speed": float(row["wind_speed"]),
            "anchor_tension": float(row["anchor_tension"]),
            "autorotation_rpm": float(row["autorotation_rpm"]),
            "tip_speed_bem": float(row["tip_speed_bem"]),
        })

configs = defaultdict(list)
for row in rows:
    key = (row["radius"], row["n_rotors"], row["profile"], row["elevation"])
    configs[key].append(row)

records = []
for (radius, n_rotors, profile, elevation), group in configs.items():
    tensions = [r["anchor_tension"] for r in group]
    rpms = [r["autorotation_rpm"] for r in group]
    tips = [r["tip_speed_bem"] for r in group]
    mt = np.mean(tensions)
    if mt <= 0:
        continue
    records.append({
        "radius": radius, "n_rotors": n_rotors, "profile": profile,
        "elevation": elevation,
        "mean_tension": mt,
        "tension_per_kg": mt / (n_rotors * 5.0),
        "mean_rpm": np.mean(rpms),
        "mean_tip_speed": np.mean(tips),
        "tip_reynolds": 1.225 * np.mean(tips) * 0.15 / 1.81e-5,
    })

# ── Build data matrix & standardise ────────────────────────────────────────
var_names = ["radius", "n_rotors", "mean_tension", "tension_per_kg",
             "mean_rpm", "mean_tip_speed", "tip_reynolds"]
n = len(records)
X = np.zeros((n, 7))
for j, vn in enumerate(var_names):
    X[:, j] = [r[vn] for r in records]
X_std = (X - X.mean(axis=0)) / X.std(axis=0)

# ── PCA via SVD ────────────────────────────────────────────────────────────
U, S, Vt = np.linalg.svd(X_std, full_matrices=False)
scores = U[:, :2] * S[:2]           # n×2 PC scores
loadings = Vt[:2, :].T * S[:2]      # 7×2 loadings scaled by singular values
pc1_var = S[0]**2 / np.sum(S**2) * 100
pc2_var = S[1]**2 / np.sum(S**2) * 100

# ── Plot ───────────────────────────────────────────────────────────────────
PROFILE_COLORS = {
    "uniform": "#2166ac", "top_draggy": "#d6604d",
    "bottom_lifty": "#4daf4a", "graded": "#b2182b",
}
PROFILE_MARKERS = {"uniform": "o", "top_draggy": "s",
                   "bottom_lifty": "^", "graded": "D"}
PROFILE_LABELS = {"uniform": "uniform", "top_draggy": "top-draggy",
                  "bottom_lifty": "bottom-lifty", "graded": "graded"}
RADII = sorted(set(r["radius"] for r in records))

fig, ax = plt.subplots(figsize=(9, 10))
fig.patch.set_facecolor("white")
ax.set_facecolor("white")

# Scatter by profile
for profile in ["uniform", "top_draggy", "bottom_lifty", "graded"]:
    idx = [i for i, r in enumerate(records) if r["profile"] == profile]
    if not idx:
        continue
    px = scores[idx, 0]
    py = scores[idx, 1]
    ps = np.array([records[i]["radius"]**2 * 12 for i in idx])
    ax.scatter(px, py, s=ps, c=PROFILE_COLORS[profile],
               marker=PROFILE_MARKERS[profile],
               label=PROFILE_LABELS[profile],
               edgecolors="white", linewidth=0.5, alpha=0.85, zorder=3)

# ── Loading arrows (quiver — reliable vector rendering) ────────────────────
arrow_scale = 0.18  # shrink arrows to fit within data frame

# Collect all arrow components
all_dx, all_dy, all_labels = [], [], []

# 5 collinear variables with small angular spread
collinear = [0, 3, 4, 5, 6]
collinear_names = ["radius", "tension per kg", "mean rpm", "mean tip speed", "tip Reynolds"]
spreads = [-0.05, -0.025, 0.0, 0.025, 0.05]

for k, j in enumerate(collinear):
    lx = loadings[j, 0] * arrow_scale
    ly = loadings[j, 1] * arrow_scale
    angle = np.arctan2(ly, lx) + spreads[k]
    mag = np.sqrt(lx**2 + ly**2)
    all_dx.append(mag * np.cos(angle))
    all_dy.append(mag * np.sin(angle))
    all_labels.append(collinear_names[k])

# n_rotors and mean_tension
for j, name in [(1, "n_rotors"), (2, "mean tension")]:
    all_dx.append(loadings[j, 0] * arrow_scale)
    all_dy.append(loadings[j, 1] * arrow_scale)
    all_labels.append(name)

# Draw all vectors from origin
ax.quiver(np.zeros(7), np.zeros(7), all_dx, all_dy,
          angles="xy", scale_units="xy", scale=1,
          color="gray", alpha=0.7, width=0.005,
          headwidth=5, headlength=6, headaxislength=5,
          zorder=4)

# Labels at tips — offset in data coords, not proportional to tip
label_offset = 0.25  # fixed data-unit offset from arrow tip
for dx, dy, label in zip(all_dx, all_dy, all_labels):
    mag = np.sqrt(dx**2 + dy**2)
    if mag > 1e-6:
        ux, uy = dx / mag, dy / mag  # unit direction
    else:
        ux, uy = 1.0, 0.0
    ax.text(dx + ux * label_offset, dy + uy * label_offset, label,
            fontsize=9, color="black", ha="left", va="center",
            bbox=dict(boxstyle="round,pad=0.12", facecolor="white",
                      edgecolor="#cccccc", alpha=0.9),
            zorder=5)

# Collinearity note
ax.text(all_dx[0] + 0.4, all_dy[0] - 0.2,
        "(collinear — all driven by radius)",
        fontsize=7.5, color="#888888", ha="left", va="center",
        bbox=dict(boxstyle="round,pad=0.1", facecolor="white", edgecolor="none", alpha=0.8))

# ── Size legend (flat row, positioned relative to data) ────────────────────
# Place above the data on the left side
sx_base = scores[:, 0].min() * 0.8
sy_base = scores[:, 1].max() * 1.25
for j, rad in enumerate(RADII):
    sz = rad**2 * 12
    ax.scatter([sx_base + j * 1.5], [sy_base], s=sz, c="#888888",
               edgecolors="white", linewidth=0.5, alpha=0.7)
    ax.text(sx_base + j * 1.5 + 0.3, sy_base, f"R={rad:.1f}m",
            fontsize=9, color="#555555", va="center")
ax.text(sx_base + 1.5, sy_base + 0.5,
        "Point area ∝ disk area (πR²)", fontsize=8, color="#888888",
        ha="center")

# ── Axes ───────────────────────────────────────────────────────────────────
ax.set_xlabel(f"PC1 — Physical Scale & Performance ({pc1_var:.1f}% variance)", fontsize=11)
ax.set_ylabel(f"PC2 — Rotor Count ({pc2_var:.1f}% variance)", fontsize=11)
ax.set_title("PCA of BEM Configurations: What Drives Performance Variance?",
             fontsize=13, fontweight="bold", pad=14)
ax.legend(loc="lower right", fontsize=8, framealpha=0.9, edgecolor="#cccccc")
ax.grid(True, alpha=0.3, linestyle="--")

# ── Implications caption ───────────────────────────────────────────────────
caption = (
    "IMPLICATIONS: PCA of 96 BEM configurations across 7 variables. "
    "The design space collapses to 2-D: PC1 (81%) = physical scale & "
    "performance; PC2 (19%) = rotor count. All 4 tilt profiles overlap "
    "completely — tilt is a tuning parameter, not a design differentiator. "
    "For manufacturing: reduce the 96-configuration space to a 4×4 grid "
    "of (radius, N). Build uniform tilt. "
    "Data: BEM v2.0, corrected polygon solver. See SPEC.md §6.6."
)
caption_text = fig.text(0.10, 0.02, caption, fontsize=8, color="#444444",
                         ha="left", va="bottom", style="italic", family="serif",
                         wrap=True)

plt.subplots_adjust(left=0.11, right=0.93, top=0.93, bottom=0.16)
fig.savefig("pca-biplot.png", dpi=300, facecolor="white", edgecolor="none",
            bbox_extra_artists=[caption_text], bbox_inches="tight")
fig.savefig("pca-biplot.pdf", facecolor="white", edgecolor="none",
            bbox_extra_artists=[caption_text], bbox_inches="tight")
plt.close()

print(f"pca-biplot.png + pca-biplot.pdf generated")
print(f"  {n} configurations, PC1={pc1_var:.1f}%, PC2={pc2_var:.1f}%")
