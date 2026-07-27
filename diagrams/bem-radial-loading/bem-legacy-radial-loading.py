#!/usr/bin/env python3
"""bem-radial-loading: CL distribution along blade — 2D vs 3D Snel."""
import csv
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

# Load
r_R, cl_2d, cl_3d, aoa = [], [], [], []
with open("radial_loading.csv") as f:
    for row in csv.DictReader(f):
        r_R.append(float(row["r_R"]))
        cl_2d.append(float(row["cl_2d"]))
        cl_3d.append(float(row["cl_3d"]))
        aoa.append(float(row["aoa_deg"]))

fig, ax1 = plt.subplots(figsize=(8, 5))
fig.patch.set_facecolor("white")

ax1.plot(r_R, cl_2d, "b-", linewidth=2, label="CL 2-D (NACA 0012)")
ax1.plot(r_R, cl_3d, "r-", linewidth=2, label="CL 3-D (Snel stall delay)")
ax1.set_xlabel("Radial position r/R", fontsize=11)
ax1.set_ylabel("Section lift coefficient CL", fontsize=11, color="black")
ax1.set_title("Radial BEM Loading — R=3.0m, 8 m/s, 45° — 2-D vs 3-D Snel",
             fontsize=12, fontweight="bold", pad=12)
ax1.legend(loc="upper left", fontsize=9, framealpha=0.9, edgecolor="#cccccc")
ax1.grid(True, alpha=0.3, linestyle="--")
ax1.set_xlim(0.15, 1.02)

# AoA on secondary axis
ax2 = ax1.twinx()
ax2.plot(r_R, aoa, "k--", linewidth=1, alpha=0.4, label="AoA (°)")
ax2.set_ylabel("Angle of attack (°)", fontsize=10, color="#666666")
ax2.legend(loc="upper right", fontsize=8, framealpha=0.9)

# Snel effect annotation
mid = len(r_R) // 2
ax1.annotate("Snel correction boosts CL\nnear root (high solidity)",
            xy=(0.35, cl_3d[mid]), xytext=(0.2, max(cl_2d) * 0.7),
            fontsize=9, color="#cc0000",
            arrowprops=dict(arrowstyle="->", color="#cc0000", lw=1.2))

# Caption
caption = (
    "IMPLICATIONS: The Snel 3-D stall delay correction increases CL by "
    "up to 30% near the blade root (r/R < 0.5), where the chord/radius "
    "ratio is highest and 2-D airfoil data underpredicts lift. Beyond "
    "r/R ≈ 0.6, the correction vanishes — the outer blade behaves as 2-D. "
    "BEM models without stall delay systematically under-predict thrust "
    "from the inboard section. Data: R=3.0m rotor at 8 m/s wind speed, "
    "45° elevation, 78 RPM autorotation. See SPEC.md §6.6."
)
caption_text = fig.text(0.10, 0.02, caption, fontsize=8, color="#444444",
                         ha="left", va="bottom", style="italic", family="serif",
                         wrap=True)

plt.subplots_adjust(left=0.11, right=0.88, top=0.92, bottom=0.24)
fig.savefig("bem-radial-loading.png", dpi=300,
            facecolor="white", edgecolor="none",
            bbox_extra_artists=[caption_text], bbox_inches="tight")
fig.savefig("bem-radial-loading.pdf",
            facecolor="white", edgecolor="none",
            bbox_extra_artists=[caption_text], bbox_inches="tight")
plt.close()

print("bem-radial-loading.png + .pdf generated")
