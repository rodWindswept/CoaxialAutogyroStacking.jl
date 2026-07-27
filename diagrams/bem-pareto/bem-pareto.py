#!/usr/bin/env python3
"""bem-pareto: Pareto front — anchor tension vs mass efficiency by tilt profile.

Reads ../../bem_full_sweep.tsv, aggregates by configuration, plots
mean anchor tension vs tension per rotor mass, colored by tilt profile.
Point size encodes rotor disk area (radius**2).
"""
import csv
from collections import defaultdict
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

# ── Load data ──────────────────────────────────────────────────────────────
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

# ── Aggregate by configuration ─────────────────────────────────────────────
configs: dict[tuple, list[float]] = defaultdict(list)
for row in rows:
    key = (row["radius"], row["n_rotors"], row["profile"], row["elevation"])
    configs[key].append(row["anchor_tension"])

records = []
for (radius, n_rotors, profile, elevation), tensions in configs.items():
    mean_t = np.mean(tensions)
    if mean_t <= 0:
        continue
    t_per_kg = mean_t / (n_rotors * 5.0)
    records.append({
        "radius": radius, "n_rotors": n_rotors, "profile": profile,
        "elevation": elevation, "mean_tension": mean_t,
        "tension_per_kg": t_per_kg,
    })

# ── Pareto front ───────────────────────────────────────────────────────────
xs = np.array([r["mean_tension"] for r in records])
ys = np.array([r["tension_per_kg"] for r in records])
pareto_mask = np.ones(len(records), dtype=bool)
for i in range(len(records)):
    for j in range(len(records)):
        if i != j and xs[j] >= xs[i] and ys[j] >= ys[i]:
            if xs[j] > xs[i] or ys[j] > ys[i]:
                pareto_mask[i] = False
                break
pareto_idx = np.where(pareto_mask)[0]
pareto_sorted = sorted(pareto_idx, key=lambda i: xs[i])
pareto_x = [xs[i] for i in pareto_sorted]
pareto_y = [ys[i] for i in pareto_sorted]

# ── Plot (portrait, tight crop) ────────────────────────────────────────────
PROFILE_COLORS = {
    "uniform": "#2166ac", "top_draggy": "#d6604d",
    "bottom_lifty": "#4daf4a", "graded": "#b2182b",
}
PROFILE_MARKERS = {"uniform": "o", "top_draggy": "s",
                   "bottom_lifty": "^", "graded": "D"}
PROFILE_LABELS = {"uniform": "uniform", "top_draggy": "top-draggy",
                  "bottom_lifty": "bottom-lifty", "graded": "graded"}
RADII = sorted(set(r["radius"] for r in records))

fig, ax = plt.subplots(figsize=(8, 10))
fig.patch.set_facecolor("white")
ax.set_facecolor("white")

# Plot points by profile
for profile in ["uniform", "top_draggy", "bottom_lifty", "graded"]:
    mask = [r["profile"] == profile for r in records]
    if not any(mask):
        continue
    px = [r["mean_tension"] for r, m in zip(records, mask) if m]
    py = [r["tension_per_kg"] for r, m in zip(records, mask) if m]
    ps = [r["radius"]**2 * 50 for r, m in zip(records, mask) if m]
    ax.scatter(px, py, s=ps, c=PROFILE_COLORS[profile],
               marker=PROFILE_MARKERS[profile],
               label=PROFILE_LABELS[profile],
               edgecolors="white", linewidth=0.5, alpha=0.85, zorder=3)

# Pareto-optimal star
ax.scatter(pareto_x, pareto_y, s=350, c="black", marker="*",
           edgecolors="white", linewidth=0.8, zorder=5,
           label="Pareto-optimal")

# ── Leader-line annotations: routed to whitespace, avoiding data clusters ──
annotations = []

# Pareto-optimal (top right) — pull label slightly right, within margin
for i, r in enumerate(records):
    if pareto_mask[i]:
        annotations.append((i, 50, -5))
        break

# Distinct performance bands — pull labels outward from their cluster
# (R, N) → (dx, dy) in data coords, routing into nearest whitespace
bands = [
    (3.0, 2, 50, -18),    # right-down, below title area
    (2.0, 4, -90, 2),     # left, into left margin
    (2.0, 2, 70, -10),    # right, below the cluster
    (2.0, 1, 50, 14),     # right, above the low cluster (clear of top spine)
]
for rad, nrot, dx, dy in bands:
    best = None
    for i, r in enumerate(records):
        if r["radius"] == rad and r["n_rotors"] == nrot:
            if best is None or r["mean_tension"] > records[best]["mean_tension"]:
                best = i
    if best is not None and best not in [a[0] for a in annotations]:
        annotations.append((best, dx, dy))

for i, dx, dy in annotations:
    r = records[i]
    label = (f'{r["profile"]}\n'
             f'R={r["radius"]:.1f}m  N={r["n_rotors"]}\n'
             f'{r["mean_tension"]:.0f} N  {r["tension_per_kg"]:.1f} N/kg')
    # Use straight leader lines (no arc) for direct routing
    ax.annotate(label,
                xy=(r["mean_tension"], r["tension_per_kg"]),
                xytext=(r["mean_tension"] + dx, r["tension_per_kg"] + dy),
                fontsize=7, color="#333333", linespacing=1.3,
                arrowprops=dict(arrowstyle="->", color="#555555", lw=0.8),
                bbox=dict(boxstyle="round,pad=0.3", facecolor="white",
                          edgecolor="#888888", alpha=0.92))

# ── Size legend ────────────────────────────────────────────────────────────
size_label_y = -0.12
ax.text(0.02, size_label_y,
        "Point area ∝ rotor disk area (πR²)  —  ",
        transform=ax.transAxes, fontsize=8, color="#555555", va="center")
for j, rad in enumerate(RADII):
    sz = rad**2 * 50
    ax.scatter([0.38 + j*0.075], [size_label_y], s=sz, c="#888888",
               edgecolors="white", linewidth=0.5, alpha=0.7,
               transform=ax.transAxes, clip_on=False)
    ax.text(0.40 + j*0.075, size_label_y, f"R={rad:.1f}",
            transform=ax.transAxes, fontsize=7.5, color="#555555", va="center")

# ── Axes & labels ──────────────────────────────────────────────────────────
ax.set_xlabel("Mean Anchor Tension (N)", fontsize=11, labelpad=8)
ax.set_ylabel("Tension per Rotor Mass (N/kg)", fontsize=11, labelpad=8)
ax.set_title("No Pareto Trade-off: Anchor Tension and Mass Efficiency Are Co-linear\n"
             "BEM v2.0 — Corrected Polygon Solver (2026-07-27)",
             fontsize=12, fontweight="bold", pad=16)
ax.legend(loc="lower right", fontsize=8, framealpha=0.9, edgecolor="#cccccc")
ax.grid(True, alpha=0.3, linestyle="--")
ax.set_xlim(left=-20, right=920)
ax.set_ylim(bottom=-2, top=47)

# ── Implications caption in dedicated bottom area ──────────────────────────
caption = (
    "IMPLICATIONS: Tension and mass efficiency are co-linear — no Pareto "
    "trade-off exists. A single configuration (R=3.0m, N=4, graded, 839 N, "
    "42.0 N/kg) dominates all others on both objectives. Tilt profile effect "
    "is <2% at R=3.0m: uniform tilt is nearly optimal. For design: maximise "
    "rotor radius within mechanical limits, stack as many rotors as line "
    "tension allows, do not over-invest in tilt profile differentiation. "
    "Data: 384 BEM v2.0 configurations (corrected polygon solver), 4 wind "
    "speeds 6–12 m/s, 2 elevations. See SPEC.md §6.6."
)
# Add caption as a text element inside the figure, anchored to bottom-left
caption_text = fig.text(0.13, 0.03, caption, fontsize=7.5, color="#444444",
                         ha="left", va="bottom", style="italic", family="serif",
                         wrap=True)

plt.subplots_adjust(left=0.13, right=0.90, top=0.90, bottom=0.24)
fig.savefig("bem-pareto.png", dpi=300,
            facecolor="white", edgecolor="none",
            bbox_extra_artists=[caption_text], bbox_inches="tight")
fig.savefig("bem-pareto.pdf",
            facecolor="white", edgecolor="none",
            bbox_extra_artists=[caption_text], bbox_inches="tight")
plt.close()
print("bem-pareto.png + bem-pareto.pdf generated")
print(f"  {len(records)} configs, {sum(pareto_mask)} Pareto-optimal")
