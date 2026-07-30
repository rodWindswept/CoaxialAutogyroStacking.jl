#!/usr/bin/env python3
"""bem-force-breakdown: Per-rotor force components — along-line vs losses."""
import csv
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

with open("force_breakdown.csv") as f:
    rows = list(csv.DictReader(f))

# Group by wind speed
from collections import defaultdict
by_ws = defaultdict(list)
for r in rows:
    by_ws[float(r["wind_speed"])].append({
        "pos": int(r["rotor_position"]),
        "along": float(r["along_line"]),
        "thrust": float(r["thrust"]),
        "drag": float(r["drag_force"]),
        "weight": float(r["weight"]),
    })

fig, axes = plt.subplots(1, 2, figsize=(10, 5))
fig.patch.set_facecolor("white")
ax1, ax2 = axes

# Left: stacked bar — useful vs losses at 8 m/s
ws8 = sorted(by_ws[8.0], key=lambda x: x["pos"])
positions = [f"R{r['pos']}" for r in ws8]
along = [r["along"] for r in ws8]
drag = [r["drag"] for r in ws8]
weight = [r["weight"] for r in ws8]

x = np.arange(len(positions))
w = 0.6
ax1.bar(x, along, w, color="#2166ac", label="Along-line force (useful)")
ax1.bar(x, drag, w, bottom=along, color="#f4a582", label="Line drag")
ax1.bar(x, weight, w, bottom=[a+d for a,d in zip(along, drag)],
        color="#bababa", label="Rotor weight (loss)")

# Add efficiency percentage
for i, (a, t, d, wgt) in enumerate(zip(along, [r["thrust"] for r in ws8],
                                          drag, weight)):
    eff = a / (a + d + wgt) * 100
    ax1.text(i, a + d + wgt + 1, f"{eff:.0f}%", ha="center", fontsize=9,
             fontweight="bold", color="#2166ac")

ax1.set_xticks(x)
ax1.set_xticklabels(positions)
ax1.set_ylabel("Force (N)", fontsize=11)
ax1.set_title("Force Budget per Rotor\nR=3.0m, N=4, 8 m/s",
              fontsize=11, fontweight="bold")
ax1.legend(fontsize=8, framealpha=0.9)
ax1.grid(True, alpha=0.3, axis="y")

# Right: along-line force vs wind speed by position
colors = ["#2166ac", "#67a9cf", "#d1e5f0", "#f4a582"]
for ws in [6, 8, 10, 12]:
    pts = sorted(by_ws[ws], key=lambda x: x["pos"])
    ax2.plot([r["pos"] for r in pts], [r["along"] for r in pts],
             "o-", linewidth=2, markersize=7,
             label=f"{ws:.0f} m/s")

ax2.set_xlabel("Rotor Position (1=topmost)", fontsize=11)
ax2.set_ylabel("Along-line Force (N)", fontsize=11)
ax2.set_title("Along-line Force vs Position\n"
              "R=3.0m, N=4, Graded Tilt, 45°",
              fontsize=11, fontweight="bold")
ax2.set_xticks([1, 2, 3, 4])
ax2.legend(fontsize=8, framealpha=0.9)
ax2.grid(True, alpha=0.3)

caption = (
    "IMPLICATIONS: Rotor weight (49 N) is the dominant loss — 20–27% of "
    "thrust. Line drag is negligible (<1 N per section). Along-line efficiency "
    "improves with wind speed (73%→79%). Force increases from top to bottom "
    "rotor by 10% — the polygon chain gives lower rotors a more favorable "
    "inflow angle. Data: BEM v2.1, corrected polygon solver. See SPEC.md §6.6."
)
fig.text(0.10, 0.02, caption, fontsize=8, color="#444444",
         ha="left", va="bottom", style="italic", wrap=True)
plt.subplots_adjust(left=0.07, right=0.95, top=0.90, bottom=0.22,
                    wspace=0.30)
fig.savefig("bem-force-breakdown.png", dpi=300, facecolor="white",
            bbox_inches="tight")
fig.savefig("bem-force-breakdown.pdf", facecolor="white", bbox_inches="tight")
plt.close()
print("bem-force-breakdown.png + .pdf generated")
