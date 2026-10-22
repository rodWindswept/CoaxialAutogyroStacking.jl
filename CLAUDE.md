# CLAUDE.md

Read [`AGENTS.md`](AGENTS.md) for all conventions. Read [`PLAN.md`](PLAN.md) for the
implementation roadmap and scope.

## Quick start

Run the test suite before committing:
```
julia --project=. test/runtests.jl
```

Use strict TDD. Write the failing test first. Implement the minimum to pass.
Then refactor.

## Conventions

All conventions live in [`AGENTS.md`](AGENTS.md). Key points:

- Mirror KiteTurbineDynamics.jl naming, dispatch, and unit conventions.
- Use SI units. Angles are in degrees at the API boundary.
- Rotors in a stack are ordered top to bottom. Index 1 is the topmost.
- Scope limit: no wake interaction. This is a single-rotor BEM model.

## Writing discipline

Follow the clarity rules in [`AGENTS.md`](AGENTS.md) for all captions, specs,
implications, and code comments. Use active voice. Use short sentences.
Use one name per thing. Do not hedge.

Lint diagram captions with `python3 ste-lint.py <file>` before Round 2 approval.
The score must be below 2.0 violations per 100 words.

## Agent reference docs

| File | Purpose |
|------|---------|
| [`docs/agents/domain.md`](docs/agents/domain.md) | Quick start, repo map, physics summary |
| [`SOURCE_INVENTORY.md`](SOURCE_INVENTORY.md) | Every file with a one-line purpose |
| [`docs/agents/issue-tracker.md`](docs/agents/issue-tracker.md) | How to create and manage issues |
| [`docs/agents/triage-labels.md`](docs/agents/triage-labels.md) | Standard triage label set |

## Agent skills

Read by `to-tickets`, `triage`, `to-spec`, `wayfinder`, and `qa`.

### Issue tracker

GitHub Issues on `rodWindswept/CoaxialAutogyroStacking.jl`, driven by the `gh` CLI. Covers issue create/read/list/label/close, the PRs-as-triage-surface flag (currently off), and the `wayfinder` map-and-child-ticket operations used by [`docs/agents/wayfinder-ste-sweep-map.md`](docs/agents/wayfinder-ste-sweep-map.md) and [`docs/agents/wayfinder-tickets/`](docs/agents/wayfinder-tickets). See [`docs/agents/issue-tracker.md`](docs/agents/issue-tracker.md).

### Triage labels

The five canonical roles, each label string equal to its name: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See [`docs/agents/triage-labels.md`](docs/agents/triage-labels.md).

### Domain docs

Single-context. `CONTEXT.md` at the repo root holds domain vocabulary and architecture; there is no `docs/adr/` yet — `/domain-modeling` creates ADRs lazily when decisions actually get resolved. Agent onboarding — repo map, physics summary, quick start — is in [`docs/agents/domain.md`](docs/agents/domain.md).
