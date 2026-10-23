# Handover: desktop repo-hygiene pass (2026-10-23)

**From** the desktop seat (hermes). **To** the laptop seat and Rod.

The desktop seat ran the repo-improvement plan the founder agreed on
2026-10-22. Everything landed on master and pushes with this note.

## What landed

- `459ddc3` hook: the markdown STE gate now honours a `.ste-exempt`
  ledger list (DECISIONS.md, CHANGELOG.md, STANDARDS, handovers/). New
  entries in an exempt file must still read STE-clean. The hook is
  installed in `.git/hooks/pre-commit` on the desktop.
- `83e43c3` register: `docs/numbers-register.md` opens the scaffold.
  Nine candidate rows (CA-001 to CA-009) copy values from committed
  docs, all unsigned. The discipline mirrors KTD: one row per number,
  amend-only once signed, the validator reproduces before signing.
- `123baff` checks: `scripts/doc_currency_check.py` ports the KTD
  currency check. Four sensors: decision lag behind src commits, the
  AGENTS.md file map against the tree, register coverage against
  number-shaped claims, aged plan docs. Run it after every pull.
- `77055dc` decisions: D8 to D12 backfill the unlogged physics
  decisions. D8 wake lineage (Jensen/PARK then Bastankhah 2026 with the
  AtWIND-lab crosscheck), D9 Prandtl tip-loss, D10 Øye dynamic inflow,
  D11 NACA 4412, D12 Snel stall delay. Each cites its commit and its
  suite count.
- Worktrees pruned: `CoaxialAutogyroStacking.jl-aw-nb3` and
  `KiteTurbineDynamics.jl/scratch/coax_011` are removed. The one
  untracked probe (`aw_k_mom_backline.jl`) moved into `scratch/`.
  The KTD symlink `scratch/CoaxialAutogyroStacking.jl` goes too.

## The branch state (needs one ruling)

`sky-anchor-boundary` holds the Phase 13 and 13b code (sky anchor node,
n_b = 3 re-base, 504 tests). Master holds the D6 and D7 decisions that
document that design, and 423 tests. Master does not carry the code.

The recommended path: rebase the two branch commits onto master and
fast-forward, or squash them into one Phase 13 commit on master. The
laptop seat wrote the D6/D7 staging, so the ruling is theirs.

## What the validator still owes

- Sign CA-001 to CA-009 and expand the register. The currency check
  counts 118 number-shaped claims across README, SPEC and the academic
  report against nine rows.
- The sky-anchor merge brings the suite to 504. The merged master
  should run green before any campaign cites it.
