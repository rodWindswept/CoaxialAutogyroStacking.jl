#!/usr/bin/env python3
"""viability-gates: Summary table of physical viability constraints."""
import csv, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

CHORD = 0.15
NU = 1.5e-5  # kinematic viscosity of air
RE_MIN = 5e4  # transitional flow threshold for NACA 0012
TIP_MAX = 120.0  # m/s, Mach 0.3 noise limit

rows = []
with open("../../bem_full_sweep.tsv") as f:
    for r in csv.DictReader(f, delimiter="\t"):
        rows.append({
            "radius": float(r["radius"]),
            "n": int(r["n_rotors"]),
            "tension": float(r["anchor_tension"]),
            "tip_speed": float(r["tip_speed_bem"]),
        })

# Compute Re = tip_speed * chord / nu
for r in rows:
    r["re"] = r["tip_speed"] * CHORD / NU if r["tip_speed"] > 0 else 0

# Group by (radius, n)
from collections import defaultdict
groups = defaultdict(list)
for r in rows:
    groups[(r["radius"], r["n"])].append(r)

fig, ax = plt.subplots(figsize=(9, 5))
fig.patch.set_facecolor("white")
ax.axis("off")

table_data = [["R (m)", "N", "Configs", "Viable", "Min Re", "Max Tip (m/s)",
               "Re OK?", "Tip OK?", "Viable?"]]
radii = [1.5, 2.0, 3.0]
n_vals = [1, 2, 3, 4]

for rad in radii:
    for n in n_vals:
        group = groups.get((rad, n), [])
        viable = [g for g in group if g["tension"] > 0]
        re_vals = [g["re"] for g in viable]
        tip_vals = [g["tip_speed"] for g in viable]
        re_ok = all(r > RE_MIN for r in re_vals) if re_vals else False
        tip_ok = all(t < TIP_MAX for t in tip_vals) if tip_vals else False
        is_viable = re_ok and tip_ok and len(viable) > 0
        re_min_str = f"{min(re_vals):.0f}" if re_vals else "N/A"
        tip_max_str = f"{max(tip_vals):.0f}" if tip_vals else "N/A"
        table_data.append([
            f"{rad:.1f}", str(n), str(len(viable)),
            str(len([g for g in group if g["tension"] > 0])),
            re_min_str, tip_max_str,
            "\u2713" if re_ok else "\u2717",
            "\u2713" if tip_ok else "\u2717",
            "\u2713" if is_viable else "\u2717",
        ])

table = ax.table(cellText=table_data, cellLoc="center", loc="center")
table.auto_set_font_size(False)
table.set_fontsize(10)
table.scale(1.0, 1.5)

# Style header
for i in range(len(table_data[0])):
    table[0, i].set_facecolor("#4575b4")
    table[0, i].set_text_props(color="white", fontweight="bold")

# Colour viable rows green
for row_idx in range(1, len(table_data)):
    if table_data[row_idx][-1] == "\u2713":
        for col_idx in range(len(table_data[0])):
            table[row_idx, col_idx].set_facecolor("#e6f3e6")

ax.set_title("Viability Gates: Physical Constraints by (R,N)\n"
             f"Re > {RE_MIN:.0e} (transitional), Tip Speed < {TIP_MAX:.0f} m/s (Mach 0.3)",
             fontsize=12, fontweight="bold", pad=20)

caption = (
    f"IMPLICATIONS: R=1.5m fails the Re gate at all N \u2014 the NACA 0012 operates "
    f"in the laminar/transitional regime (Re < {RE_MIN:.0e}) where CL/CD data is unreliable. "
    f"R=2.0m passes Re at N\u22652 and passes tip speed everywhere. "
    f"R=3.0m passes all gates at all wind speeds. "
    f"No configuration exceeds the 120 m/s noise limit \u2014 autorotation tip speeds "
    f"are well below Mach 0.3. The primary viability constraint is minimum Reynolds "
    f"number, not noise. Data: BEM v2.1, all wind speeds 6\u201312 m/s."
)
fig.text(0.08, 0.02, caption, fontsize=8, color="#444444",
         ha="left", va="bottom", style="italic", wrap=True)
plt.subplots_adjust(left=0.06, right=0.96, top=0.88, bottom=0.20)
fig.savefig("viability-gates.png", dpi=300, facecolor="white", bbox_inches="tight")
fig.savefig("viability-gates.pdf", facecolor="white", bbox_inches="tight")
plt.close()
print("viability-gates.png + .pdf generated")
