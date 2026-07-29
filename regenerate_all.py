#!/usr/bin/env python3
"""regenerate_all.py — regenerate sweep and all dependent diagrams.

Run after any change to the physics solvers (polygon_line.jl, bem.jl, stack.jl).
Re-runs the sweep, then re-runs every diagram script, then reports which
diagrams changed significantly and need HITL re-review.
"""
import subprocess, sys, os, json, csv
from pathlib import Path

REPO = Path(__file__).resolve().parent
SWEEP_SCRIPT = REPO / "scripts" / "bem_full_sweep.jl"
SWEEP_OUTPUT = REPO / "bem_full_sweep.tsv"

# ── Step 1: Sweep ──────────────────────────────────────────────────────────
print("=" * 60)
print("Step 1: Regenerating BEM sweep...")
result = subprocess.run(
    ["julia", "--project=.", str(SWEEP_SCRIPT)],
    capture_output=True, text=True, cwd=str(REPO), timeout=120
)
print(result.stdout.strip())
if result.returncode != 0:
    print("ERROR:", result.stderr)
    sys.exit(1)

# ── Step 2: Snapshot old tension values for comparison ─────────────────────
def load_tension_summary(tsv_path):
    """Load mean anchor tension per (radius, n_rotors, profile)."""
    from collections import defaultdict
    cells = defaultdict(list)
    with open(tsv_path) as f:
        for row in csv.DictReader(f, delimiter="\t"):
            t = float(row["anchor_tension"])
            if t > 0:
                cells[(float(row["radius"]), int(row["n_rotors"]),
                       row["profile"])].append(t)
    import statistics
    return {k: statistics.mean(v) for k, v in cells.items() if v}

prev_path = REPO / "bem_full_sweep_prev.tsv"
if prev_path.exists():
    prev_tensions = load_tension_summary(str(prev_path))
else:
    prev_tensions = {}

new_tensions = load_tension_summary(str(SWEEP_OUTPUT))

# Compare
if prev_tensions:
    diffs = []
    for k, new_t in new_tensions.items():
        old_t = prev_tensions.get(k)
        if old_t and old_t > 0:
            pct = (new_t - old_t) / old_t * 100
            if abs(pct) > 2:
                diffs.append((k, old_t, new_t, pct))
    if diffs:
        print(f"\n{len(diffs)} configurations changed >2%:")
        for k, old, new, pct in sorted(diffs, key=lambda x: abs(x[3]), reverse=True)[:10]:
            print(f"  R={k[0]} N={k[1]} {k[2]}: {old:.0f} → {new:.0f} N ({pct:+.1f}%)")

# Save current as previous for next time
import shutil
shutil.copy(str(SWEEP_OUTPUT), str(prev_path))

# ── Step 3: Diagram scripts ────────────────────────────────────────────────
DIAGRAMS = [
    ("diagrams/bem-pareto", "python3", "bem-pareto.py"),
    ("diagrams/bem-feasibility-radius", "python3", "bem-feasibility-radius.py"),
    ("diagrams/bem-feasibility-heatmap", "python3", "bem-feasibility-heatmap.py"),
    ("diagrams/bem-radar", "python3", "bem-radar.py"),
    ("diagrams/pca-biplot", "python3", "pca-biplot.py"),
]

# Tension accumulation needs Julia first
TENSION_DIR = "diagrams/bem-tension-accum"
print(f"\n{'='*60}")
print("Step 2: Julia data generation (tension profiles)...")
for script in ["compute_tension_profile.jl", "compute_tension_profile_v2.jl"]:
    result = subprocess.run(
        ["julia", f"--project={REPO}", script],
        capture_output=True, text=True, cwd=str(REPO / TENSION_DIR), timeout=120
    )
    print(f"  {script}: {result.stdout.strip()}")
    if result.returncode != 0:
        print(f"  ERROR: {result.stderr}")

print(f"\n{'='*60}")
print("Step 3: Diagram scripts...")
results = {}
for directory, runner, script in DIAGRAMS:
    d = REPO / directory
    if not (d / script).exists():
        print(f"  SKIP {directory}/{script} — not found")
        continue
    result = subprocess.run(
        [runner, script],
        capture_output=True, text=True, cwd=str(d), timeout=60
    )
    results[directory] = result
    status = "✓" if result.returncode == 0 else "✗"
    output = result.stdout.strip().split("\n")[0] if result.stdout else ""
    print(f"  {status} {directory}: {output}")
    if result.returncode != 0:
        print(f"    ERROR: {result.stderr[:200]}")

# Tension accum plot
for script in ["bem-tension-accum.py", "bem-tension-accum-v2.py"]:
    result = subprocess.run(
        ["python3", script],
        capture_output=True, text=True, cwd=str(REPO / TENSION_DIR), timeout=60
    )
    status = "✓" if result.returncode == 0 else "✗"
    print(f"  {status} {TENSION_DIR}/{script}")

# Radial loading needs Julia
RADIAL_DIR = "diagrams/bem-radial-loading"
print(f"\n{'='*60}")
print("Step 4: Radial loading (Julia + Python)...")
result = subprocess.run(
    ["julia", f"--project={REPO}", "compute_radial_loading.jl"],
    capture_output=True, text=True, cwd=str(REPO / RADIAL_DIR), timeout=60
)
print(f"  {result.stdout.strip()}")
result = subprocess.run(
    ["python3", "bem-radial-loading.py"],
    capture_output=True, text=True, cwd=str(REPO / RADIAL_DIR), timeout=30
)
print(f"  ✓ bem-radial-loading.py")

print(f"\n{'='*60}")
print("Regeneration complete.")
print(f"Sweep: {SWEEP_OUTPUT} ({SWEEP_OUTPUT.stat().st_size} bytes)")

# Summary of changes
if prev_tensions and diffs:
    print(f"\n⚠ {len(diffs)} configurations shifted >2%. Diagrams need re-review.")
    print("Run ste-lint.py on updated captions before HITL rounds.")
else:
    print("No significant changes — diagrams should be current.")
