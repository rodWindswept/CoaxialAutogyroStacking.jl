# Resolution: Ticket 04 — Build shared vocabulary glossary

## Finding

Four critical ambiguous terms resolved via HITL grilling. Six new glossary
entries added to CONTEXT.md. The glossary now has 31 terms.

## Terms resolved

1. **Tension** — scalar force in the line at a point. Not "force" or "load."
2. **Along-line force** — what a rotor contributes to tension below it.
   Distinct from tension. "The rotor adds along-line force; the line
   carries tension."
3. **Anchor** — the structural ground attachment point. Not the same as
   ground station.
4. **Ground station** — the complete ground assembly (winch + structure
   + anchor + electronics).
5. **Rotor ordering** — R1 = topmost, RN = nearest anchor. Codified.
   Never label the other way.
6. **PCA-2 vs PCA** — PCA-2 = Pitcairn rotor. PCA = Principal Component
   Analysis. Never use bare "PCA" when PCA-2 could be meant.

## Staleness noted (not fixed in this ticket)

CONTEXT.md still references PCA-2 as the primary model. BEM v2.1 terms
(stall delay, polygon line, viability gates) are missing. These are
deferred to the Wave 3 src/ sweep.
