#!/usr/bin/env python3
"""bem-pareto: Pareto front — anchor tension vs mass efficiency by tilt profile.

Reads ../../bem_full_sweep.tsv, aggregates by configuration, plots
mean anchor tension vs tension per rotor mass, colored by tilt profile.
Pareto front shows non-dominated configurations.
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
ConfigKey = tuple  # (radius, n_rotors, profile, elevation)
configs: dict[ConfigKey, list[float]] = defaultdict(list)

for row in rows:
    key = (row["radius"], row["n_rotors"], row["profile"], row["elevation"])
    configs[key].append(row["anchor_tension"])

# Build aggregated records
records = []
for (radius, n_rotors, profile, elevation), tensions in configs.items():
    mean_t = np.mean(tensions)
    if mean_t <= 0:
        continue  # viability gate
    mass = n_rotors * 5.0  # 5 kg per rotor
    t_per_kg = mean_t / mass
    records.append({
        "radius": radius,
        "n_rotors": n_rotors,
        "profile": profile,
        "elevation": elevation,
        "mean_tension": mean_t,
        "tension_per_kg": t_per_kg,
    })

# ── Pareto front (maximize both tension and N/kg) ──────────────────────────
xs = np.array([r["mean_tension"] for r in records])
ys = np.array([r["tension_per_kg"] for r in records])

pareto_mask = np.ones(len(records), dtype=bool)
for i in range(len(records)):
    for j in range(len(records)):
        if i != j and xs[j] >= xs[i] and ys[j] >= ys[i]:
            if xs[j] > xs[i] or ys[j] > ys[i]:
                pareto_mask[i] = False
                break

# Sort Pareto points by x for curve plotting
pareto_indices = np.where(pareto_mask)[0]
pareto_sorted = sorted(pareto_indices, key=lambda i: xs[i])
pareto_x = [xs[i] for i in pareto_sorted]
pareto_y = [ys[i] for i in pareto_sorted]

# ── Plot ───────────────────────────────────────────────────────────────────
PROFILE_COLORS = {
    "uniform":       "#2166ac",
    "top_draggy":    "#d6604d",
    "bottom_lifty":  "#4daf4a",
    "graded":        "#b2182b",
}
PROFILE_MARKERS = {
    "uniform":       "o",
    "top_draggy":    "s",
    "bottom_lifty":  "^",
    "graded":        "D",
}
PROFILE_LABELS = {
    "uniform":       "uniform",
    "top_draggy":    "top-draggy",
    "bottom_lifty":  "bottom-lifty",
    "graded":        "graded",
}

fig, ax = plt.subplots(figsize=(10, 7))
fig.patch.set_facecolor("white")
ax.set_facecolor("white")

# Plot points by profile
for profile in ["uniform", "top_draggy", "bottom_lifty", "graded"]:
    mask = [r["profile"] == profile for r in records]
    if not any(mask):
        continue
    px = [r["mean_tension"] for r, m in zip(records, mask) if m]
    py = [r["tension_per_kg"] for r, m in zip(records, mask) if m]
    ps = [r["radius"]**2 * 40 for r, m in zip(records, mask) if m]  # area ∝ R²
    ax.scatter(px, py, s=ps, c=PROFILE_COLORS[profile],
               marker=PROFILE_MARKERS[profile],
               label=PROFILE_LABELS[profile],
               edgecolors="white", linewidth=0.5, alpha=0.85, zorder=3)

# Pareto front curve (may be a single point if objectives are co-linear)
if len(pareto_x) >= 2:
    ax.plot(pareto_x, pareto_y, "k--", linewidth=1.5, alpha=0.6,
            label="Pareto front", zorder=2)
else:
    # Single Pareto-optimal point — mark with star
    ax.scatter(pareto_x, pareto_y, s=300, c="black", marker="*",
               edgecolors="white", linewidth=0.8, zorder=5,
               label="Pareto-optimal")

# Annotate: Pareto-optimal + one representative per distinct (radius, N) band
labeled = set()
label_order = []

# 1. Pareto-optimal
for i, r in enumerate(records):
    if pareto_mask[i]:
        label_order.append(i)
        labeled.add(i)
        break

# 2. Best per distinct performance band (unique radius × N combinations)
bands = [(3.0, 2), (2.0, 4), (2.0, 2), (2.0, 1)]
for rad, nrot in bands:
    best = None
    for i, r in enumerate(records):
        if r["radius"] == rad and r["n_rotors"] == nrot and i not in labeled:
            if best is None or r["mean_tension"] > records[best]["mean_tension"]:
                best = i
    if best is not None:
        label_order.append(best)
        labeled.add(best)
        if len(label_order) >= 5:
            break

# Cluster annotation for the R=3.0m N=4 band (all profiles tight)
r3n4 = [r for r in records if r["radius"] == 3.0 and r["n_rotors"] == 4 and r["mean_tension"] > 600]
if r3n4:
    best_r3n4 = max(r3n4, key=lambda r: r["mean_tension"])
    ax.annotate(f'R=3.0m, N=4: all profiles\nwithin 2% (best: {best_r3n4["profile"]})',
                xy=(820, 41.8), fontsize=7, color="#555555",
                ha="center", va="bottom",
                bbox=dict(boxstyle="round,pad=0.3", facecolor="#f8f8f8",
                          edgecolor="#dddddd", alpha=0.85))

for rank, i in enumerate(label_order[:5]):
    r = records[i]
    label = f'[{r["mean_tension"]:.0f} N, {r["tension_per_kg"]:.1f} N/kg\n {r["profile"]}, R={r["radius"]:.1f}m, N={r["n_rotors"]}]'
    offsets = [(50, 8), (-90, 5), (50, -12), (-90, -8), (10, 18)]
    dx, dy = offsets[rank % len(offsets)]
    ax.annotate(label,
                xy=(r["mean_tension"], r["tension_per_kg"]),
                xytext=(r["mean_tension"] + dx, r["tension_per_kg"] + dy),
                fontsize=6.5, color="#333333",
                arrowprops=dict(arrowstyle="->", color="#888888", lw=0.6),
                bbox=dict(boxstyle="round,pad=0.25", facecolor="white",
                          edgecolor="#cccccc", alpha=0.9))

# Labels
ax.set_xlabel("Mean Anchor Tension (N)", fontsize=12)
ax.set_ylabel("Tension per Rotor Mass (N/kg)", fontsize=12)
ax.set_title("No Pareto Trade-off: Tension and Mass Efficiency Are Co-linear\n"
             "BEM v2.0 — Corrected Polygon Solver (2026-07-27)",
             fontsize=13, fontweight="bold")

# Legend
ax.legend(loc="lower right", fontsize=9, framealpha=0.9,
          edgecolor="#cccccc")

# Grid
ax.grid(True, alpha=0.3, linestyle="--")
ax.set_xlim(left=0)
ax.set_ylim(bottom=0)

plt.tight_layout()
fig.savefig("bem-pareto.png", dpi=300, bbox_inches="tight",
            facecolor="white", edgecolor="none")
fig.savefig("bem-pareto.pdf", bbox_inches="tight",
            facecolor="white", edgecolor="none")
plt.close()
print("bem-pareto.png + bem-pareto.pdf generated")
print(f"  {len(records)} configurations plotted")
print(f"  {sum(pareto_mask)} on Pareto front")
print(f"  Top tension: {max(r['mean_tension'] for r in records):.0f} N")
print(f"  Top N/kg:    {max(r['tension_per_kg'] for r in records):.1f} N/kg")
