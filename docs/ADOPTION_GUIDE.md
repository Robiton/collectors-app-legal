# Adoption Guide — Adding the Scaffold to Existing Projects

_How to add the AI Project Scaffold to a repo that already exists,
and how to keep it updated when the scaffold evolves._

---

## Overview

There are two ways to use this scaffold:

1. **New project** — clone the scaffold, run `setup.sh`, start building.
   This is covered in the README and CONTRIBUTING.md.

2. **Existing project** — copy the scaffold files into a repo that already
   has code, history, and maybe its own conventions. This guide covers that.

The process takes about 15 minutes. Most of it is filling in your project's
context in the `ai/` files — the file copying itself is fast.

---

## AI-driven setup (hands-off)

> 🤖 **If you are an agent, [`AGENT_RUNBOOK.md`](https://github.com/Robiton/ai-project-scaffold/blob/main/docs/AGENT_RUNBOOK.md) is the shorter path.**
> Absolute on purpose: this file ships to adopters and the runbook does not.
> This guide is 1,051 lines and carries the reasoning; the runbook carries the work, and
> following it literally produces a correct adoption. Come back here when you need to know
> WHY a step exists.

Both paths can be delegated to an AI agent — `setup.sh` has non-interactive flags,
and `--check` verifies the result so the agent can prove the setup instead of
asserting it:

```bash
# New project (agent runs this instead of answering prompts)
./setup.sh --type splunk-app --name TA-vendor-product --owner "Your Name" \
           --splunk-existing            # or --splunk-new for a fresh app

# Any project type: base, ai-skill, splunk-app, security-tool,
#                   python-script, it-automation, api-integration
./setup.sh --type base --name my-project --owner "Your Name"

# Verify — exit 0 means correct; [FAIL] lines include the fix
./setup.sh --check
```

Setup also runs the verification automatically at the end and exits non-zero on
failure. When asking an agent to adopt the scaffold, tell it: *"run setup.sh
non-interactively, then run `./setup.sh --check` and report its output"* — the
check output is the evidence the setup is right, per `ai/PLANNING.md` → *How to verify*.

---

## Nested AGENTS.md for multi-component repos

If one repo holds many components (e.g. dozens of Splunk apps), the root AGENTS.md
can't tell an agent which app's build to run. Give each component a **small**
AGENTS.md with its commands and facts — AI tools resolve the nearest file, and it
adds to (never replaces) the root. Full rule: `ai/STANDARDS.md` → *Nested AGENTS.md*.

```
repo-root/
├── AGENTS.md              ← repo-wide: load ai/STANDARDS.md, versioning, hooks
├── ai/                    ← standards live here, and only here
├── TA-vendor-product/
│   └── AGENTS.md          ← this app's commands + facts (example below)
└── SA-framework-function/
    └── AGENTS.md
```

Example `TA-vendor-product/AGENTS.md` — commands and facts only, no standards:

```markdown
# TA-vendor-product — agent context

| Action | Command (run from this directory) |
|--------|-----------------------------------|
| Package | `./build.sh` — never hand-tar |
| Validate package | AppInspect: `splunk-appinspect inspect <artifact> --included-tags self-service` |
| Py syntax check | `python3 -m py_compile bin/*.py` |

Facts:
- Version lives in: `default/app.conf` ([launcher] version + [install] build), `version`, conf headers, git tag, artifact name
- Deploy target: Heavy Forwarder (data collection TA)
- Gotcha: inputs.conf intervals are staggered deliberately — do not normalize them
```

Rules of thumb: ~5–15 lines; update it in the same PR that changes the component's
commands; if you're about to write a *standard* in one, stop — that belongs in `ai/`.

---

## What you're adding

The scaffold adds these to your existing repo:

| What | Files | Purpose |
|------|-------|---------|
| Hook files | `AGENTS.md`, `.cursorrules`, `.windsurfrules`, `.codex` | Tell AI tools to load standards on startup |
| Base standards | `ai/STANDARDS.md`, `ai/CODING.md`, `ai/SECURITY.md`, `ai/PLANNING.md` | Rules every tool follows |
| Living context | `ai/SESSION.md`, `ai/BACKLOG.md`, `ai/MEMORY.md`, `ai/TEAM.md` | Context that persists across sessions |
| Support files | `sync-check.sh`, `.editorconfig`, `.gitattributes`, `version`, `LICENSE` | Multi-machine sync, formatting, union-merge for the append-logs, versioning |
| GitHub config | `.github/CONTRIBUTING.md`, `.github/PULL_REQUEST_TEMPLATE.md`, `.github/CODEOWNERS`, `.github/copilot-instructions.md`, `.github/workflows/scaffold-check.yml` | Onboarding, PR process, CI |

None of this overwrites your existing code. The `ai/` folder and hook files
are additive. If you already have a `.github/` folder, the scaffold files
merge into it.

---

## Step-by-step: Add scaffold to an existing project

### Prerequisites

- Your project is in a Git repo
- You have push access
- You know your default branch name (`main` or `master`)

### 1. Clone the scaffold to a temp location

```bash
SCAFFOLD_DIR="/tmp/ai-project-scaffold"
rm -rf "$SCAFFOLD_DIR"
git clone https://github.com/Robiton/ai-project-scaffold.git "$SCAFFOLD_DIR"
```

### 2. Create a branch in your project

```bash
cd /path/to/your-project
git checkout main                  # or master — use your default branch
git pull origin main
git checkout -b chore/add-scaffold
```

### 3. Copy the scaffold files

> **`setup.sh` is part of an adoption, not just the thing that creates one.** It is the
> declared reader for the `scaffold:no-artifact` marker, so `tools/marker_scan.sh` fails
> without it — and `--check` and `--upgrade` are both run *from your project*, not from the
> scaffold. This list omitted it until 2026-08-31, when an adoption built by following the
> list exactly failed its own first preflight.

> **STOP if `ai/` already exists in your project.** `cp -r` overwrites, and `ai/MEMORY.md`,
> `ai/BACKLOG.md` and `ai/SESSION.md` are the least replaceable files a project has. On one
> real repository they held 44 KB of history that this line would have replaced with empty
> templates. If you already have an `ai/` directory you have a STALE ADOPTION, not a fresh
> one — see "Catching up a stale adoption" below, and do not run this block.

```bash
# Core standards folder — see the warning above if ai/ already exists
cp -r "$SCAFFOLD_DIR/ai" .

# STRIP THE SCAFFOLD'S OWN DECLARATIONS. Two markers in those files describe THIS
# repository's arrangements, not yours, and both break your first preflight if they travel:
#   scaffold:session-log  names ../ai-project-scaffold-dev/ai/SESSION.md, which you do not
#                         have. tools/session_currency.sh HARD-FAILS (exit 4) on it.
#   scaffold:must-run     names a test suite that exists only in the source repo.
# `./setup.sh --type` strips both automatically; this manual path is the one that did not,
# and it is the only documented route for adopting into EXISTING code.
grep -v 'scaffold:session-log' ai/BACKLOG.md > ai/BACKLOG.tmp && mv ai/BACKLOG.tmp ai/BACKLOG.md
grep -v 'scaffold:must-run'    ai/BACKLOG.md > ai/BACKLOG.tmp && mv ai/BACKLOG.tmp ai/BACKLOG.md

# Hook files — all AI tools
cp "$SCAFFOLD_DIR/AGENTS.md" .
cp "$SCAFFOLD_DIR/.cursorrules" .
cp "$SCAFFOLD_DIR/.windsurfrules" .
cp "$SCAFFOLD_DIR/.codex" .
mkdir -p .cursor/rules
cp "$SCAFFOLD_DIR/.cursor/rules/base.mdc" .cursor/rules/   # Cursor reads this, not .cursorrules

# Support files
cp "$SCAFFOLD_DIR/.editorconfig" .
# gitleaks allowlist. WITHOUT THIS, gitleaks reports 12 findings in the tools/secret_scan.sh
# you just copied — synthetic fixtures its own selftest needs in order to prove it detects
# secrets. A gate that is red on arrival trains people to scroll past it.
cp "$SCAFFOLD_DIR/.gitleaks.toml" .
cp "$SCAFFOLD_DIR/.gitattributes" .
cp "$SCAFFOLD_DIR/sync-check.sh" .
# LICENSE — A DECISION, NOT A FILE. This is the scaffold's MIT licence. Copying it into an
# internal or proprietary project makes a licensing statement on that project's behalf, and
# most adoptions inside a company are exactly that. Copy it if your project is open source;
# skip this line if it is not, and nothing downstream depends on it either way.
cp "$SCAFFOLD_DIR/LICENSE" .          # ← skip for a proprietary/internal project
cp "$SCAFFOLD_DIR/setup.sh" .
# The Windows counterpart of the copy path. It is PowerShell, so it does not need chmod and
# it does no harm on a Unix adoption — it ships so a Windows machine has a native entry
# point at all. It COPIES ONLY: the gates are bash and still need WSL or Git Bash.
cp "$SCAFFOLD_DIR/adopt.ps1" .
chmod +x sync-check.sh setup.sh

# GitHub config (creates .github/ if it doesn't exist)
mkdir -p .github/workflows
cp "$SCAFFOLD_DIR/.github/CONTRIBUTING.md" .github/
cp "$SCAFFOLD_DIR/.github/PULL_REQUEST_TEMPLATE.md" .github/
cp "$SCAFFOLD_DIR/.github/CODEOWNERS" .github/
cp "$SCAFFOLD_DIR/.github/copilot-instructions.md" .github/
cp "$SCAFFOLD_DIR/.github/workflows/scaffold-check.yml" .github/workflows/

# The staleness marker. Without it nothing in your repo will ever say "the scaffold
# moved on" — see step 4 of "Updating an existing adoption" below for why that matters.
cp "$SCAFFOLD_DIR/.scaffold-version" .
# NOTE: `version` is deliberately NOT copied — that file is YOUR project's version.

# Git hooks. These SHIP but are NOT ACTIVATED — `.git/hooks` is not versioned and does not
# come with a clone, so a hook nobody can receive is a rule enforced on whoever happened to
# install it. `./setup.sh --install-hooks` turns them on, per machine, by hand.
#
# Absent from this list until 2026-09-03: they were on the upgrade's delivery list and not
# on this one, so a FRESH adoption never received them and an upgraded one did. Found by an
# outside reviewer, who reasonably filed it as an incomplete adoption. It was a complete
# adoption; the list was incomplete. `tools/adoption_manifest.sh --check` now compares the
# two, and fails if they drift again.
mkdir -p .githooks
cp "$SCAFFOLD_DIR/.githooks/pre-push" .githooks/
cp "$SCAFFOLD_DIR/.githooks/post-checkout" .githooks/
cp "$SCAFFOLD_DIR/.githooks/post-commit" .githooks/
cp "$SCAFFOLD_DIR/.githooks/post-merge" .githooks/
chmod +x .githooks/*

# Tooling + Claude Code hooks (optional, but this is what makes the rules enforceable
# rather than merely stated). localcoder is NOT in here -- it is a separate product now
# (W-15); `uv tool install localcoder` if you want it, and keep
# ai/localcoder.config.json either way, since that file is what declares the intent.
cp -r "$SCAFFOLD_DIR/tools" .

# The scaffold's own documentation. THE MANIFEST HAS ALWAYS DECLARED docs/ AND NOTHING EVER
# COPIED IT -- measured 2026-09-09 across three real adoptions, none of which had a docs/
# directory at all. That is why `tools/README.md` linked to a TROUBLESHOOTING.md no adopter
# had, and why `docs/AGENT_RUNBOOK.md` -- written so an AGENT in an adoption could follow it
# -- reached no adoption.
#
# Skip it only if you genuinely do not want the scaffold's docs in your tree; nothing else
# depends on it being there, and the links that used to assume it are absolute now.
cp -r "$SCAFFOLD_DIR/docs" .

mkdir -p .claude
# READ THIS BEFORE YOU COMMIT IT. `.claude/settings.json` wires SIX auto-running hooks that
# fire with no review gate on any machine that opens this project in Claude Code:
#
#     SessionStart  sync-check.sh                     is the vendored scaffold stale?
#     SessionStart  tools/session_hook.sh start       opens a session record
#     SessionStart  a context injection on compact    re-states the checkpoint rule
#     Stop          tools/session_hook.sh checkpoint  writes ai/SESSION_JOURNAL.md
#     SessionEnd    tools/session_hook.sh end         closes the session record
#     PreCompact    tools/session_hook.sh precompact  (manual and auto)
#
# All of it is local: it reads the repo and writes to `ai/`. Nothing phones anywhere. But it
# is automatic execution in a repository that may also hold production configuration, and
# that is a decision your security people get to make rather than inherit. This is why the
# companion guard ships as `.claude/settings.pretooluse-guard.example.json` — inert until
# renamed. The hooks are the enforcement layer; without them the standards are stated and
# not checked. Take them knowing what they are, or leave this line out.
cp "$SCAFFOLD_DIR/.claude/settings.json" .claude/
cp "$SCAFFOLD_DIR/.claude/settings.hooks.json" .claude/   # the canonical set --check compares against
cp -r "$SCAFFOLD_DIR/.agents" . && cp -r "$SCAFFOLD_DIR/.agents/skills" .claude/
chmod +x tools/*.sh tools/*.py

# CLAUDE.md pointer for Claude Code — one-line import of AGENTS.md (commit it)
# REMOVE A LEGACY SYMLINK FIRST OR THIS DESTROYS AGENTS.md.
# Scaffold <=v0.3.0 shipped an AGENTS.md telling adopters to `ln -s AGENTS.md CLAUDE.md`.
# `>` FOLLOWS a symlink, so on any such adoption this line truncates AGENTS.md to the
# eleven bytes "@AGENTS.md" and leaves CLAUDE.md pointing at the wreckage. Reproduced:
# an 86-byte AGENTS.md became 11. setup.sh has always got this right; both MANUAL paths
# in this guide did not. Found on a real stale adoption, 2026-09-04.
[ -L CLAUDE.md ] && rm CLAUDE.md
printf '@AGENTS.md\n' > CLAUDE.md
```

**Copy `tools/` or the CI workflow will fail on you.** `scaffold-check.yml` calls
`tools/header_check.sh`, `tools/session_archive.py` and `tools/adoption_check.sh`, and
`.claude/settings.json` wires `tools/session_journal.sh` to `SessionStart`. Each degrades
to a warning when its script is absent rather than erroring — but a warning is what you
get *instead of* the check, which is the whole thing you came here for.

### 4. Update your .gitignore

> **`CLAUDE.md` is COMMITTED — do not ignore it.** This block used to list it, which was
> correct only while `CLAUDE.md` was a generated symlink. It is now a one-line
> `@AGENTS.md` import that every teammate needs on a fresh clone, and this guide's own
> final checklist already fails you for ignoring it. If your `.gitignore` still carries a
> `CLAUDE.md` line from an earlier adoption, `./setup.sh` removes it and leaves
> `.gitignore.scaffold-backup` behind.

Add these lines if they're not already present:

```bash
# Append scaffold gitignore entries
cat >> .gitignore << 'EOF'

# AI Project Scaffold — tool caches, never the ai/ files or CLAUDE.md
.cursor/cache/
.cursor/logs/
.claude/cache/
.claude/logs/
.agents/cache/
.agents/runtime/
.agents/*.db

# Per-developer working state written by the scaffold's own tools
ai/SESSION_JOURNAL.md
.session-journal-state
.scaffold-version-check
.localcoder-log.jsonl
*.scaffold-backup
ai/.scaffold-run-log
EOF
```

That last group is not optional bookkeeping. `ai/SESSION_JOURNAL.md` records itself on
every turn if it is tracked, so a tracked journal leaves the tree permanently dirty; and
`.localcoder-log.jsonl` is appended on every `localcoder` call with the first 200
characters of each task, so an untracked one is a dirty tree and a tracked one publishes
your prompts.

### 5. Create the version file

```bash
echo "0.1.0.$(date +%Y%m%d.%H%M)" > version
```

If your project already has a version number, use that as the
MAJOR.MINOR.PATCH portion instead of `0.1.0`.

### 6. Apply an overlay (if your project type has one)

> **`./setup.sh --type <overlay>` will NOT work here, and this is the only route.** That
> command refuses unless `overlays/` and the scaffold's own `ai/STANDARDS.md` are in the
> current directory, and a successful run *deletes* `overlays/` — so it is single-shot per
> clone and cannot add or redo an overlay on a project that is already adopted. For existing
> code, the manual steps below are the supported path. Verified by acceptance test on two
> real projects.

Three things have to happen, and for a long time this section only listed the first one.
An overlay that appends its text but writes no marker leaves `./setup.sh --check` reporting
`[!] no overlay applied` forever, on a project that genuinely has one.

Substitute your overlay name for `<type>` — one of `splunk-app`, `python-script`,
`security-tool`, `it-automation`, `api-integration`, `ai-skill`:

```bash
TYPE=<type>   # e.g. TYPE=python-script

# 1. Append the overlay's standards and coding rules.
printf '\n---\n' >> ai/STANDARDS.md
cat "$SCAFFOLD_DIR/overlays/$TYPE/STANDARDS.md" >> ai/STANDARDS.md
printf '\n---\n' >> ai/CODING.md
cat "$SCAFFOLD_DIR/overlays/$TYPE/CODING.md" >> ai/CODING.md

# 2. WRITE THE MARKER. `setup.sh --check` greps for `^# Overlay: ` to know an overlay was
#    applied; without it you get "[!] no overlay applied (base scaffold only)" permanently.
#    scaffold_upgrade.sh also uses it to detach your overlay appendix before merging and
#    reattach it after — so without the marker, every future upgrade conflicts on the
#    appendix instead of leaving it alone.
printf '# Overlay: %s\n' "$TYPE" >> ai/STANDARDS.md
printf '# Overlay: %s\n' "$TYPE" >> ai/CODING.md

# 3. COPY THE OVERLAY'S REFERENCE. The CODING.md text you just appended tells the reader to
#    "see ai/REFERENCE.md" — a file that does not exist unless you copy it.
cp "$SCAFFOLD_DIR/overlays/$TYPE/REFERENCE.md" ai/REFERENCE.md
```

Confirm it took:

```bash
./setup.sh --check | grep -i overlay      # expect: [OK] overlay applied: <type>
```

### 7. Fill in your project context

This is the most important step. The templates have placeholders — replace
them with your actual project information.

**`ai/MEMORY.md`** — Your project's institutional knowledge:
- What the project does and who uses it
- Architecture decisions already made
- Known gotchas and issues
- External dependencies and integrations

**`ai/TEAM.md`** — Who works on this project:
- Team member names, roles, tools, GitHub handles
- Who owns what area
- Working agreements

**`ai/BACKLOG.md`** — Current tasks:
- What's in progress right now
- What's coming up next
- What's in the backlog

**`ai/SESSION.md`** — Seed the first entry:

```markdown
## [TODAY'S DATE] — [Your Name] — [Tool used]

**Who worked on this:** [Your Name]

**What we worked on:**
Added AI project scaffold to existing repo. Standards loaded.

**Decisions made:**
- Project type: [type / overlay chosen]
- Initial version set to: [version from step 5]

**Next steps:**
- Begin first AI-assisted work session using scaffold
- Verify all tools load standards correctly
```

### 8. Update CODEOWNERS

Edit `.github/CODEOWNERS` to use your GitHub handle instead of @Robiton:

```bash
# Replace @Robiton with your handle
sed -i 's/@Robiton/@YOUR_HANDLE/g' .github/CODEOWNERS
```

### 9. Commit and push

```bash
git add -A
git commit -m "chore(scaffold): add AI project scaffold v0.2.0"
git push origin chore/add-scaffold
```

Open a Pull Request on GitHub. After review, merge it.

### 10. Clean up and verify

```bash
# After merge
git checkout main     # or master
git pull origin main

# Clean up temp scaffold
rm -rf "$SCAFFOLD_DIR"

# Verify
ls ai/
# Should show: BACKLOG.md  CODING.md  localcoder.config.json  MEMORY.md
#              OPERATIONS.md  PLANNING.md  PROVENANCE.md  SECURITY.md
#              SESSION.md  STANDARDS.md  STANDARDS_EVIDENCE.md  TEAM.md
```

## Adopting inside a monorepo

**Read this before step 3 if your project is a directory inside a larger repository** —
`apps/my-app/`, `services/thing/`, anything that is not the repository root.

The rest of this guide assumes the project it adopts into **is** a repository. Three things
break when that is not true, and **none of them reports an error** — they simply do nothing:

| What | Why it is inert in a subdirectory |
|---|---|
| `.github/workflows/scaffold-check.yml` | GitHub discovers workflows only at the repository root. A workflow in `apps/my-app/.github/workflows/` never runs — and reads to any reviewer as though CI is enforcing your standards. |
| `.github/CODEOWNERS`, PR template | Same rule. Root only. |
| Claude Code hooks | `.claude/settings.json` scans one directory level. A project two levels down is invisible from the root, so no hook fires. |
| "AGENTS.md exists in repo root" (final checklist) | Passes in your project directory, where it means something different. |

`./setup.sh --check` now tells you when you are in this situation. It is a notice, not a
refusal: adopting into a monorepo is legitimate and common. It just needs different wiring.

### What stays in the project directory

Everything from step 3 except the `.github/` block: `ai/`, `AGENTS.md`, `CLAUDE.md`,
`tools/`, `.claude/`, `.agents/`, `.githooks/`, `setup.sh`, `sync-check.sh`, the editor
dotfiles and `.scaffold-version`. All of those work from where they are.

### What has to move to the repository root

**1. The workflow.** Put this at `.github/workflows/scaffold-check-apps.yml` **in the
repository root** — not in your project. It runs the vendored gate for whichever project
changed, and only when one did:

```yaml
name: Scaffold Check (apps)

on:
  pull_request:
    paths: ['apps/**']
  push:
    branches: [main, master]
    paths: ['apps/**']
  workflow_dispatch:

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ github.event_name == 'pull_request' }}

permissions:
  contents: read

jobs:
  changed:
    runs-on: ubuntu-latest
    outputs:
      projects: ${{ steps.find.outputs.projects }}
    steps:
      - uses: actions/checkout@v5
        with: { fetch-depth: 0 }
      - id: find
        # Every adopting project under apps/ that this push or PR actually touched.
        # An adoption is identified by ai/STANDARDS.md, the same marker sync-check.sh uses.
        run: |
          base="${{ github.event.pull_request.base.sha || github.event.before }}"
          [ -n "$base" ] && [ "$base" != "0000000000000000000000000000000000000000" ] \
            || base="$(git rev-list --max-parents=0 HEAD | tail -1)"
          dirs="$(git diff --name-only "$base" HEAD -- 'apps/**' \
                  | cut -d/ -f1,2 | sort -u \
                  | while read -r d; do [ -f "$d/ai/STANDARDS.md" ] && echo "$d"; done \
                  | jq -R . | jq -sc .)"
          echo "projects=${dirs:-[]}" >> "$GITHUB_OUTPUT"

  scaffold:
    needs: changed
    if: needs.changed.outputs.projects != '[]'
    strategy:
      fail-fast: false
      matrix:
        project: ${{ fromJSON(needs.changed.outputs.projects) }}
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ${{ matrix.project }}
    steps:
      - uses: actions/checkout@v5
        with: { fetch-depth: 0 }
      # The project vendors its own tools/, so the gate it runs is the one it adopted —
      # not whatever version the root happens to have.
      - run: ./setup.sh --check
      - run: tools/preflight.sh
```

> **`if: needs.changed.outputs.projects != '[]'` is doing real work.** Without it a PR that
> touches nothing under `apps/` produces a job with an empty matrix, which GitHub reports as
> *skipped* — and a required check that is permanently skipped is a check that never fails.
> That is the same silent-absence failure this whole guide exists to prevent.

**2. CODEOWNERS.** One file at the root, with a line per project:

```
/apps/my-app/  @your-team
```

**3. The PR template.** One per repository. Merge your project's requirements into the root
template rather than shipping a second one that nobody sees.

### Then delete what cannot work

Remove `.github/` from your project directory once the root workflow exists. Leaving an
inert copy behind is the actual hazard: it provides zero enforcement while looking exactly
like enforcement, and a reviewer who sees it will reasonably assume the checks are running.

### 11. Start your first AI session

Open your AI tool and paste this as your first message:

> "Read ai/STANDARDS.md and load all files in the order it specifies
> before we begin any work."

That's it. The tool loads everything automatically from there.

---

## Catching up a stale adoption

**Use this when `ai/` already exists but `.scaffold-version` does not.** The guide's other
two modes do not fit and both destroy things here:

- *Fresh adoption* (step 3) begins `cp -r "$SCAFFOLD_DIR/ai" .`, which overwrites the
  memory, backlog and session history the project has been accumulating.
- *`./setup.sh --upgrade`* needs `.scaffold-version` as its merge base. Without one there is
  no honest three-way merge, and the vendored `setup.sh` predates the tools it would run.

An adoption from before `tools/` existed has neither. This was the shape of a real
repository on 2026-09-04 — 44 KB of live `ai/` content, no `tools/`, no `.scaffold-version` —
and every safety property of that catch-up came from someone reasoning it out by hand,
because this section did not exist.

**1. Record what must survive, before touching anything.**

```bash
git checkout -b chore/scaffold-catchup
for f in ai/*.md; do printf '%-28s %s\n' "$f" "$(shasum -a 256 "$f" | cut -c1-16)"; done
```

Those hashes are the acceptance criterion. Any of them changing at the end is a mistake in
the catch-up, not an upgrade.

**2. Take everything from step 3 EXCEPT the `ai/` copy.** `tools/`, `.claude/`, `.agents/`,
`.githooks/`, `.gitleaks.toml`, `.cursor/rules/base.mdc`, `.gitattributes`,
`.scaffold-version`, `setup.sh`, `sync-check.sh`, `.github/`, and the `CLAUDE.md` pointer —
**with the `[ -L CLAUDE.md ] && rm CLAUDE.md` guard, which matters most on exactly this
vintage of adoption.**

**3. Add only the `ai/` files you do not already have.**

```bash
for f in OPERATIONS.md PROVENANCE.md STANDARDS_EVIDENCE.md localcoder.config.json; do
  [ -e "ai/$f" ] || cp "$SCAFFOLD_DIR/ai/$f" "ai/$f"
done
grep -n 'scaffold:session-log' ai/BACKLOG.md   # delete the line if present; it names OUR sibling
```

**4. Decide about `ai/STANDARDS.md` and `ai/CODING.md` with a command, not a feeling.**
They are yours and may hold project rules — or they may be a stale copy of ours with nothing
in them worth keeping. Measure it:

```bash
comm -23 <(sort -u ai/CODING.md) <(sort -u "$SCAFFOLD_DIR/ai/CODING.md") | grep -vc '^$'
```

Zero unique lines means it is a pure stale copy and taking upstream's costs you nothing.
A non-zero count is the list to read before deciding. On the repository this section was
written from, `ai/CODING.md` had **zero** and `ai/STANDARDS.md` had 21 — all of them older
upstream *wording*, not project facts.

**5. Commit BEFORE running the verification.** Freshly vendored `setup.sh` and
`sync-check.sh` carry upstream's build stamps, and `header_check --since` reads those as
hundreds of thousands of minutes "AHEAD of the commit that carries it" while they are
uncommitted. It clears the moment they are committed. Verify after, not before.

```bash
git add -A && git commit -m 'chore(scaffold): catch up to <version>'
./setup.sh --check
tools/preflight.sh
```

**6. Expect real failures on the first run, and one specific remedy.** `header_check` will
flag every pre-existing source file, because the standard applies forward rather than
retroactively. The fix is `tools/header_check.sh --adopt`, which declares today as your
baseline — **and it writes a `scaffold:header-baseline` marker into `ai/STANDARDS.md`**, so
run it after step 1's hashes have served their purpose, not before. It is the one sanctioned
edit to that file.

**7. Re-check the hashes from step 1.** If any of the files you already had have changed,
stop and find out why.

## Headless Linux (SSH-only machines)

Same process as above. If you can't clone the scaffold repo locally,
use `curl` to pull individual files:

```bash
cd /path/to/your-project
git checkout master
git pull origin master
git checkout -b chore/add-scaffold

# THE UPSTREAM REPO IS PRIVATE, so raw.githubusercontent.com returns 404 for everyone.
# `gh` is authenticated and is already required elsewhere in this toolchain.
#
# VERIFY WHAT CAME BACK. The failure mode here is not an error, it is a FILE: `curl -sS -o`
# happily writes a 404 body into the target, which is how a re-fetched upgrade tool became
# a script whose first line was `404:`. Anything that fetches must check.
fetch() {  # fetch <repo-path> <dest>
  mkdir -p "$(dirname "$2")"
  gh api "repos/Robiton/ai-project-scaffold/contents/$1?ref=main" --jq .content \
    | base64 -d > "$2" || { echo "fetch failed: $1" >&2; return 1; }
  [ -s "$2" ] || { echo "fetch produced an empty file: $2" >&2; return 1; }
}

# Create ai/ folder and download all base files
mkdir -p ai
# DISCOVERED, NOT LISTED — same reason as the tools/ loop below. The hand-written list here
# was missing ai/OPERATIONS.md, ai/STANDARDS_EVIDENCE.md and ai/PROVENANCE.md, which joined
# the directory after the list was written and which nothing then re-checked.
# SESSION_JOURNAL.md is skipped deliberately: it is per-developer working state, gitignored.
for f in $(gh api "repos/Robiton/ai-project-scaffold/contents/ai?ref=main" \
             --jq '.[] | select(.type=="file") | .name' | grep -v '^SESSION_JOURNAL.md$'); do
  fetch "ai/$f" "ai/$f"
done

# STRIP THE SCAFFOLD'S OWN DECLARATIONS — the same two markers step 3 strips, for the same
# reason. `scaffold:session-log` names ../ai-project-scaffold-dev/ai/SESSION.md, which you do
# not have, and tools/session_currency.sh HARD-FAILS exit 4 on it. This block is a SECOND
# adoption path and the fix for step 3 did not reach it; that is why preflight now checks
# both paths against the manifest.
grep -v 'scaffold:session-log' ai/BACKLOG.md > ai/BACKLOG.tmp && mv ai/BACKLOG.tmp ai/BACKLOG.md
grep -v 'scaffold:must-run'    ai/BACKLOG.md > ai/BACKLOG.tmp && mv ai/BACKLOG.tmp ai/BACKLOG.md

# Hook files
fetch "AGENTS.md" AGENTS.md
fetch ".cursorrules" .cursorrules
fetch ".windsurfrules" .windsurfrules
fetch ".codex" .codex
fetch ".scaffold-version" .scaffold-version   # which release you are now on

# The scaffold's own docs — the MARKDOWN only. `fetch` decodes base64 from the contents API,
# which is right for text and wrong for the two images and the .docx; those are the parts an
# SSH-only machine least needs, so they are skipped deliberately rather than silently.
# docs/AGENT_RUNBOOK.md is the one that matters here: it is written so an AGENT can set this
# up without reading 1,200 lines of guide, and until 2026-09-09 it reached no adoption at all.
mkdir -p docs
for f in $(gh api "repos/Robiton/ai-project-scaffold/contents/docs?ref=main" \
             --jq '.[] | select(.name | endswith(".md")) | .name'); do
  fetch "docs/$f" "docs/$f"
done
# NOTE: `version` is deliberately absent from this list — it is YOUR project's.
fetch ".editorconfig" .editorconfig
fetch "adopt.ps1" adopt.ps1
fetch ".gitattributes" .gitattributes
fetch "sync-check.sh" sync-check.sh
# setup.sh IS PART OF AN ADOPTION, NOT JUST THE THING THAT CREATES ONE. It is the declared
# reader for the scaffold:no-artifact marker, and `--check` and `--upgrade` both run FROM
# your project. Step 3 learned this on 2026-08-31; this parallel path was never given the
# same line, so a headless adopter had no ./setup.sh and could not run the verification step
# this very section tells them to run next.
fetch "setup.sh" setup.sh
fetch "LICENSE" LICENSE          # skip for a proprietary/internal project
chmod +x sync-check.sh setup.sh

# GitHub config
mkdir -p .github/workflows
fetch ".github/CONTRIBUTING.md" .github/CONTRIBUTING.md
fetch ".github/PULL_REQUEST_TEMPLATE.md" .github/PULL_REQUEST_TEMPLATE.md
fetch ".github/CODEOWNERS" .github/CODEOWNERS
fetch ".github/copilot-instructions.md" .github/copilot-instructions.md
fetch ".github/workflows/scaffold-check.yml" .github/workflows/scaffold-check.yml

# Tooling + Claude Code hooks. The CI workflow above CALLS these; without them each check
# degrades to a warning, and a warning is what you get instead of the check.
```

**Upgrading from 0.11.x or earlier? Fetch this file first.**

```bash
gh api "repos/Robiton/ai-project-scaffold/contents/tools/scaffold_upgrade.sh?ref=main" \
  --jq .content | base64 -d > tools/scaffold_upgrade.sh
```

The upgrade is performed by the copy **vendored in your project**, not by the release you
are moving to. From 0.29.7 the tool hands the run to the newer upgrader in the target
release, so this step stops being necessary — but that hand-over has to already be present
to fire, and copies at or below 0.11.x replace `.gitattributes` wholesale. One project lost
its Git LFS patterns three times that way; the second time it committed 377 glTF buffers as
pointer text, which broke every fresh clone while looking correct on the machine that made
the commit (#125, #179).

```bash
# Drop the localcoder* lines if you do not run a local model.
mkdir -p tools .claude .githooks
# DISCOVERED, NOT LISTED. This was a hand-written list of filenames, and by 0.15.x it was
# missing six tools — including BOTH tree scanners, so an adopter who followed it got a
# tools/ directory whose CI then reported "no tools/*_scan.sh were found". A list of what
# ships is a second definition of the directory, and the directory is the first one.
for f in $(gh api "repos/Robiton/ai-project-scaffold/contents/tools?ref=main" \
             --jq '.[] | select(.type=="file") | .name'); do
  fetch "tools/$f" "tools/$f"
  # A tool that lands non-executable is a tool that silently stops running: every
  # discovery loop filters on [ -x ]. Shebang decides, so nothing has to be listed.
  head -1 "tools/$f" | grep -q '^#!' && chmod +x "tools/$f"
done
fetch "ai/localcoder.config.json" ai/localcoder.config.json
# Cursor reads .cursor/rules/base.mdc, not .cursorrules. Skills are mirrored into
# .claude/skills/ because Claude Code only scans that path.
fetch ".cursor/rules/base.mdc" .cursor/rules/base.mdc
fetch ".agents/skills/verify/SKILL.md" .agents/skills/verify/SKILL.md
mkdir -p .claude/skills && cp -R .agents/skills/. .claude/skills/
fetch ".claude/settings.json" .claude/settings.json
fetch ".claude/settings.hooks.json" .claude/settings.hooks.json
# WITHOUT .gitleaks.toml, gitleaks reports 12 findings in the tools/secret_scan.sh you just
# fetched — synthetic fixtures its own selftest needs. A gate that is red on arrival is one
# people learn to scroll past.
fetch ".gitleaks.toml" .gitleaks.toml
for f in pre-push post-checkout post-commit post-merge; do
  fetch ".githooks/$f" ".githooks/$f"; chmod +x ".githooks/$f"
done
chmod +x tools/*.sh tools/*.py

# CLAUDE.md pointer (committed)
# REMOVE A LEGACY SYMLINK FIRST OR THIS DESTROYS AGENTS.md.
# Scaffold <=v0.3.0 shipped an AGENTS.md telling adopters to `ln -s AGENTS.md CLAUDE.md`.
# `>` FOLLOWS a symlink, so on any such adoption this line truncates AGENTS.md to the
# eleven bytes "@AGENTS.md" and leaves CLAUDE.md pointing at the wreckage. Reproduced:
# an 86-byte AGENTS.md became 11. setup.sh has always got this right; both MANUAL paths
# in this guide did not. Found on a real stale adoption, 2026-09-04.
[ -L CLAUDE.md ] && rm CLAUDE.md
printf '@AGENTS.md\n' > CLAUDE.md

# Version
echo "0.1.0.$(date +%Y%m%d.%H%M)" > version

# Then fill in ai/MEMORY.md, ai/TEAM.md, ai/BACKLOG.md, ai/SESSION.md
# Then commit and push (see steps 7–9 above)
```

To apply an overlay via curl:

```bash
# Example: Splunk app overlay
echo -e "\n---" >> ai/STANDARDS.md
curl -sS "$SCAFFOLD/overlays/splunk-app/STANDARDS.md" >> ai/STANDARDS.md
echo -e "\n---" >> ai/CODING.md
curl -sS "$SCAFFOLD/overlays/splunk-app/CODING.md" >> ai/CODING.md
```

---

## Windows (PowerShell)

Use WSL or Git Bash to run the bash commands above. CLAUDE.md needs no
special handling on Windows — it is a plain committed file (a one-line
`@AGENTS.md` import), not a symlink.

(The old symlink/copy approaches are obsolete — the pointer file imports
AGENTS.md at load time, so it never goes stale.)

---

## Updating the scaffold in a project that already has it

### The short version

```bash
./setup.sh --upgrade --dry-run     # see the plan, change nothing
./setup.sh --upgrade               # do it
```

That is `tools/scaffold_upgrade.sh`. It replaces product-owned files, **three-way merges**
the standards files and `AGENTS.md` against the release named in your `.scaffold-version`,
union-merges `.gitignore`, runs any version-gated migrations, and verifies the result.

**Why a merge and not a copy.** `ai/STANDARDS.md`, `ai/CODING.md` and `AGENTS.md` are
product documents that you legitimately edit — your overlay appendix, your
`scaffold:ceilings` line, your filled-in Project Commands table. That is why they were on
the never-overwrite list, and why nobody could take upstream changes to them at all.
Measured 2026-08-04: **430 lines changed across the four standards files between v0.4.0 and
v0.5.2**, and an adopter following the manual procedure got none of it. Standards froze on
the day you adopted.

`.scaffold-version` is what makes the merge possible — it names the release you are on, so
the file as it shipped *to you* can be used as the merge base. Upstream changes land in
regions you never touched, your edits survive in regions upstream never touched, and the
genuine collisions get conflict markers instead of a guess.

**Safety.** It refuses to run on a dirty working tree, so `git checkout .` is a complete
undo — that is `ai/SECURITY.md`'s hard line applied to your own repo. It never writes
`ai/SESSION.md`, `ai/BACKLOG.md`, `ai/MEMORY.md`, `ai/TEAM.md`, `version`,
`.github/CODEOWNERS` or any `*_ARCHIVE.md`.

### What the upgrade does to each file

This table used to exist only as a comment inside the script, which meant the only way to
find out that a file would be overwritten was to read the tool or lose something. Both
happened: `.gitattributes` was replaced wholesale for four months while adopters kept Git
LFS patterns in it (#125).

| Class | Files | What happens to your edits |
|---|---|---|
| **Never written** | `ai/SESSION.md`, `ai/BACKLOG.md`, `ai/MEMORY.md`, `ai/TEAM.md`, `ai/localcoder.config.json`, `version`, `.github/CODEOWNERS`, `CLAUDE.md`, `*_ARCHIVE.md` | Untouched, always |
| **Three-way merged** | `AGENTS.md`, `ai/STANDARDS.md`, `ai/CODING.md`, `ai/SECURITY.md`, `ai/PLANNING.md` | Kept; upstream lands in regions you did not touch, genuine collisions get conflict markers |
| **Union merged** | `.gitignore`, `.gitattributes` | Kept in full; new upstream entries appended. A line of yours for the same path always wins |
| **Product-owned** | the tool hook files, `.editorconfig`, `.github/` templates and workflow, `setup.sh`, `sync-check.sh` | Replaced **only if identical to the version you were shipped**. If you edited it, yours is kept and the new one is written to `<file>.scaffold-<version>` for you to diff |
| **Force-installed** | `tools/` | Replaced unconditionally — see the warning below |
| **Refreshed** | `docs/` | Only files you already have are updated, and edited ones are kept like product-owned |

**Product-owned no longer means "we assume you did not touch this".** It means the upgrade
checks. The baseline is the release named in your `.scaffold-version`, which is the same
thing that makes the three-way merges possible.

`tools/` is the deliberate exception and is overwritten even if you edited it. That is why
project settings never live there — the archive ceilings are read from a marker in **your**
`ai/STANDARDS.md` for exactly this reason.

If the upgrade command is not in your project yet (it shipped in v0.5.2), fetch it once:

```bash
# The upstream repo is PRIVATE, so raw.githubusercontent.com 404s. gh is authenticated.
gh api "repos/Robiton/ai-project-scaffold/contents/tools/scaffold_upgrade.sh?ref=main" \
  --jq .content | base64 -d > tools/scaffold_upgrade.sh
chmod +x tools/scaffold_upgrade.sh
head -1 tools/scaffold_upgrade.sh | grep -q '^#!' || echo "fetch failed — check the output"
```

The manual procedure below still works and is what `--upgrade` automates. Read it if you
want to know exactly what is being done to your repo, or if you are upgrading a project
that has diverged far enough that you would rather drive it by hand.

---


> ### Two files that are easy to get wrong on an update
>
> **NEVER copy `version` across.** `version` holds **your project's** version. The
> scaffold repo also has a `version` file holding **the scaffold's** — so it shows up as
> a diff on every update, and taking that diff silently replaces your project's version
> with the scaffold's. Measured downstream: `version` held a scaffold version from day
> one and never the app's, and one update did not bump it at all, so `ai/MEMORY.md`
> claimed v0.3.0 while the file still said 0.2.0 for a month.
>
> **DO copy `.scaffold-version`.** That is the marker recording which scaffold release
> you are on. It is what `tools/scaffold_version.sh` reads to tell you when you have
> fallen behind — and it exists precisely because a project once sat on v0.2.0 for four
> months without knowing. Nothing was broken enough to notice.
>
> **Check where you stand before you start:**
> ```bash
> tools/scaffold_version.sh --force
> ```
> `sync-check.sh` runs this too, cached for 24h and silent when you are current.

When the scaffold repo gets new features or fixes, update your project:

### Quick update (pull changed files only)

```bash
cd /path/to/your-project
git checkout main
git pull origin main
git checkout -b chore/update-scaffold

# THE UPSTREAM REPO IS PRIVATE, so raw.githubusercontent.com returns 404 for everyone.
# `gh` is authenticated and is already required elsewhere in this toolchain.
#
# VERIFY WHAT CAME BACK. The failure mode here is not an error, it is a FILE: `curl -sS -o`
# happily writes a 404 body into the target, which is how a re-fetched upgrade tool became
# a script whose first line was `404:`. Anything that fetches must check.
fetch() {  # fetch <repo-path> <dest>
  mkdir -p "$(dirname "$2")"
  gh api "repos/Robiton/ai-project-scaffold/contents/$1?ref=main" --jq .content \
    | base64 -d > "$2" || { echo "fetch failed: $1" >&2; return 1; }
  [ -s "$2" ] || { echo "fetch produced an empty file: $2" >&2; return 1; }
}

# Update hook files and support files (these are safe to overwrite)
fetch "AGENTS.md" AGENTS.md
fetch ".cursorrules" .cursorrules
fetch ".windsurfrules" .windsurfrules
fetch ".codex" .codex
fetch ".editorconfig" .editorconfig
fetch "adopt.ps1" adopt.ps1
fetch ".gitattributes" .gitattributes
fetch "sync-check.sh" sync-check.sh
chmod +x sync-check.sh
fetch ".github/copilot-instructions.md" .github/copilot-instructions.md
fetch ".github/workflows/scaffold-check.yml" .github/workflows/scaffold-check.yml
fetch ".github/PULL_REQUEST_TEMPLATE.md" .github/PULL_REQUEST_TEMPLATE.md

# THE TOOLS. The workflow you just updated CALLS these — header_check.sh,
# session_archive.py and audit_localcoder.sh. Update them together or CI runs a newer
# workflow against older scripts, and each missing one degrades to a warning: you get
# the warning INSTEAD of the check, which reads like a pass.
mkdir -p tools
# DISCOVERED, NOT LISTED. This was a hand-written list of filenames, and by 0.15.x it was
# missing six tools — including BOTH tree scanners, so an adopter who followed it got a
# tools/ directory whose CI then reported "no tools/*_scan.sh were found". A list of what
# ships is a second definition of the directory, and the directory is the first one.
for f in $(gh api "repos/Robiton/ai-project-scaffold/contents/tools?ref=main" \
             --jq '.[] | select(.type=="file") | .name'); do
  fetch "tools/$f" "tools/$f"
  # A tool that lands non-executable is a tool that silently stops running: every
  # discovery loop filters on [ -x ]. Shebang decides, so nothing has to be listed.
  head -1 "tools/$f" | grep -q '^#!' && chmod +x "tools/$f"
done
chmod +x tools/*.sh tools/*.py

# THE STALENESS MARKER. Without this the update "succeeds" and every future session
# still reports you as behind — a check that cries wolf permanently is one people mute.
fetch ".scaffold-version" .scaffold-version
# `version` is still NOT in this list. That is your project's number, not the scaffold's.

# Recreate the CLAUDE.md pointer if it was lost
# REMOVE A LEGACY SYMLINK FIRST OR THIS DESTROYS AGENTS.md.
# Scaffold <=v0.3.0 shipped an AGENTS.md telling adopters to `ln -s AGENTS.md CLAUDE.md`.
# `>` FOLLOWS a symlink, so on any such adoption this line truncates AGENTS.md to the
# eleven bytes "@AGENTS.md" and leaves CLAUDE.md pointing at the wreckage. Reproduced:
# an 86-byte AGENTS.md became 11. setup.sh has always got this right; both MANUAL paths
# in this guide did not. Found on a real stale adoption, 2026-09-04.
[ -L CLAUDE.md ] && rm CLAUDE.md
printf '@AGENTS.md\n' > CLAUDE.md

# VERIFY BEFORE COMMITTING. An update that half-landed looks identical to one that
# worked — that is how a project sat on v0.2.0 for four months.
./setup.sh --check              # changes nothing; run it from the scaffold clone if
                                # your project does not carry setup.sh
tools/scaffold_version.sh --force   # must now say "current", not "BEHIND"
tools/header_check.sh               # every source file still has a valid header
tools/session_archive.py --all --check   # advisory: reports, never fails
tools/conflict_scan.sh              # no unresolved merge markers were committed
tools/secret_scan.sh                # no obvious credential in the tracked tree

git add -A
git commit -m "chore(scaffold): update scaffold to latest"
git push origin chore/update-scaffold
# Open PR and merge
```

### What `setup.sh` migrates for you, and what it does not

`setup.sh` is **not an upgrade command.** It initialises a project and verifies one, and
it carries exactly **one** migration: it replaces a legacy `CLAUDE.md` symlink with the
committed `@AGENTS.md` pointer and strips `CLAUDE.md` out of your `.gitignore` (backing
the old one up to `.gitignore.scaffold-backup` first). That migration exists because
≤v0.3.0 actively told adopters to gitignore it, and creating the pointer without removing
the ignore rule leaves every teammate and every fresh clone with no `CLAUDE.md` — silently,
since it looks right on the machine that ran setup.

Everything else about updating is the file-by-file copy above, governed by the table
below. `setup.sh --check` **changes nothing** — verified — so it is safe to run at any
point during an update to see where you stand.

### What is safe to overwrite vs what is not

| File | Safe to overwrite? | Why |
|------|-------------------|-----|
| `AGENTS.md` | Yes | Standard hook — no project-specific content |
| `.cursorrules` | Yes | Standard hook — no project-specific content |
| `.windsurfrules` | Yes | Standard hook — no project-specific content |
| `.codex` | Yes | Standard hook — no project-specific content |
| `.editorconfig` | Yes | Standard formatting — no project-specific content |
| `.gitattributes` | Yes | Union-merge for `ai/SESSION.md`/`ai/BACKLOG.md` — parallel PRs stop conflicting on the append-logs |
| `sync-check.sh` | Yes | Utility script — no project-specific content |
| `.github/copilot-instructions.md` | Yes | Standard hook |
| `.github/workflows/scaffold-check.yml` | Yes | CI workflow |
| `.github/PULL_REQUEST_TEMPLATE.md` | Yes | Standard template |
| `ai/STANDARDS.md` | **No** | Contains overlay content appended by setup.sh |
| `ai/CODING.md` | **No** | Contains overlay content appended by setup.sh |
| `ai/SECURITY.md` | Maybe | Only if you haven't added project-specific rules |
| `ai/PLANNING.md` | Maybe | Only if you haven't added project-specific rules |
| `ai/SESSION.md` | **Never** | Contains your session history |
| `ai/BACKLOG.md` | **Never** | Contains your tasks |
| `ai/MEMORY.md` | **Never** | Contains your project's institutional knowledge |
| `ai/TEAM.md` | **Never** | Contains your team roster |
| `.github/CODEOWNERS` | **No** | Contains your GitHub handles |
| `tools/*` | Yes | Vendored scripts, no project content — and the CI workflow calls them, so update them together |
| `.scaffold-version` | Yes | It IS the scaffold's release marker; not copying it is why a stale project reports itself current forever |
| `version` | **Never** | Your project's version. The scaffold has a file of the same name holding its own |

**Rule of thumb:** Hook files and vendored scripts are safe. Anything in `ai/` that you
have customized is not.

**One consequence worth knowing before you edit anything under `tools/`:** it is
overwritten on every update, so a setting changed there is silently reverted the next time
you upgrade — and the reversion looks like the tool suddenly misbehaving. Project-level
settings belong in `ai/` files, which are never overwritten. The archive ceilings work this
way deliberately: `tools/session_archive.py` reads them from the
`<!-- scaffold:ceilings ... -->` line in **your** `ai/STANDARDS.md`, so raising one
survives every future update.

---

## Checklist

After adding the scaffold, verify:

- [ ] `ai/` folder exists with all 12 files (8 until 0.84.x; OPERATIONS.md, PROVENANCE.md, STANDARDS_EVIDENCE.md and localcoder.config.json joined since)
- [ ] `AGENTS.md` exists in repo root
- [ ] `CLAUDE.md` exists and contains the `@AGENTS.md` import line (committed)
- [ ] `version` file exists with a valid version string
- [ ] `ai/MEMORY.md` has your project overview filled in (not just the template)
- [ ] `ai/TEAM.md` has your team filled in
- [ ] `ai/SESSION.md` has at least one real entry
- [ ] `.github/CODEOWNERS` has your GitHub handle
- [ ] `.gitignore` does **not** ignore `CLAUDE.md` — it is committed, so every
      teammate and every machine gets it without a setup step
- [ ] Your AI tool loads standards on startup (test with the first-message prompt)
- [ ] `sync-check.sh` runs without errors

---

_This guide lives at: `docs/ADOPTION_GUIDE.md` in the scaffold repo._

## What changed in this guide

_A dated `_Last updated:_` line used to sit here. It is gone from every prose file in this
repo as of 0.15.3 — 23 of 24 overlay files carried one that was months older than the file's
last real change, because it is a hand-maintained copy of something `git log -1` already
answers exactly. Substance stays; the claim about freshness does not._

- The `.gitignore` step no longer tells you to ignore `CLAUDE.md` — it is committed now, and
  this guide's own final checklist had been failing you for it.
- The local-copy route copies `.scaffold-version`, `tools/` and `.claude/settings.json`,
  which the download route already did.
- The two `tools/` fetch loops list nothing: they read the directory from the API. The
  hand-written list they replaced was missing six tools, including both tree scanners — so
  an adopter who followed it got a `tools/` whose CI then reported *"no tools/*_scan.sh were
  found"*, which is a warning standing in for a check that never ran.
