# Repository Standards Playbook

A record of the scaffolding we added to **CoaxialAutogyroStacking.jl**, written so
the same standards can be ported to another codebase. Each item lists *what* it
is, *why* it matters, and *how to port it* — with Julia-specific pieces flagged
so you can swap in equivalents for a non-Julia repo.

---

## Starting state

The package was already well-initiated for day one: a complete dependency
manifest with version bounds, strict test-first development, one test file per
module, per-phase commits on a green default branch, and a written roadmap. What
was missing was the *connective tissue* — the files that let other people and
agents join the project safely and keep results reproducible. Everything below
fills that gap.

---

## What we added

### 1. Reproducibility & CI

| File | What it does | Why it matters |
|------|--------------|----------------|
| `.gitignore` | Ignores build/coverage/editor cruft; **deliberately keeps the dependency lockfile tracked** | Reproducible installs; a commented line shows how to flip the lockfile policy if the repo is ever published as a library |
| `.github/workflows/CI.yml` | Runs the test suite on every push and PR | First objective green/red signal; stops regressions before merge |

**Why keep the lockfile committed:** for application/research code, exact
dependency reproducibility beats flexibility. (For a *library* destined for a
package registry, the opposite convention usually applies — stop tracking it.)

**Port it:** every ecosystem has a lockfile (`Manifest.toml`, `package-lock.json`,
`poetry.lock`, `Cargo.lock`, `go.sum`) and a CI runner. Keep the same decision —
*track the lockfile for apps, ignore it for libraries* — and wire the CI to run
the project's standard test command on push + PR.

### 2. Documentation

| File | What it does |
|------|--------------|
| `README.md` | Overview, status table, install, quickstart, file map, references, scope |
| `docs/` (Documenter.jl) | A buildable docs site: `make.jl`, `Project.toml`, `src/index.md`, `src/api.md` |
| `.github/workflows/Documentation.yml` | Builds the docs in CI |
| Upgraded docstrings | Every exported symbol got `# Arguments` / `# Returns` / `# Examples` sections |

**Why:** a README is the front door; an auto-generated API site (via an
`@autodocs` block) means new exported functions appear in the docs automatically,
and rich docstrings give other agents inline contracts to code against.

**Port it:** keep the README structure verbatim — it's language-agnostic. Swap
the docs generator for the local idiom (Documenter → Sphinx/MkDocs for Python,
TypeDoc for TS, rustdoc for Rust, godoc for Go). The docstring discipline
(Arguments/Returns/Examples on every public symbol) ports directly.

### 3. Collaboration-readiness

| File | What it does |
|------|--------------|
| `LICENSE` | MIT — sets reuse terms (swap for Apache-2.0 if you need a patent grant, or copyleft) |
| `AGENTS.md` | The working-conventions contract: the TDD loop, "new src file → add include + export" ritual, ordering/unit conventions, definition-of-done, commit style, and the v1 scope guard |
| `CLAUDE.md` | A short pointer to `AGENTS.md` + the roadmap, auto-loaded by Claude tooling |

**Why `AGENTS.md` is the keystone:** it's what keeps multiple humans *and* AI
agents coherent with how the project is actually built, rather than each
reinventing conventions. `AGENTS.md` is the emerging cross-tool standard;
`CLAUDE.md` just points to it so nothing is duplicated.

**Port it:** all three port directly and are language-agnostic. Rewrite the body
of `AGENTS.md` to match the new repo's real loop, test command, file map, and
scope guards — the *structure* (loop → conventions → definition-of-done →
commit style → scope guard) is the reusable part.

### 4. Research provenance

| File | What it does |
|------|--------------|
| `CITATION.cff` | Machine-readable citation metadata + the upstream data source (NASA TM) |
| `CHANGELOG.md` | Keep-a-Changelog format; history backfilled, with an `[Unreleased]` section |

**Why:** academic credibility and a clear audit trail of what changed when. A
changelog started while history is short stays cheap to maintain.

**Port it:** `CITATION.cff` and `CHANGELOG.md` are fully generic standards (GitHub
renders both natively). Reuse as-is; just update the metadata and source
references.

---

## Porting checklist (generic, ordered cheapest-first)

1. `.gitignore` — start from the ecosystem template; decide the lockfile policy (app = track, library = ignore).
2. `LICENSE` — pick once per repo; MIT is a safe default.
3. `README.md` — overview, status, install, quickstart, layout, references.
4. `AGENTS.md` + `CLAUDE.md` — codify the real working loop and conventions.
5. CI workflow — run the test suite on push + PR.
6. `CHANGELOG.md` — start now, backfill briefly.
7. `CITATION.cff` — if the work has research/data provenance.
8. Docs site + docstring upgrades — the biggest lift; do once the above are in.

---

## Decisions to revisit per repo

These were left open here and should be made deliberately in any new codebase:

- **Library vs application** — drives the lockfile policy and whether you add
  registry automation (CompatHelper/TagBot for Julia, Dependabot + release
  tooling elsewhere). We deferred registry publication pending external review.
- **License choice** — MIT vs Apache-2.0 (patent grant) vs copyleft.
- **Docs deployment target** — placeholders (`OWNER`, canonical URL,
  `deploydocs`) need a real Git remote before docs can publish.
- **Self-testing examples** — the docstring examples here are rendered but not
  executed; promoting them to executable doctests turns the docs into a second
  test suite (a per-ecosystem decision).

---

## What ports cleanly vs. what's Julia-specific

**Language-agnostic (reuse the file or its structure directly):** `.gitignore`
policy, `LICENSE`, `README.md`, `AGENTS.md`, `CLAUDE.md`, `CHANGELOG.md`,
`CITATION.cff`, the CI-on-push/PR pattern, and the docstring discipline.

**Julia-specific (swap for the local equivalent):** `Manifest.toml`/`Project.toml`
handling, `.JuliaFormatter.toml` (→ Prettier/Black/rustfmt/gofmt), Documenter.jl
(→ Sphinx/MkDocs/TypeDoc/rustdoc/godoc), and the `julia-actions/*` CI steps
(→ the ecosystem's setup + test actions).
