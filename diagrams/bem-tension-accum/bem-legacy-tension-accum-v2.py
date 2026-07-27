#!/usr/bin/env python3
"""V1 (uniform wind) vs V2 (wind gradient) tension profile comparison."""
import csv
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

def load_profile(path):
    profiles = {}
    with open(path) as f:
        for row in csv.DictReader(f):
            v = float(row["wind_speed"])
            d = float(row["distance_from_anchor"])
            t = float(row["tension"])
            profiles.setdefault(v, []).append((d, t))
    for v in profiles:
        profiles[v].sort(key=lambda x: x[0])
    return profiles

v1 = load_profile("tension_profile.csv")
v2 = load_profile("tension_profile_v2.csv")

wind_speeds = sorted(v1.keys())
colors = plt.cm.viridis(np.linspace(0.15, 0.95, len(wind_speeds)))
n_rotors = 4
total_len = n_rotors * 15.0

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6))
fig.patch.set_facecolor("white")

for ax, profiles, title_suffix in [
    (ax1, v1, "uniform wind"),
    (ax2, v2, "wind gradient (α=0.14)")]:
    
    ax.set_facecolor("white")
    for v, c in zip(wind_speeds, colors):
        ds = [p[0] for p in profiles[v]]
        ts = [p[1] for p in profiles[v]]
        ax.step(ds, ts, where="post", color=c, linewidth=1.8,
                label=f"{int(v)} m/s")
    
    # Rotor markers
    for i in range(1, n_rotors + 1):
        d = total_len - (i - 1) * 15.0
        ax.axvline(x=d, color="gray", linestyle=":", linewidth=0.7, alpha=0.5)
        ax.text(d, ax.get_ylim()[0] * 0.02, f"R{i}",
                ha="center", va="bottom", fontsize=8, color="#888888")
    
    ax.set_xlabel("Distance from Anchor (m)", fontsize=10)
    ax.set_ylabel("Cumulative Tension (N)", fontsize=10)
    ax.set_title(f"V2: {title_suffix}", fontsize=11, fontweight="bold")
    ax.legend(fontsize=7, framealpha=0.9, edgecolor="#cccccc")
    ax.grid(True, alpha=0.3, linestyle="--")

# Caption
caption = (
    "IMPLICATIONS: Wind gradient (power law, α=0.14) makes the top rotor "
    "see ~28% faster wind than the bottom rotor. Upper tension steps grow "
    "larger — the top rotor adds more force. At 16 m/s ref, anchor tension "
    "rises from 20 kN (uniform) to ~26 kN (gradient). The bottom step is "
    "smaller because the lowest rotor sees the slowest wind. Wind gradient "
    "increases peak anchor tension and shifts the load upward. "
    "Data: BEM v2.0, corrected polygon solver. See SPEC.md §6.6."
)
caption_text = fig.text(0.10, 0.02, caption, fontsize=8, color="#444444",
                         ha="left", va="bottom", style="italic", family="serif",
                         wrap=True)

plt.subplots_adjust(left=0.06, right=0.97, top=0.92, bottom=0.22, wspace=0.25)
fig.savefig("bem-tension-accum-v2.png", dpi=300,
            facecolor="white", edgecolor="none",
            bbox_extra_artists=[caption_text], bbox_inches="tight")
fig.savefig("bem-tension-accum-v2.pdf",
            facecolor="white", edgecolor="none",
            bbox_extra_artists=[caption_text], bbox_inches="tight")
plt.close()

print("bem-tension-accum-v2.png + .pdf generated")
