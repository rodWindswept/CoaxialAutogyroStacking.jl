# Numbers register — CoaxialAutogyroStacking.jl

**Status** SCAFFOLD. **Opened** 2026-10-23 (desktop seat). **Owner**
science-validator.

This file is the single source of truth for every number the project
states outside the code. A number appears in a report, a brief, a
figure or a post only after its row here signs.

## The discipline

- One row per number. A row holds the value at full precision, the
  units, the source (file, commit, table or line), the derivation, and
  the signing validator with the date.
- A signed row is amend-only. Fix a mistake with a dated correction
  block below the row, never by editing the signed value.
- The science-validator reproduces every value from the source before
  signing. Nobody signs their own derivation.
- A cited number with no signed row is a release blocker.

## Row format

| ID | Value (full precision) | Units | Source | Derivation | Signed |
|---|---|---|---|---|---|

## Candidate rows (unsigned until a validator reproduces them)

| ID | Value | Units | Source | Derivation | Signed |
|---|---|---|---|---|---|
| CA-001 | 5065 | N | `README.md` line 41 | anchor tension, PCA-2 v1 disk model, 8 m/s | no |
| CA-002 | 649 | N | `README.md` line 41 | anchor tension, BEM v2.1 plus polygon line, 8 m/s | no |
| CA-003 | 84 | RPM | `README.md` line 43 | autorotation speed, NACA 0012 | no |
| CA-004 | 3.0 | m | `README.md` line 71 | rotor radius of the reference design | no |
| CA-005 | 0.098 | dimensionless | `CONTEXT.md`, CHANGELOG | PCA-2 solidity, n_blades × chord / (π × R) | no |
| CA-006 | 0.032 | dimensionless | CHANGELOG | reference design solidity | no |
| CA-007 | 5×10^4 | dimensionless | `CONTEXT.md` viability gate | minimum blade Reynolds number, NACA 0012 transitional | no |
| CA-008 | 120 | m/s | `CONTEXT.md` viability gate | maximum blade tip speed, Mach 0.3 noise limit | no |
| CA-009 | 8× | dimensionless | `README.md` line 45 | the v1 to v2 anchor-tension gap, stated as a fundamental limit | no |

The scaffold copies values from committed documents. It verifies
nothing. Every row waits for the validator.
