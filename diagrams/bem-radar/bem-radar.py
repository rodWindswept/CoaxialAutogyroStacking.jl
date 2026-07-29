#!/usr/bin/env python3
"""bem-radar: Radar chart comparing 4 tilt profiles at best (R,N) config."""
import csv, numpy as np
from collections import defaultdict
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

# Load & aggregate
rows = []
with open("../../bem_full_sweep.tsv") as f:
    for row in csv.DictReader(f, delimiter="\t"):
        if float(row["anchor_tension"]) <= 0:
            continue
        rows.append({
            "radius": float(row["radius"]),
            "n_rotors": int(row["n_rotors"]),
            "profile": row["profile"],
            "anchor_tension": float(row["anchor_tension"]),
        })

# Aggregate by (radius, n_rotors, profile)
cells = defaultdict(list)
for r in rows:
    cells[(r["radius"], r["n_rotors"], r["profile"])].append(r["anchor_tension"])

# Compute figures of merit per cell
fom = []
for (radius, n_rotors, profile), tensions in cells.items():
    t_arr = np.array(tensions)
    fom.append({
        "radius": radius, "n_rotors": n_rotors, "profile": profile,
        "mean_tension": np.mean(t_arr),
        "tension_per_kg": np.mean(t_arr) / (n_rotors * 5.0),
        "max_tension": np.max(t_arr),
        "tension_cv": np.std(t_arr) / np.mean(t_arr) if np.mean(t_arr) > 0 else 0,
    })

# Find best (R,N) by mean tension
best = max(fom, key=lambda x: x["mean_tension"])
best_r, best_n = best["radius"], best["n_rotors"]

# Filter to best (R,N)
profiles_at_best = [f for f in fom if f["radius"] == best_r and f["n_rotors"] == best_n]
profile_order = ["uniform", "top_draggy", "bottom_lifty", "graded"]
profiles_at_best.sort(key=lambda x: profile_order.index(x["profile"]))

# Normalize each metric to [0,1] across the 4 profiles
def norm(vals):
    mn, mx = min(vals), max(vals)
    return [(v - mn) / (mx - mn) if mx > mn else 0 for v in vals]

metrics = {
    "Tension": norm([p["mean_tension"] for p in profiles_at_best]),
    "N/kg": norm([p["tension_per_kg"] for p in profiles_at_best]),
    "Max T": norm([p["max_tension"] for p in profiles_at_best]),
    "Stability": norm([1.0 - p["tension_cv"] for p in profiles_at_best]),
}
metric_names = list(metrics.keys())
n_metrics = len(metric_names)

# Radar plot
angles = np.linspace(0, 2 * np.pi, n_metrics, endpoint=False).tolist()
angles += angles[:1]  # close the polygon

PROFILE_COLORS = {
    "uniform": "#2166ac", "top_draggy": "#d6604d",
    "bottom_lifty": "#4daf4a", "graded": "#b2182b",
}

fig, ax = plt.subplots(figsize=(7, 7), subplot_kw=dict(polar=True))
fig.patch.set_facecolor("white")
ax.set_facecolor("white")

for prof in profile_order:
    vals = [metrics[m][i] for i, m in enumerate(metric_names)
            for p in [profiles_at_best] if p[profile_order.index(prof)]["profile"] == prof]
    # Actually simpler: just get the index
    idx = next(i for i, p in enumerate(profiles_at_best) if p["profile"] == prof)
    vals = [metrics[m][idx] for m in metric_names]
    vals += vals[:1]
    ax.fill(angles, vals, alpha=0.1, color=PROFILE_COLORS[prof])
    ax.plot(angles, vals, "o-", linewidth=2, color=PROFILE_COLORS[prof],
            label=prof, markersize=8)

ax.set_xticks(angles[:-1])
ax.set_xticklabels(metric_names, fontsize=11, fontweight="bold")
ax.set_ylim(0, 1.2)
# Push axis labels outward
ax.tick_params(axis="x", pad=30)
# Hide radial grid labels (0.2, 0.4...) — they overlap data
ax.set_yticklabels([])
ax.set_title(f"Tilt Profile Comparison — R={best_r}m, N={best_n}",
             fontsize=13, fontweight="bold", pad=20, va="bottom")
ax.legend(loc="lower left", fontsize=9, framealpha=0.95, edgecolor="#cccccc",
          bbox_to_anchor=(0.02, 0.02))
ax.grid(True, alpha=0.3)

# Caption
caption = (
    "IMPLICATIONS: Radar chart comparing 4 tilt profiles at the best "
    f"(R={best_r}m, N={best_n}) configuration. Values normalized 0–1 "
    "across profiles. Graded tilt edges ahead on tension and N/kg, but "
    "the absolute spread is 10.4% between best and worst "
    "(769–858 N mean across elevations). All profiles overlap heavily on "
    "Stability. Tilt profile has a moderate effect — not negligible. "
    "Build uniform tilt for manufacturing simplicity — graded tilt adds "
    "complexity for a 10% gain. "
    "Data: BEM v2.1, corrected polygon solver. See SPEC.md §6.6."
)
caption_text = fig.text(0.10, 0.02, caption, fontsize=8, color="#444444",
                         ha="left", va="bottom", style="italic", family="serif",
                         wrap=True)

plt.subplots_adjust(left=0.05, right=0.95, top=0.90, bottom=0.30)
fig.savefig("bem-radar.png", dpi=300, facecolor="white", edgecolor="none",
            bbox_extra_artists=[caption_text], bbox_inches="tight")
fig.savefig("bem-radar.pdf", facecolor="white", edgecolor="none",
            bbox_extra_artists=[caption_text], bbox_inches="tight")
plt.close()

print(f"bem-radar.png + .pdf generated — best R={best_r}m, N={best_n}")
for p in profiles_at_best:
    print(f"  {p['profile']}: T={p['mean_tension']:.0f} N, "
          f"N/kg={p['tension_per_kg']:.1f}, CV={p['tension_cv']:.3f}")
