#!/usr/bin/env python3
"""bem-tension-accum: Tension accumulation along the polygon line.

Computes tension profile data via Julia (compute_tension_profile.jl),
then plots multi-line chart: tension vs distance from anchor for multiple
wind speeds.
"""
import csv, subprocess, sys
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

# ── Generate data via Julia ────────────────────────────────────────────────
print("Computing tension profiles (Julia)...")
result = subprocess.run(
    ["julia", "--project=../..", "compute_tension_profile.jl"],
    capture_output=True, text=True, cwd="."
)
if result.returncode != 0:
    print("ERROR:", result.stderr)
    sys.exit(1)
print(result.stdout.strip())

# ── Load ───────────────────────────────────────────────────────────────────
profiles = {}
with open("tension_profile.csv") as f:
    for row in csv.DictReader(f):
        v = float(row["wind_speed"])
        d = float(row["distance_from_anchor"])
        t = float(row["tension"])
        profiles.setdefault(v, []).append((d, t))

for v in profiles:
    profiles[v].sort(key=lambda x: x[0])

# ── Plot ───────────────────────────────────────────────────────────────────
fig, ax = plt.subplots(figsize=(8, 6))
fig.patch.set_facecolor("white")
ax.set_facecolor("white")

wind_speeds = sorted(profiles.keys())
colors = plt.cm.viridis(np.linspace(0.15, 0.95, len(wind_speeds)))

best_n = 4
total_len = best_n * 15.0

for v, c in zip(wind_speeds, colors):
    ds = [p[0] for p in profiles[v]]
    ts = [p[1] for p in profiles[v]]
    ax.step(ds, ts, where="post", color=c, linewidth=2.2,
            label=f"{int(v)} m/s")

# Rotor position markers — topmost (R1) at 60m, lowest (R4) at 15m above anchor
for i in range(1, best_n + 1):
    d = total_len - (i - 1) * 15.0  # R1 at 60m, R2 at 45m, R3 at 30m, R4 at 15m
    ax.axvline(x=d, color="gray", linestyle=":", linewidth=0.8, alpha=0.6)
    label_y = ax.get_ylim()[0] * 0.02
    ax.text(d, label_y, f"R{i}",
            ha="center", va="bottom", fontsize=9, color="#666666")

ax.set_xlabel("Distance from Anchor (m)", fontsize=11)
ax.set_ylabel("Cumulative Tension (N)", fontsize=11)
ax.set_title("Tension Accumulation — R=3.0m, N=4, graded, 45°",
             fontsize=13, fontweight="bold", pad=12)
ax.legend(title="Wind speed", fontsize=8, framealpha=0.9, edgecolor="#cccccc")
ax.grid(True, alpha=0.3, linestyle="--")

# ── Implications caption ───────────────────────────────────────────────────
caption = (
    "IMPLICATIONS: Tension accumulates toward the anchor — each rotor "
    "adds ~1,250 N of along-line force at 8 m/s (~5,200 N at 16 m/s). "
    "Between rotors, bare-line drag adds further tension. Tension above "
    "the topmost rotor drops to zero. Note: wind gradient is NOT modeled — "
    "all rotors see the same freestream speed. With real wind shear "
    "(exponent 0.14), the top rotor at 60m sees ~28% faster wind than at "
    "15m, making upper steps larger. Anchor line must be rated for ~20 kN "
    "at 16 m/s for this 4-rotor stack. Data: BEM v2.0, corrected polygon "
    "solver. See SPEC.md §6.6."
)
caption_text = fig.text(0.10, 0.02, caption, fontsize=8, color="#444444",
                         ha="left", va="bottom", style="italic", family="serif",
                         wrap=True)

plt.subplots_adjust(left=0.11, right=0.94, top=0.93, bottom=0.22)
fig.savefig("bem-tension-accum.png", dpi=300,
            facecolor="white", edgecolor="none",
            bbox_extra_artists=[caption_text], bbox_inches="tight")
fig.savefig("bem-tension-accum.pdf",
            facecolor="white", edgecolor="none",
            bbox_extra_artists=[caption_text], bbox_inches="tight")
plt.close()

print("bem-tension-accum.png + .pdf generated")
