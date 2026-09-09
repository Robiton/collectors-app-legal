# Release Security and Review Gate

This project requires a full code review and security/dependency check before any
PR is merged or release package is promoted.

No PR may merge until a human code review is complete and applicable dependency,
secret, vulnerability, static-analysis, and package/release checks are run or
explicitly documented as unavailable with fallback validation.

Critical and high findings must be fixed before merge unless the project owner
explicitly accepts and documents the risk.

---

## Required before opening a PR

- [ ] Unrelated local changes excluded from the branch
- [ ] AI scaffold files (`ai/SESSION.md`, `ai/BACKLOG.md`, `ai/MEMORY.md`) updated
- [ ] Syntax checks passed
- [ ] Dependency inventory completed (see below)
- [ ] Outdated package check run when dependency manifests exist
- [ ] Vulnerability scan run when dependency manifests exist
- [ ] Secret scan run, or limitation documented with fallback check
- [ ] Static/security analysis run where applicable
- [ ] Build/package validation run for deployable artifacts
- [ ] Package contents inspected — no secrets, local overrides, caches, or nested packages

## Required before merging

- [ ] Human code review completed — AI-assisted review may help but does not replace it
- [ ] Critical/high findings fixed or explicitly risk-accepted and documented by project owner
- [ ] PR description documents: validation performed, scan results, residual risk, deployment notes
- [ ] **Does this change AGENT BEHAVIOUR?** If the PR touches `AGENTS.md`, `ai/STANDARDS.md`,
      `ai/CODING.md`, `ai/SECURITY.md` or `ai/PLANNING.md`, say so in the PR and lead the
      release notes with it — see below

---

## Agent-behaviour changes are upgrade-impacting, and they are the quiet kind

Those five files are **merged into every adopter on upgrade** and **loaded into every agent
session**. A rule added to one of them changes what adopters' agents *do*, immediately, in
every project that upgrades.

**This class has no failing build.** Every other upgrade-impacting change announces itself as
a red check with a name you can search. This one announces itself as an engineer being told
"no" mid-task, with no error, no exit code, and no way to tell policy from bug from a model
having a bad day.

Measured (#118): `0.5.4.20260805.0400` merged an agent threat model into `ai/SECURITY.md`,
including *"No secrets in prompts or agent memory."* A maintainer who had been committing HEC
tokens for **months** was refused by his own agent the next time he tried. The release notes
led with tooling. His upgrade output said `ai/SECURITY.md  clean (+79 upstream lines)`.

So:

- **Lead the release notes with it**, in the same place a breaking change would go. "Your
  agents will now refuse X" is more disruptive than most API breaks, because there is nothing
  to grep for.
- **Say what an adopter should expect to be refused**, not just which file changed.
- `scaffold_upgrade.sh` now names the arriving sections at upgrade time. That is a backstop
  for someone who missed the notes — it is not a substitute for writing them.

---

## What CI already ran, and what it did not

Do not repeat these by hand; do not assume they cover more than they do.

| check | covers | does NOT cover |
|---|---|---|
| `tools/secret_scan.sh` | an obvious committed credential in the tracked tree | history, entropy, anything gitleaks would find |
| `tools/conflict_scan.sh` | unresolved merge markers | a merge that resolved *wrongly* — that is review |
| `tools/header_check.sh` | headers and build stamps | whether the changelog is true |
| ruff (pinned set) | the scaffold's own Python | your project's Python, deliberately |

The dependency, vulnerability and licence work below is **not** in CI and is the reason
this gate exists.

---

## Dependency inventory

Detect and document which manifests are present:

| Ecosystem | Manifests to check |
|-----------|-------------------|
| Python    | `requirements.txt`, `pyproject.toml`, `poetry.lock`, `Pipfile` |
| Node      | `package.json`, `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock` |
| Go        | `go.mod`, `go.sum` |
| Rust      | `Cargo.toml`, `Cargo.lock` |

If no dependency manifests exist, document explicitly:
> No app-bundled third-party dependencies detected.

---

## Secret scan

**Preferred:**
```bash
gitleaks detect --source . --redact
```

**Alternative:**
```bash
trufflehog filesystem . --only-verified
```

**Fallback when neither is available — use the one this scaffold ships:**
```bash
tools/secret_scan.sh
```
It is the same heuristic as the raw `rg` line this used to recommend, but tuned against
real false positives and with a sanctioned way to clear a reviewed line
(`# scaffold:not-a-secret`, or an existing `# nosec`) rather than nothing. A raw grep with
no exception mechanism gets run once, produces a wall of framework boilerplate, and is
never run again. It is **not** a substitute for gitleaks: it catches an obvious paste and
says so.

Document which tool was used and any limitations. Note: AI-assisted code generation
carries a 2× higher secret-leakage rate than baseline — always scan AI-generated files.

---

## Outdated package checks

**Python:**
```bash
python -m pip list --outdated
# or if using Poetry:
poetry show --outdated
```

**Node:**
```bash
npm outdated
# or pnpm/yarn equivalents:
pnpm outdated
yarn outdated
```

---

## Vulnerability scan

**Python:**
```bash
pip-audit -r requirements.txt
# or:
safety check -r requirements.txt
```

**Node:**
```bash
npm audit
# or pnpm/yarn equivalents:
pnpm audit
yarn npm audit
```

Document unavailable tools and the fallback validation performed.

---

## Static and security analysis

**Python:**
```bash
bandit -r .
semgrep scan --config auto
```

**JavaScript/TypeScript:**
```bash
# Run project linter and type checks
semgrep scan --config auto
```

Use project-appropriate linters, type checks, and framework-specific security checks.
Document any findings and disposition (fixed, accepted, deferred).

---

## Package inspection

For deployable artifacts (tar.gz, .spl, wheel, zip, etc.):

1. Extract or list the archive contents
2. Confirm the package contains what it should and nothing more
3. Verify exclusions: no secrets, no `local/`, no `ai/`, no `.DS_Store`, no
   AppleDouble metadata (`._*`), no `PaxHeaders`, no build scripts, no nested
   packages, no `passwords.conf`

See project-type overlay standards for ecosystem-specific packaging requirements.

---

## Residual risk

Document any known limitation, accepted risk, unavailable scanner, or deferred finding:

| Finding | Severity | Disposition | Owner | Date |
|---------|----------|-------------|-------|------|
| | | | | |

If all scans passed with no findings, document:
> All applicable scans completed. No findings.
