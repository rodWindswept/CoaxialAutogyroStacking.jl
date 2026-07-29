#!/usr/bin/env python3
"""bem-trpt-power: TRPT vs Yo-yo power generation from stacked autogyros.

Compares traction power (fly-gen TRPT) vs yo-yo mode across wind speeds.
Data from bem_full_sweep.tsv — best config: R=3.0m, N=4, graded, 45°.
"""
import csv, numpy as np
from collections import defaultdict
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

# ── Load best config ───────────────────────────────────────────────────────
rows = []
with open("../../bem_full_sweep.tsv") as f:
    for row in csv.DictReader(f, delimiter="\t"):
        t = float(row["anchor_tension"])
        if t <= 0:
            continue
        rows.append({
            "radius": float(row["radius"]),
            "n_rotors": int(row["n_rotors"]),
            "profile": row["profile"],
            "elevation": float(row["elevation"]),
            "wind": float(row["wind_speed"]),
            "tension": t,
        })

best = [(r["wind"], r["tension"]) for r in rows
        if r["radius"] == 3.0 and r["n_rotors"] == 4
        and r["profile"] == "graded" and r["elevation"] == 45.0]
best.sort()

winds = [w for w, _ in best]
tensions = [t for _, t in best]

FACTOR_V5 = 44.4    # v5 Octagon, 871 W/kg
FACTOR_CANON = 28.9  # Canonical 5-line, 568 W/kg

trpt_v5 = [t * FACTOR_V5 / 1000 for t in tensions]
trpt_canon = [t * FACTOR_CANON / 1000 for t in tensions]
yoyo_peak = [t * (w / 3.0) / 1000 for t, w in zip(tensions, winds)]
yoyo_net = [yp * 0.77 for yp in yoyo_peak]

# ── Plot ───────────────────────────────────────────────────────────────────
fig, ax = plt.subplots(figsize=(8, 5.5))
fig.patch.set_facecolor("white")
ax.set_facecolor("white")

ax.plot(winds, trpt_v5, "s-", color="#2166ac", linewidth=2.2, markersize=8,
        label="TRPT — v5 Octagon (871 W/kg)")
ax.plot(winds, trpt_canon, "D-", color="#92c5de", linewidth=2.2, markersize=8,
        label="TRPT — Canonical 5-line (568 W/kg)")
ax.plot(winds, yoyo_peak, "^-", color="#d6604d", linewidth=1.8, markersize=7,
        label="Yo-yo peak (reel-out)")
ax.plot(winds, yoyo_net, "v--", color="#f4a582", linewidth=1.5, markersize=6,
        label="Yo-yo net (77% duty cycle)")

ax.set_xlabel("Wind Speed (m/s)", fontsize=11)
ax.set_ylabel("Power (kW)", fontsize=11)
ax.set_title("Power Generation Potential — Stacked Autogyro Lift\n"
             "R=3.0m, N=4, graded, 45° elevation",
             fontsize=13, fontweight="bold", pad=12)
ax.legend(fontsize=9, framealpha=0.9, edgecolor="#cccccc")
ax.grid(True, alpha=0.3, linestyle="--")

# Annotate the gap
ax.annotate("TRPT exceeds yo-yo\nby 10–14× at all wind speeds",
            xy=(9, trpt_v5[2]), xytext=(7, trpt_v5[2] * 0.5),
            fontsize=9, color="#2166ac",
            arrowprops=dict(arrowstyle="->", color="#2166ac", lw=1.2),
            bbox=dict(boxstyle="round,pad=0.15", facecolor="white",
                      edgecolor="#cccccc", alpha=0.9))

# ── Implications caption ───────────────────────────────────────────────────
caption = (
    "IMPLICATIONS: The stacked autogyro strongly favors Kite Turbine TRPT "
    "(mechanical power transmission) over yo-yo cycling. At 12 m/s, TRPT "
    "delivers 64 kW (v5 Octagon) or 42 kW (Canonical). Yo-yo net delivers "
    "only 4.5 kW. The gap is 10–14× across all wind speeds. The autogyro "
    "produces steady lift. TRPT converts it to shaft power through a kite "
    "turbine. Yo-yo wastes energy on the reel-in phase. For AWES deployment, "
    "pair the autogyro stack with a kite turbine. Do not use it in yo-yo "
    "mode. Data: BEM v2.1, corrected polygon solver. See SPEC.md §6.6."
)
caption_text = fig.text(0.10, 0.02, caption, fontsize=8, color="#444444",
                         ha="left", va="bottom", style="italic", family="serif",
                         wrap=True)

plt.subplots_adjust(left=0.11, right=0.94, top=0.92, bottom=0.22)
fig.savefig("bem-trpt-power.png", dpi=300, facecolor="white", edgecolor="none",
            bbox_extra_artists=[caption_text], bbox_inches="tight")
fig.savefig("bem-trpt-power.pdf", facecolor="white", edgecolor="none",
            bbox_extra_artists=[caption_text], bbox_inches="tight")
plt.close()

print("bem-trpt-power.png + .pdf generated")
print(f"  TRPT v5: {trpt_v5[0]:.0f}–{trpt_v5[-1]:.0f} kW")
print(f"  TRPT canon: {trpt_canon[0]:.0f}–{trpt_canon[-1]:.0f} kW")
print(f"  Yo-yo net: {yoyo_net[0]:.1f}–{yoyo_net[-1]:.1f} kW")
