# Agent Runbook

**You are an AI agent and this is the only document you need to read to set up, verify,
upgrade, or apply an overlay.** Everything here is a command and its expected result. If you
want the reasoning, it is in [`ADOPTION_GUIDE.md`](ADOPTION_GUIDE.md) — 1,051 lines of it —
but you do not need it to do the work correctly.

This file exists because a human may never read the guide. It is written so that following it
literally produces a correct adoption, and so that anything going wrong produces a message
naming the fix rather than a mystery.

---

## The three rules that make everything else work

**1. Read the exit code, not the output.**

| code | means | do |
|---|---|---|
| `0` | verified | proceed |
| `1` | found a real problem | fix it; the message names the fix |
| `2` | you used the tool wrong | read the usage it printed |
| **`3`** | **COULD NOT CHECK** | **not a pass and not a failure — say so** |

**Exit 3 is the one that matters.** It means the check did not run: no lockfile, no network,
no history to read. Reporting it as success is the most common way this scaffold gets
misused. *An absent record and a clean record are different answers.*

**2. Never pipe a gate into anything.**

```bash
tools/preflight.sh | tail -25        # WRONG — $? is tail's, always 0
tools/preflight.sh; echo "rc=$?"     # right
```

This repository has pushed a red tree exactly this way. `&&` after a pipe reads the *last*
command's status.

**3. Prove it, do not assert it.** Every step below ends in a command whose output is the
evidence. Run it and report what it said. "Setup completed successfully" is not evidence;
`./setup.sh --check` exiting 0 is.

---

## Which situation are you in?

```
Does the target have a .scaffold-version file?
├─ no  → is it an empty/new project?
│        ├─ yes → A. NEW PROJECT
│        └─ no  → B. EXISTING PROJECT
└─ yes → is it behind the newest release?
         ├─ yes → C. UPGRADE
         └─ no  → D. VERIFY ONLY
```

Check it:

```bash
cat .scaffold-version 2>/dev/null || echo "not adopted"
```

---

## A. New project

```bash
git clone https://github.com/Robiton/ai-project-scaffold.git
cd ai-project-scaffold
./setup.sh --type base --name my-project --owner "Your Name"
./setup.sh --check;  echo "rc=$?"
```

`--type` is required and switches setup into non-interactive mode. Valid values:

```
base  ai-skill  splunk-app  security-tool  python-script  it-automation  api-integration
```

**Expected:** setup exits 0 and `--check` exits 0. If `--check` reports `[fill in]`
placeholders in AGENTS.md, that is a real finding — a human has to answer them, and you
should report the list rather than inventing values.

---

## B. Existing project

The full file list is in [`ADOPTION_GUIDE.md`](ADOPTION_GUIDE.md) → *Step-by-step*. Do not
retype it from memory — the authoritative list is:

```bash
tools/adoption_manifest.sh --list      # exactly what an adoption receives
```

⚠️ **`CLAUDE.md` is a committed one-line pointer, NEVER a symlink.** Claude Code reads
`CLAUDE.md`, not `AGENTS.md`, and a symlink here has destroyed the target file in a real
adoption — 86 bytes to 11. If the target already has one:

```bash
[ -L CLAUDE.md ] && rm CLAUDE.md
printf '@AGENTS.md\n' > CLAUDE.md
```

**On Windows**, use `adopt.ps1` — it reads the same manifest and needs no bash. The gates
still require WSL or Git Bash; the script says so itself.

---

## C. Upgrade an existing adoption

```bash
git status --porcelain          # MUST be empty — the upgrade refuses a dirty tree
tools/scaffold_upgrade.sh --dry-run
tools/scaffold_upgrade.sh
```

The dry run prints exactly what would change: product files replaced, standards files
three-way merged, `.gitignore` union-merged, migrations that apply. Read it before running
the real thing.

**The refusal on a dirty tree is deliberate** — it makes `git checkout .` a complete undo.

**After upgrading, run the gate.** An upgrade that is not verified is not an upgrade:

```bash
tools/preflight.sh;  echo "rc=$?"
```

---

## D. Verify only

```bash
./setup.sh --check;      echo "rc=$?"     # structure, headers, drift
tools/preflight.sh;      echo "rc=$?"     # everything CI runs, all failures at once
tools/ci_status.sh;      echo "rc=$?"     # is the REMOTE green
```

Run all three. They answer different questions, and `preflight` reports every failure at once
where CI stops at the first.

---

## Overlays

An overlay adds a project-type's standards on top of the base scaffold. It is applied by
`setup.sh --type <name>`, not by copying files.

| overlay | for |
|---|---|
| `base` | anything with no more specific fit |
| `ai-skill` | a Claude Code / agent skill |
| `splunk-app` | a Splunk TA or app |
| `security-tool` | scanners, detection content, anything security-facing |
| `python-script` | a Python CLI or library |
| `it-automation` | Ansible, infrastructure, ops runbooks |
| `api-integration` | anything whose main job is calling someone else's API |

**Applying one to a NEW project:** `./setup.sh --type <name> --name X --owner Y`

**Applying one to an EXISTING adoption:** the overlay's standards are appended to
`ai/STANDARDS.md` and `ai/CODING.md`. The guide's *Step-by-step* has the exact commands;
`splunk-app` additionally takes `--splunk-new` or `--splunk-existing` plus
`--splunk-app-type`, `--splunk-version`, `--splunk-deploy`.

**To see what an overlay actually contains before applying it:**

```bash
ls overlays/<name>/
head -40 overlays/<name>/STANDARDS.md
```

⚠️ **`setup.sh --check` reports `no overlay applied (base scaffold only)` as a note, not a
failure.** That is correct for a base adoption and is not something to "fix" by applying an
overlay at random.

---

## When something fails

**Run the gate and read the whole output.** `preflight` prints every failure; do not fix the
first and re-run.

| symptom | it means |
|---|---|
| `[GAP]` | the check could not run — environmental, exit 0, **not a pass** |
| `[FAIL]` | a real finding, and the line names the remedy |
| `NOTHING TO SCAN` | no lockfile in the tree; the scanner had nothing to look at |
| `NOT MEASURED` | the instrument is absent — say so, never round to zero |
| `vendored scaffold is not more than one release behind` | upgrade, or check the age — since 0.97.0 this only fails when the oldest release you skipped is more than 7 days old |
| `session hooks ... NEVER FIRED` | on a **new** adoption this is now `too early to tell`; if it says NEVER FIRED, the repo has genuinely been worked in without the hook running |

Full symptom table: [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md).

---

## What to report back to the human

Not "done". These four things:

1. **Which situation** you were in (A/B/C/D) and the command you ran.
2. **The exit code** of `./setup.sh --check` and of `tools/preflight.sh`, verbatim.
3. **Every `[FAIL]`, `[GAP]` and `NOT MEASURED` line**, unedited. A `[GAP]` is information,
   not noise — it says a declared check did not run.
4. **What you did not verify.** If you could not run a gate, say which and why.

---

## Things that look fine and are not

Collected from real incidents in this project. Each cost real time.

- **A test suite with no `.github/workflows/` looks identical to one that is green.** `gh run
  list` returns empty in both cases. Check the directory exists.
- **A check that prints nothing when clean is indistinguishable from one that never ran.**
- **`AGENTS.md` present with no `CLAUDE.md` means Claude Code loads none of your rules**, and
  nothing reports it. This is the most common broken adoption.
- **Copying `AGENTS.md` alone is not an adoption.** Without `.scaffold-version` there is no
  upgrade path and no staleness check; without `tools/` there are no gates.
- **A backup, log or record nobody has read back is not one.** The same applies to a gate
  nobody has watched fail.
