#!/usr/bin/env python3
"""PCA analysis of BEM sweep data for CoaxialAutogyroStacking.jl."""

import pandas as pd
import numpy as np
from sklearn.decomposition import PCA
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.compose import ColumnTransformer
from scipy.stats import pearsonr

# ── Load ────────────────────────────────────────────────────────────────
df = pd.read_csv('bem_full_sweep.tsv', sep='\t')

# Filter viable (tension > 0)
viable = df[df['anchor_tension'] > 0].copy()
print(f"Total rows: {len(df)}, Viable (tension > 0): {len(viable)}")

# ── Features ─────────────────────────────────────────────────────────────
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
print(f"\nFeature matrix: {X.shape[0]} rows × {X.shape[1]} columns")
print(f"Features: {feature_names}")

# ── PCA ──────────────────────────────────────────────────────────────────
pca = PCA()
X_pca = pca.fit_transform(X)

print("\n" + "=" * 55)
print("EXPLAINED VARIANCE")
print("=" * 55)
for i, (ev, evr) in enumerate(zip(pca.explained_variance_,
                                   pca.explained_variance_ratio_)):
    cum = np.sum(pca.explained_variance_ratio_[:i + 1])
    bar = "█" * int(evr * 50)
    print(f"  PC{i+1}: {evr*100:5.1f}%  cum={cum*100:5.1f}%  {bar}")

# ── Loadings ─────────────────────────────────────────────────────────────
def print_loadings(pc_idx, label):
    print(f"\n{'─' * 55}")
    print(f"{label} LOADINGS")
    print(f"{'─' * 55}")
    comp = pca.components_[pc_idx]
    ranked = sorted(zip(feature_names, comp),
                    key=lambda x: abs(x[1]), reverse=True)
    for name, val in ranked:
        direction = "→" if val > 0 else "←"
        print(f"  {direction} {name:30s} {val:+.4f}")

print_loadings(0, "PC1")
print_loadings(1, "PC2")
print_loadings(2, "PC3")

# ── PC scores in dataframe ───────────────────────────────────────────────
viable['PC1'] = X_pca[:, 0]
viable['PC2'] = X_pca[:, 1]
viable['PC3'] = X_pca[:, 2]

# ── Clusters by profile ──────────────────────────────────────────────────
print(f"\n{'─' * 55}")
print("PC MEANS BY PROFILE")
print(f"{'─' * 55}")
print(viable.groupby('profile')[['PC1', 'PC2', 'PC3']].mean().to_string())

# ── Correlation with target ──────────────────────────────────────────────
print(f"\n{'─' * 55}")
print("CORRELATION WITH ANCHOR TENSION")
print(f"{'─' * 55}")
for pc in ['PC1', 'PC2', 'PC3']:
    r, p = pearsonr(viable[pc], viable['anchor_tension'])
    stars = "***" if p < 0.001 else "**" if p < 0.01 else "*" if p < 0.05 else ""
    print(f"  {pc}: r = {r:+.4f}  p = {p:.2e} {stars}")

# Also raw feature correlations with tension
print(f"\n  Raw feature correlations:")
for feat in num_features:
    r, p = pearsonr(viable[feat], viable['anchor_tension'])
    print(f"    {feat:25s} r = {r:+.4f}")

# ── PC variance by n_rotors ──────────────────────────────────────────────
print(f"\n{'─' * 55}")
print("PC1 RANGE BY N_ROTORS")
print(f"{'─' * 55}")
for n in sorted(viable['n_rotors'].unique()):
    subset = viable[viable['n_rotors'] == n]
    print(f"  n_rotors={int(n)}: PC1 mean={subset['PC1'].mean():+.3f}, "
          f"range=[{subset['PC1'].min():+.3f}, {subset['PC1'].max():+.3f}]")

# ── Top/bottom configurations in PC space ────────────────────────────────
print(f"\n{'─' * 55}")
print("TOP 5 CONFIGS BY PC1 (most 'powerful')")
print(f"{'─' * 55}")
top5 = viable.nlargest(5, 'PC1')[
    ['radius', 'n_rotors', 'wind_speed', 'profile', 'anchor_tension',
     'autorotation_rpm', 'PC1', 'PC2']]
print(top5.to_string(index=False))

print(f"\nBOTTOM 5 CONFIGS BY PC1 (least 'powerful')")
print(f"{'─' * 55}")
bot5 = viable.nsmallest(5, 'PC1')[
    ['radius', 'n_rotors', 'wind_speed', 'profile', 'anchor_tension',
     'autorotation_rpm', 'PC1', 'PC2']]
print(bot5.to_string(index=False))

# ── Save ─────────────────────────────────────────────────────────────────
viable.to_csv('bem_pca_scores.tsv', sep='\t', index=False)
print(f"\n✓ Saved {len(viable)} rows to bem_pca_scores.tsv")
