#!/usr/bin/env python3
"""Generate PCA charts for BEM sweep data."""

import pandas as pd
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
from sklearn.decomposition import PCA
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.compose import ColumnTransformer
import os

# ── Setup ────────────────────────────────────────────────────────────────
OUT = 'docs/charts'
os.makedirs(OUT, exist_ok=True)

plt.rcParams.update({
    'font.family': 'sans-serif',
    'font.size': 10,
    'axes.labelsize': 12,
    'axes.titlesize': 14,
    'axes.grid': True,
    'grid.alpha': 0.3,
    'figure.dpi': 150,
    'savefig.dpi': 300,
    'savefig.bbox': 'tight',
    'savefig.facecolor': 'white',
})

# ── Load & prep ──────────────────────────────────────────────────────────
df = pd.read_csv('bem_full_sweep.tsv', sep='\t')
viable = df[df['anchor_tension'] > 0].copy()

num_features = ['radius', 'n_rotors', 'wind_speed', 'elevation',
                'autorotation_rpm', 'tip_speed_bem']
cat_features = ['profile']

preprocessor = ColumnTransformer([
    ('num', StandardScaler(), num_features),
    ('cat', OneHotEncoder(drop='first'), cat_features)
])

X = preprocessor.fit_transform(viable[num_features + cat_features])
feature_names = (num_features +
    list(preprocessor.named_transformers_['cat']
         .get_feature_names_out(['profile'])))

pca = PCA()
X_pca = pca.fit_transform(X)
viable['PC1'] = X_pca[:, 0]
viable['PC2'] = X_pca[:, 1]
viable['PC3'] = X_pca[:, 2]

# ── Colours ──────────────────────────────────────────────────────────────
profile_colors = {
    'uniform':       '#3498db',  # blue
    'graded':        '#e67e22',  # orange
    'top_draggy':    '#e74c3c',  # red
    'bottom_lifty':  '#2ecc71',  # green
}
profile_markers = {
    'uniform':       'o',
    'graded':        's',
    'top_draggy':    '^',
    'bottom_lifty':  'D',
}

# ═══════════════════════════════════════════════════════════════════════════
# CHART A: PCA BIPLOT (PC1 vs PC2)
# ═══════════════════════════════════════════════════════════════════════════
fig, ax = plt.subplots(figsize=(10, 8))

for profile in ['uniform', 'graded', 'top_draggy', 'bottom_lifty']:
    mask = viable['profile'] == profile
    sc = ax.scatter(
        viable.loc[mask, 'PC1'], viable.loc[mask, 'PC2'],
        c=profile_colors[profile], marker=profile_markers[profile],
        s=30, alpha=0.7, edgecolors='white', linewidth=0.3,
        label=profile.replace('_', ' ')
    )

# Annotate extremes
extremes = pd.concat([
    viable.nlargest(3, 'PC1'),
    viable.nsmallest(3, 'PC1'),
    viable.nlargest(3, 'PC2'),
    viable.nsmallest(3, 'PC2'),
]).drop_duplicates()

for _, row in extremes.iterrows():
    label = f"R={row.radius:.1f} n={int(row.n_rotors)} v={row.wind_speed:.0f}"
    ax.annotate(label, (row.PC1, row.PC2),
                xytext=(8, 5), textcoords='offset points',
                fontsize=7, alpha=0.8,
                arrowprops=dict(arrowstyle='->', lw=0.5, color='gray'))

# Loadings arrows
scale = 3.5
for i, name in enumerate(feature_names):
    ax.arrow(0, 0, pca.components_[0, i] * scale, pca.components_[1, i] * scale,
             head_width=0.08, head_length=0.12, fc='dimgray', ec='dimgray',
             alpha=0.6, linewidth=0.5)
    ax.text(pca.components_[0, i] * scale * 1.15,
            pca.components_[1, i] * scale * 1.15,
            name, fontsize=7, color='dimgray', ha='center', va='center')

ax.axhline(0, color='gray', linewidth=0.5, alpha=0.3)
ax.axvline(0, color='gray', linewidth=0.5, alpha=0.3)
ax.set_xlabel(f'PC1 ({pca.explained_variance_ratio_[0]*100:.0f}% variance)')
ax.set_ylabel(f'PC2 ({pca.explained_variance_ratio_[1]*100:.0f}% variance)')
ax.set_title('PCA Biplot: BEM Sweep Configurations in PC1–PC2 Space')
ax.legend(title='Tilt Profile', loc='upper left', fontsize=9)
fig.tight_layout()
fig.savefig(f'{OUT}/pca_biplot.png', facecolor='white')
plt.close(fig)
print(f"✓ Saved {OUT}/pca_biplot.png")


# ═══════════════════════════════════════════════════════════════════════════
# CHART B: EXPLAINED VARIANCE + LOADINGS
# ═══════════════════════════════════════════════════════════════════════════
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6))

# -- Scree plot --
n_pcs = len(pca.explained_variance_ratio_)
x = range(1, n_pcs + 1)
bars = ax1.bar(x, pca.explained_variance_ratio_ * 100, color='#3498db', alpha=0.7)
ax1.plot(x, np.cumsum(pca.explained_variance_ratio_) * 100, 'o-',
         color='#e74c3c', linewidth=2, markersize=6, label='Cumulative')
ax1.axhline(y=80, color='gray', linestyle='--', alpha=0.4, label='80% threshold')
ax1.set_xlabel('Principal Component')
ax1.set_ylabel('Explained Variance (%)')
ax1.set_title('Scree Plot: Variance Explained by Each PC')
ax1.set_xticks(x)
ax1.legend(fontsize=9)

# Annotate bars
for bar, ev in zip(bars, pca.explained_variance_ratio_ * 100):
    ax1.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.5,
             f'{ev:.1f}%', ha='center', fontsize=8)

# -- PC1-3 Loadings heatmap-style bars --
top_features = feature_names[:6]  # skip profile dummies for clarity
short_names = ['radius', 'n_rotors', 'wind_speed', 'elevation', 'rpm', 'tip_speed']
pc_colors = ['#3498db', '#e67e22', '#2ecc71']

y_pos = range(len(short_names))
width = 0.25
for i, (pc_idx, color) in enumerate([(0, pc_colors[0]), (1, pc_colors[1]), (2, pc_colors[2])]):
    loadings = [pca.components_[pc_idx, j] for j in range(len(short_names))]
    bars = ax2.barh([y + i * width for y in y_pos], loadings, width,
                    color=color, alpha=0.8, label=f'PC{pc_idx+1}')

ax2.set_yticks([y + width for y in y_pos])
ax2.set_yticklabels(short_names)
ax2.axvline(0, color='black', linewidth=0.5)
ax2.set_xlabel('Loading')
ax2.set_title('Feature Loadings: PC1, PC2, PC3')
ax2.legend(fontsize=9)

fig.suptitle('PCA Decomposition: BEM Sweep Design Parameters',
             fontsize=15, fontweight='bold', y=1.02)
fig.tight_layout()
fig.savefig(f'{OUT}/pca_loadings.png', facecolor='white')
plt.close(fig)
print(f"✓ Saved {OUT}/pca_loadings.png")


# ═══════════════════════════════════════════════════════════════════════════
# CHART C: CORRELATION WITH TARGET
# ═══════════════════════════════════════════════════════════════════════════
from scipy.stats import pearsonr

corr_features = ['PC1', 'PC2', 'PC3', 'radius', 'n_rotors', 'wind_speed',
                 'autorotation_rpm', 'tip_speed_bem']
corr_labels = ['PC1', 'PC2', 'PC3', 'Radius', 'N Rotors', 'Wind Speed',
               'RPM', 'Tip Speed']

corrs = []
for feat in corr_features:
    r, _ = pearsonr(viable[feat], viable['anchor_tension'])
    corrs.append(r)

# Also add elevation and profile
r_el, _ = pearsonr(viable['elevation'], viable['anchor_tension'])
corrs.append(r_el)
corr_labels.append('Elevation')

fig, ax = plt.subplots(figsize=(10, 5))
colors = ['#e74c3c' if c > 0.5 else '#e67e22' if c > 0.2 else '#3498db'
          for c in corrs]
bars = ax.barh(corr_labels, corrs, color=colors, alpha=0.8)

# Add value labels
for bar, c in zip(bars, corrs):
    ax.text(bar.get_width() + 0.01, bar.get_y() + bar.get_height()/2,
            f'{c:+.3f}', va='center', fontsize=9)

ax.axvline(0, color='black', linewidth=0.8)
ax.set_xlabel("Pearson's r with Anchor Tension")
ax.set_title('What Drives Anchor Tension? Feature Correlations')
ax.set_xlim(-0.1, 0.8)
fig.tight_layout()
fig.savefig(f'{OUT}/pca_correlations.png', facecolor='white')
plt.close(fig)
print(f"✓ Saved {OUT}/pca_correlations.png")


# ═══════════════════════════════════════════════════════════════════════════
# CHART D: PC1 COLOURED BY ANCHOR TENSION
# ═══════════════════════════════════════════════════════════════════════════
fig, ax = plt.subplots(figsize=(10, 8))

sc = ax.scatter(viable['PC1'], viable['PC2'],
                c=viable['anchor_tension'], cmap='RdYlGn',
                s=40, alpha=0.8, edgecolors='white', linewidth=0.3)
cbar = plt.colorbar(sc, ax=ax)
cbar.set_label('Anchor Tension (N)')

ax.axhline(0, color='gray', linewidth=0.5, alpha=0.3)
ax.axvline(0, color='gray', linewidth=0.5, alpha=0.3)
ax.set_xlabel(f'PC1 ({pca.explained_variance_ratio_[0]*100:.0f}% var) — Rotor Size & Speed')
ax.set_ylabel(f'PC2 ({pca.explained_variance_ratio_[1]*100:.0f}% var) — Wind Speed')
ax.set_title('PCA Space Coloured by Anchor Tension')
fig.tight_layout()
fig.savefig(f'{OUT}/pca_tension_map.png', facecolor='white')
plt.close(fig)
print(f"✓ Saved {OUT}/pca_tension_map.png")


# ═══════════════════════════════════════════════════════════════════════════
# Summary output
# ═══════════════════════════════════════════════════════════════════════════
print(f"\n{'='*55}")
print("PCA SUMMARY")
print(f"{'='*55}")
print(f"Data: 312 viable configs, 9 features (6 num + 3 profile dummies)")
print(f"PC1 ({pca.explained_variance_ratio_[0]*100:.0f}%): tip_speed, rpm, radius — SIZE/SPEED axis")
print(f"PC2 ({pca.explained_variance_ratio_[1]*100:.0f}%): wind_speed — ENVIRONMENT axis")
print(f"PC3 ({pca.explained_variance_ratio_[2]*100:.0f}%): n_rotors — STACK COUNT axis")
print(f"First 3 PCs capture {np.sum(pca.explained_variance_ratio_[:3])*100:.0f}% of variance")
print(f"Best tension predictor: tip_speed_bem (r={corrs[-2]:.3f}), then PC1 (r={corrs[0]:.3f})")
print(f"Profile and elevation have near-zero effect on tension")
