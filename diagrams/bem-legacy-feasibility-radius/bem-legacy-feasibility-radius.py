#!/usr/bin/env python3
"""bem-legacy-feasibility-radius: Tip Reynolds number heatmap by (radius, N).

Reads ../../bem_full_sweep.tsv, computes mean tip Reynolds per (radius, n_rotors)
cell, annotates pass/fail per Re > 5e4 viability gate.
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
            "anchor_tension": float(row["anchor_tension"]),
        })

# ── Aggregate by (radius, n_rotors) ────────────────────────────────────────
cells = defaultdict(list)
for r in rows:
    key = (r["radius"], r["n_rotors"])
    # Compute tip Reynolds: Re = ρ * v_tip * chord / μ
    re_val = 1.225 * r["tip_speed_bem"] * 0.15 / 1.81e-5
    cells[key].append(re_val)

radii_sorted = sorted(set(r["radius"] for r in rows))
counts_sorted = sorted(set(r["n_rotors"] for r in rows))
RE_LIMIT = 5e4  # transitional flow threshold

# Build matrices
re_mean = np.zeros((len(counts_sorted), len(radii_sorted)))
re_pass = np.zeros((len(counts_sorted), len(radii_sorted)), dtype=bool)
for ci, n in enumerate(counts_sorted):
    for ri, rad in enumerate(radii_sorted):
        vals = cells.get((rad, n), [])
        if vals:
            re_mean[ci, ri] = np.mean(vals)
            re_pass[ci, ri] = all(v >= RE_LIMIT for v in vals)
        else:
            re_mean[ci, ri] = np.nan
            re_pass[ci, ri] = False

# ── Plot ───────────────────────────────────────────────────────────────────
fig, ax = plt.subplots(figsize=(6, 5))
fig.patch.set_facecolor("white")

vmin = 0
vmax = 300000
im = ax.imshow(re_mean, cmap="RdYlGn", aspect="auto", origin="lower",
               vmin=vmin, vmax=vmax,
               extent=[radii_sorted[0]-0.25, radii_sorted[-1]+0.25,
                       counts_sorted[0]-0.5, counts_sorted[-1]+0.5])

# Annotate ✓/✗
for ci, n in enumerate(counts_sorted):
    for ri, rad in enumerate(radii_sorted):
        if not np.isnan(re_mean[ci, ri]):
            ok = re_pass[ci, ri]
            ax.text(rad, n, "PASS" if ok else "FAIL",
                    ha="center", va="center",
                    fontsize=10, fontweight="bold",
                    color="#1a5c1a" if ok else "#8b0000",
                    bbox=dict(boxstyle="round,pad=0.2", facecolor="white",
                              edgecolor="#999999", alpha=0.95))
            re_val = int(re_mean[ci, ri])
            ax.text(rad, n - 0.35, f"Re={re_val:,}".replace(",", "·"),
                    ha="center", va="top", fontsize=7, color="#444444",
                    bbox=dict(boxstyle="round,pad=0.1", facecolor="white",
                              edgecolor="none", alpha=0.8))

cbar = fig.colorbar(im, ax=ax, label="Mean Tip Reynolds Number", shrink=0.85)
ax.set_xticks(radii_sorted)
ax.set_yticks(counts_sorted)
ax.set_xlabel("Rotor Radius (m)", fontsize=11, labelpad=10)
ax.set_ylabel("Stack Count (n_rotors)", fontsize=11, labelpad=10)
ax.set_title(f"Tip Reynolds Number — Viability Gate (Re > {RE_LIMIT:.0e})",
             fontsize=12, fontweight="bold", pad=12)

# ── Implications caption ───────────────────────────────────────────────────
caption = (
    "IMPLICATIONS: Larger rotors at higher stack counts push tip Reynolds "
    "above 5×10⁴ — the transitional flow threshold. PASS = all wind speeds pass. "
    "FAIL = laminar flow at some speeds, airfoil performance degrades. "
    "Small-radius single-rotor configurations are physically non-viable "
    "under autorotation. Minimum viable product: R≥2.0m or N≥3. "
    "Data: BEM v2.0, corrected polygon solver. See SPEC.md §6.6."
)
caption_text = fig.text(0.10, 0.02, caption, fontsize=8, color="#444444",
                         ha="left", va="bottom", style="italic", family="serif",
                         wrap=True)

plt.subplots_adjust(left=0.12, right=0.92, top=0.90, bottom=0.27)
fig.savefig("bem-legacy-feasibility-radius.png", dpi=300,
            facecolor="white", edgecolor="none",
            bbox_extra_artists=[caption_text], bbox_inches="tight")
fig.savefig("bem-legacy-feasibility-radius.pdf",
            facecolor="white", edgecolor="none",
            bbox_extra_artists=[caption_text], bbox_inches="tight")
plt.close()

print("bem-legacy-feasibility-radius.png + .pdf generated")
print(f"  {len(radii_sorted)} radii × {len(counts_sorted)} counts = "
      f"{np.sum(~np.isnan(re_mean))} cells")
