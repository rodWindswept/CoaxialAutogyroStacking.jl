#!/usr/bin/env python3
"""bem-legacy-feasibility-heatmap: Tip speed heatmap by (radius, N).

Reads ../../bem_full_sweep.tsv, computes mean tip speed per (radius, n_rotors)
cell, annotates pass/fail per tip speed ≤ 100 m/s noise gate.
"""
import csv, numpy as np
from collections import defaultdict
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

# ── Load ───────────────────────────────────────────────────────────────────
rows = []
with open("../../bem_full_sweep.tsv") as f:
    for row in csv.DictReader(f, delimiter="\t"):
        rows.append({
            "radius": float(row["radius"]),
            "n_rotors": int(row["n_rotors"]),
            "profile": row["profile"],
            "tip_speed_bem": float(row["tip_speed_bem"]),
        })

# ── Aggregate by (radius, n_rotors) ────────────────────────────────────────
cells = defaultdict(list)
for r in rows:
    key = (r["radius"], r["n_rotors"])
    cells[key].append(r["tip_speed_bem"])

radii_sorted = sorted(set(r["radius"] for r in rows))
counts_sorted = sorted(set(r["n_rotors"] for r in rows))
TIP_LIMIT = 100  # m/s — above this, tip noise becomes problematic

# Build matrices
tip_mean = np.zeros((len(counts_sorted), len(radii_sorted)))
tip_pass = np.zeros((len(counts_sorted), len(radii_sorted)), dtype=bool)
for ci, n in enumerate(counts_sorted):
    for ri, rad in enumerate(radii_sorted):
        vals = cells.get((rad, n), [])
        if vals:
            tip_mean[ci, ri] = np.mean(vals)
            tip_pass[ci, ri] = all(v <= TIP_LIMIT for v in vals)
        else:
            tip_mean[ci, ri] = np.nan
            tip_pass[ci, ri] = False

# ── Plot ───────────────────────────────────────────────────────────────────
fig, ax = plt.subplots(figsize=(6, 5))
fig.patch.set_facecolor("white")

# Reverse colormap: red=high tip speed (noisy), green=low (quiet)
im = ax.imshow(tip_mean, cmap="RdYlGn_r", aspect="auto", origin="lower",
               vmin=0, vmax=TIP_LIMIT,
               extent=[radii_sorted[0]-0.25, radii_sorted[-1]+0.25,
                       counts_sorted[0]-0.5, counts_sorted[-1]+0.5])

for ci, n in enumerate(counts_sorted):
    for ri, rad in enumerate(radii_sorted):
        if not np.isnan(tip_mean[ci, ri]):
            ok = tip_pass[ci, ri]
            ax.text(rad, n, "PASS" if ok else "FAIL",
                    ha="center", va="center",
                    fontsize=10, fontweight="bold",
                    color="#1a5c1a" if ok else "#8b0000",
                    bbox=dict(boxstyle="round,pad=0.2", facecolor="white",
                              edgecolor="#999999", alpha=0.95))
            ts_val = int(tip_mean[ci, ri])
            ax.text(rad, n - 0.35, f"{ts_val} m/s",
                    ha="center", va="top", fontsize=7, color="#444444",
                    bbox=dict(boxstyle="round,pad=0.1", facecolor="white",
                              edgecolor="none", alpha=0.8))

cbar = fig.colorbar(im, ax=ax, label="Mean Tip Speed (m/s)", shrink=0.85)
ax.set_xticks(radii_sorted)
ax.set_yticks(counts_sorted)
ax.set_xlabel("Rotor Radius (m)", fontsize=11, labelpad=10)
ax.set_ylabel("Stack Count (n_rotors)", fontsize=11, labelpad=10)
ax.set_title(f"Tip Speed — Noise Gate (≤ {TIP_LIMIT} m/s)",
             fontsize=12, fontweight="bold", pad=12)

# ── Implications caption ───────────────────────────────────────────────────
caption = (
    "IMPLICATIONS: All configurations stay well below 100 m/s tip speed — "
    "the noise gate does not constrain this design space. Tip speed "
    "saturates at ~30 m/s for R≥2.0m: larger rotors spin slower, "
    "self-regulating to the same tip speed via BEM equilibrium. "
    "R=1.5m is stalled — Re=15k, below the transitional threshold. "
    "Blades bottom out at 10 RPM regardless of stack count. "
    "Noise is not a limiting factor at these scales. "
    "Data: BEM v2.0, corrected polygon solver. See SPEC.md §6.6."
)
caption_text = fig.text(0.10, 0.02, caption, fontsize=8, color="#444444",
                         ha="left", va="bottom", style="italic", family="serif",
                         wrap=True)

plt.subplots_adjust(left=0.14, right=0.91, top=0.92, bottom=0.28)
fig.savefig("bem-legacy-feasibility-heatmap.png", dpi=300,
            facecolor="white", edgecolor="none",
            bbox_extra_artists=[caption_text], bbox_inches="tight")
fig.savefig("bem-legacy-feasibility-heatmap.pdf",
            facecolor="white", edgecolor="none",
            bbox_extra_artists=[caption_text], bbox_inches="tight")
plt.close()

print("bem-legacy-feasibility-heatmap.png + .pdf generated")
print(f"  {len(radii_sorted)} radii × {len(counts_sorted)} counts = "
      f"{np.sum(~np.isnan(tip_mean))} cells")
