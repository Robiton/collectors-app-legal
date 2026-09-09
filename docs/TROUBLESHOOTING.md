# Troubleshooting

Common issues when using the AI Project Scaffold and how to fix them.

---

## AI tool doesn't load standards on startup

**Symptom:** You open a project in Claude Code, Cursor, or another tool, and it doesn't know about your standards or backlog.

**Cause:** CLAUDE.md pointer is missing/edited or tool hook file is missing.

**Fix:**
```bash
# Check the pointer — it must contain a line that is exactly: @AGENTS.md
cat CLAUDE.md

# If it's a regular file or missing:
printf '@AGENTS.md\n' > CLAUDE.md
```

For other tools, verify the hook file exists:
- Cursor: `.cursorrules`
- Windsurf: `.windsurfrules`
- Codex: `.codex`
- GitHub Copilot: `.github/copilot-instructions.md`

---

## sync-check.sh shows files are behind

**Symptom:** `./sync-check.sh` reports ai/ files are behind origin.

**Fix:**
```bash
# On main branch:
git pull origin main

# On a feature branch:
git fetch origin && git merge origin/main
```

---

## setup.sh fails or behaves incorrectly

**Symptom:** setup.sh exits with an error or doesn't apply the overlay.

**Common causes:**

| Error | Fix |
|-------|-----|
| "permission denied" | Run `chmod +x setup.sh` |
| Overlay not applied | Verify you selected the right number (1-7) |
| CLAUDE.md is a file | setup.sh now backs it up automatically — check for `CLAUDE.md.bak` |
| Splunk context appended twice | Fixed in v0.2.1 — update your scaffold copy |

---

## Merge conflicts in ai/ files

**Symptom:** Git reports conflicts in SESSION.md, BACKLOG.md, or MEMORY.md after merging.

**Rules:**
- `ai/SESSION.md` and `ai/BACKLOG.md` — **keep both sides**. These are append-only logs. Accept all entries.
- `ai/MEMORY.md` — **resolve manually**. Both sides may have made architectural decisions that conflict. The project owner must review and reconcile.

---

## CI reports "an ai/ file is over its archive threshold"

**It does not fail the job, and has not since 0.14.0.** This section described a build
failure for five releases after the gate was removed — read on only if you want the file
shorter, never because something is red.

```bash
tools/session_archive.py --all --check  # which file, by how much, and what would help
tools/session_archive.py --apply        # rotates SESSION.md only
```

`SESSION.md` rotates mechanically. `BACKLOG.md` is swept by hand at each release.
**`MEMORY.md` is never automated** — deciding which decisions are superseded is a human
call, and a script guessing would drop live ones. Every path *adds* to an archive; none
removes from the live file.

**If the ceiling is wrong for your project, change it.** Ceilings are per-project, in a
marker `ai/STANDARDS.md` carries and no scaffold update overwrites:

```
<!-- scaffold:ceilings SESSION.md=800/900 BACKLOG.md=800/900 MEMORY.md=800/900 -->
```

**Do the archive pass first.** "The ceiling is too low" and "I have not archived" look
identical from inside the file, and only the pass tells you which you have — measured on
this scaffold's own dev repo, where the file sat 36 lines over its line with nothing
archivable because five finished items had never been MARKED finished.

`MEMORY.md` ships higher than the other two on purpose: a session entry is a log line and a
backlog item is a task, but a decision entry is an argument, and the ones worth re-reading
run 13 to 35 lines. Raise the number before you shorten an entry that is carrying its
weight.

---

## CI fails: "Possible credential found"

**Symptom:** the Scaffold Check job fails on `tools/secret_scan.sh`, often on a line nobody
touched, right after an upgrade.

`tools/secret_scan.sh` is a **heuristic backstop**, not a secret scanner — gitleaks is the
real tool. It looks for *keyword + separator + a literal value* across the tracked tree, so
it fires on real credentials and on things that merely look like them.

**If it is a real credential:** remove it, rotate it, and treat the git history as
compromised — deleting the line does not remove it from earlier commits.

**If it is not**, say so on that line and re-run. Do NOT exclude the file and do NOT rename
the variable to dodge the pattern:

```python
_DEFAULT_SECRET = 'dev-secret-key-change-in-production'  # scaffold:not-a-secret
```

An existing `# nosec` on the line is honoured too — it already means a human reviewed this
line. The exception is deliberately **line-scoped**: a file-level exclusion is a hole that
outlives the reason for it.

A project that must commit Splunk HEC receiver tokens declares
`<!-- scaffold:hec-tokens-committed -->` in `ai/STANDARDS.md`, which permits exactly one
shape — `token = <uuid>` in a file named `inputs.conf`. A password, an api_key, a bearer,
or a token whose value is not a UUID still fails, there and everywhere else.

```bash
tools/secret_scan.sh             # what it found, and where
tools/secret_scan.sh --selftest  # prove the checker fails what it should
```

---

## CI fails: "Unresolved merge-conflict markers are committed"

**Symptom:** the Scaffold Check job fails on `tools/conflict_scan.sh`, usually in
`ai/STANDARDS.md`, usually after `./setup.sh --upgrade`.

An upgrade three-way merges the standards files. When you and upstream edited the same
region it writes ordinary git conflict markers and hands the region to you, because that is
the case where guessing would be wrong. This check exists because **the instruction to
resolve them was, for thirteen releases, the only thing enforcing it** — and this scaffold's
own dev repo committed a set, layered the next upgrade on top of them, and stayed green.

Open each file named, keep what belongs from **both** sides, and delete the `<<<<<<<`,
`=======` and `>>>>>>>` lines. Then:

```bash
tools/conflict_scan.sh          # confirms every marker is gone
```

**If a region is a deliberate example of a conflict** — a tutorial, a changelog quoting what
an upgrade wrote — mark any one of its three marker lines:

```
>>>>>>> theirs   scaffold:not-a-conflict
```

Markdown setext headings (`=======` under a title) never trigger it: a region needs an
opener *and* its closer.

---

## CI fails: "a changed file was not re-stamped"

**Symptom:** the Scaffold Check job fails on `tools/header_check.sh --since`. **Also blocking
as of 0.6.1.**

**Cause:** you changed a source file (`.sh`, `.py`, or an extensionless script) and did not
update its header's `Modified:` / `Version:` lines.

```bash
tools/header_check.sh --since origin/main     # names each unstamped file
```

**Fix:** bump `Modified:` to today and the `Version:` build stamp on each named file, and add
a changelog line. It is one line per changed file.

This is not bookkeeping. `Modified:` is how the next reader decides whether a measurement
quoted in a comment still describes the code — and this scaffold's own comments are largely
measurements. It went unchecked until 2026-08-04, by which point `setup.sh` carried a stamp
four versions and a month behind its own last change.

**Do not find this out from CI.** `tools/preflight.sh` runs this check in CI's exact form
along with every other gate, in about 25 seconds, and reports all of them at once.

---

## CI fails on a gate my local run said nothing about

**Symptom:** you ran the checks you know about, everything was green, and the build went
red — possibly twice in a row, each fix revealing the next gate.

**Cause:** there is more than one gate, and CI **stops at the first failure**, so a red build
tells you about exactly one of them. Reconstructing the list from memory omits a different
check for every person who tries. Measured on this repo 2026-08-09: two red builds in three
minutes, on the commits that were adding a rule about checking CI.

**Fix:**

```bash
git commit ...
tools/preflight.sh          # every gate, all failures at once, ~25s
git push
```

Three traps it exists to remove, each of which produced a real red build here:

- **Order.** `check && commit && push` runs the check against a tree that is not what you
  are about to push. Preflight refuses a dirty tree outright (exit 3) rather than reporting
  a result that describes something else — `--allow-dirty` if the dirt is genuinely
  unrelated, and it will say so in the output.
- **A bare `header_check.sh` is weaker than CI's invocation**, which uses
  `--since origin/main`. Preflight always runs the stricter form.
- **`tools/adoption_check.sh`** runs the scaffold's own gates inside a synthetic ADOPTION —
  a tree with no `overlays/`, no `OVERVIEW.md` and no scaffold tags. Every rule that is true
  of the scaffold and false of an adoption used to ship green; on 2026-08-11 that single gap
  produced four defects in one evening, all found by one person upgrading a real project.

If CI grows a gate, `tools/preflight.sh --coverage` fails until preflight runs it too — so
the local list cannot quietly fall behind the remote one.

---

## Editing `tools/localcoder` fails CI with "the two copies have drifted"

**This cannot happen any more, and the section is kept only to say so.** Until W-15,
`localcoder` was one product with two homes — `tools/localcoder` here and
`src/localcoder/localcoder` in `Robiton/localcoder` — and `tools/localcoder_sync.py` failed
CI when they diverged.

The scaffold no longer ships localcoder. There is one copy, in `Robiton/localcoder`, and it
is installed rather than vendored:

```bash
uv tool install git+https://github.com/Robiton/localcoder
localcoder --doctor
```

The drift check and its tool retired with the second copy. If you are looking at this
because CI told you the copies drifted, you are on a release before 0.36.0 — upgrade.

**The markers still exist**, and `scaffold:owns-localcoder` still means *the upgrader will
not install localcoder's own files into this repo*. It is read by `setup.sh --upgrade`, and
it still does not mean "this project may edit them freely" — `scaffold:localcoder-forked`,
sitting next to it, is the one that means that. The permissive-sounding one is the strict
one; that has not changed.

If a vendored `tools/localcoder` and friends are still sitting in your tree after upgrading
past 0.36.0, that is expected and documented: **the upgrader has no deletion mechanism**
(A7). It stops shipping files; it does not remove them. Delete them by hand — and grep for
*invocations*, not filenames, first. A wrapper running `python3 tools/localcoder` cannot
work against a console-script entry point, and a filename grep will not show it.

---

## CI fails on dozens of files that predate the standard, right after an upgrade

**Symptom:** you upgraded an existing project, the upgrade itself went cleanly, and then
`header_check` failed most of your codebase at once:

```
[FAIL] app.py            header missing: Project File Modified Version Purpose
[FAIL] config.py         header missing: ...
  ... 33 files
```

**Cause:** the file-header rule became blocking in 0.6.1, and with no arguments the checker
holds *every* tracked source file to it — including files written long before your project
adopted the standard. **This is the bill scaling with the age of your codebase, not
something you did wrong.**

**Fix — declare when you adopted the rule. Once, and it survives future upgrades:**

```bash
tools/header_check.sh --adopt        # writes the date into ai/STANDARDS.md
git add ai/STANDARDS.md && git commit -m "chore: declare the file-header baseline"
```

Files whose last commit predates that date are now `legacy`: counted on every run, never
failed. **Edit one and it is in scope immediately** — the baseline exempts history, not
future work. `tools/header_check.sh --list-legacy` names what is left; delete the marker
when that list is empty.

**Do not instead** add to `EXCLUDE` in `tools/header_check.sh`, or append `--warn-only` in
`.github/workflows/scaffold-check.yml`. Both are product-owned files that
`scaffold_upgrade.sh` replaces, so the accommodation is erased by your next upgrade — and
locally downgrading a blocking check is the loosening `ai/STANDARDS.md` → *Rule precedence*
forbids. The baseline is the sanctioned route, and it lives in a file upgrades merge.

Since 0.6.7 the upgrade tool detects this during the upgrade and prints the same remedy, so
you should meet it before CI rather than after. Requires full history — CI must check out
with `fetch-depth: 0`, which the shipped workflow already does; the checker refuses to grant
the exemption it cannot verify rather than guessing.

---

## The draft ignored my standards, and everything looked fine

**Symptom:** a draft with a large context — `-f` on a big file, or `--digest` over a tree —
comes back ignoring the drafting brief, the gotchas, or half of what you sent. Nothing
errored. Often it came back *faster* than usual.

**Cause: the prompt was truncated and nobody told you.** Ollama's llama.cpp runner reads
only **`num_ctx/2`** and reserves the rest for generation. Past that it keeps the first
**four** tokens and drops the front of the prompt — which is where the system prompt, the
standards and the gotchas are. The API returns a normal answer; the warning goes to the
server log:

```bash
grep "truncating input prompt" ~/Library/Logs/ollama.log
# msg="truncating input prompt" limit=16386 prompt=32832 keep=4 new=16386
```

`limit` is half the window. Measured 2026-08-09 at `num_ctx` 8,192 against one
200,000-character prompt: the GGUF model received **4,098 tokens and answered in 2.3 s**,
against 58.6 s for the MLX model that received all 63,431. **The truncated call is the fast
one** — losing 94% of a prompt presents as the tool getting quicker, and the reply still
reads plausibly because the model answers the question it was left with.

**MLX-runner models did not truncate at any window tested**, so this bites the GGUF half of
a mixed fleet.

**Fix:**

```bash
localcoder --where          # `max prompt` is the real ceiling — half the window on GGUF
localcoder --doctor         # confirms the server default matches the config
```

Since 0.14.0 localcoder warns *before* the call against that ceiling, and reports
**`TRUNCATED`** *after* it by comparing what it sent against the `prompt_eval_count` the
server returns — the second one is the reliable half, because it is evidence rather than
arithmetic. Every draft logs `truncated` and `num_ctx`, so old rows can be re-read.

Raise `num_ctx` in `ai/localcoder.config.json` (a reviewed change — see the cost table in
that file) and **re-run the Ollama service installer** so the server default follows. That
script left with localcoder in W-15 and lives at `ops/install_ollama_service.sh` in
`Robiton/localcoder`; the scaffold does not ship it.
On MLX a larger window is free until you fill it; on GGUF it is pre-allocated at load, so
set `num_ctx` per model inside `approved_models` for those.

---

## localcoder ignores my machine-wide settings inside a project

**Symptom:** you set `num_ctx` (or a model) in `~/.config/localcoder/config.json`, and
inside a scaffolded project `localcoder` behaves as if you hadn't.

**Cause: that is the design, and it is not a bug.** Config scopes are **exclusive** — the
first one found *is* the config:

```
1. $LOCALCODER_CONFIG                          explicit
2. <project>/ai/localcoder.config.json         project — committed, shared by the team
3. ~/.config/localcoder/config.json            device  — yours, every project on the box
4. built-in defaults
```

While a project config exists, the device file is ignored **including for keys the project
does not set** — those fall to built-in defaults, not to yours. Otherwise two developers
running the same task on the same project would get different windows with no message,
which is the divergence a committed config exists to prevent.

```bash
localcoder --where     # names the scope, and the origin of every effective setting
```

It says explicitly when a device config is present and unused.

**Fix — if the project genuinely should inherit your defaults, have it say so.** In the
project's committed `ai/localcoder.config.json`:

```json
{ "extends": "device", "default_model": "..." }
```

Shallow merge, project wins per key. `approved_models` is never deep-merged: a device must
not be able to add a model to a project's reviewed registry.

**If instead you want device settings everywhere**, the project config is what is in your
way — that is a conversation with the team, not a local override. `LOCALCODER_*` env vars
work for anything the project lists in `allow_overrides`, and are refused loudly otherwise.

---

## localcoder in a project that never adopted the scaffold

**Symptom:** you run `localcoder` in an ordinary repo and it uses a model you never chose.

**Cause:** with no config anywhere it falls back to built-in defaults — a model tag from
the source, `num_ctx` 131072, no registry and no digest pin.

**Fix:**

```bash
localcoder --init-device    # writes ~/.config/localcoder/config.json
localcoder --doctor         # what this machine actually has
```

Then set `default_model` from what `--doctor` reports. `ai/CODING.md` and `ai/MEMORY.md`
are skipped silently when absent, so drafting still works — you simply get no brief and no
gotchas. Point `standards` / `gotcha_sources` in the device config at machine-wide files if
you want them; those accept absolute and `~` paths.

Since 0.6.7 `--doctor` still **fails** when nothing is configured anywhere. Two places a
config may live is not the same as no pins being acceptable.

---

## localcoder injects no gotchas even though MEMORY.md is full of them

**Symptom:** `ai/MEMORY.md` has a well-populated *Known issues and gotchas* section and
every draft comes back with `gotchas_injected: 0`.

**Cause:** gotchas are read **only** from Markdown list items starting at column 0. A prose
paragraph under that heading is not read — and until v0.8.0 that failed *silently*, so a
full register looked exactly like an empty one. The shipped template invited the mistake by
showing no format at all.

**Fix:** make each entry a `- ` item, lead with a bolded title, and tag it:

```markdown
- **Widget parser:** chokes on CRLF input — normalise line endings before parsing.
  <!-- tags: parser, encoding -->
```

The tool now tells you which of the three states you are in:

| What you see | What it means |
|---|---|
| *"has content but no entries could be read"* | the register is prose — reformat it as list items |
| *"no recorded gotcha matched this task — N read, M skipped as tooling notes"* | parsed fine, judged irrelevant |
| nothing at all | the section is empty; nothing is recorded yet |

**If entries are formatted correctly and still never appear**, check two things. Relevance
needs a score of **3**: a task keyword scores 1 in the body, 3 in a `**bolded title**`, 5 in
a `<!-- tags: -->` comment *inside* the entry (a tags line above the entry belongs to
nothing). And entries mentioning **localcoder, the scaffold or Ollama are never injected**
by design — notes about the toolchain are not context for the code being drafted. A register
written mostly about your local tooling correctly injects nothing; the second message above
is what tells you that is what happened.

---

## A push went out even though preflight was red

Almost always this:

```bash
tools/preflight.sh 2>&1 | tail -3 && git push      # WRONG — the && never gates
```

**A pipeline's exit status is the LAST command's**, so `&&` sees `tail`'s zero and pushes
regardless of what preflight decided. The gate ran, printed `PREFLIGHT FAILED`, and the push
went out anyway. Same family as redirecting a check to `/dev/null` and reading the next
command's status: piping a verdict somewhere convenient discards it.

The documented one-liner is safe **precisely because it does not pipe**:

```bash
git commit ... && tools/preflight.sh && git push
```

If you want to shorten the output, capture the status first:

```bash
tools/preflight.sh > /tmp/pf.txt 2>&1; rc=$?
tail -3 /tmp/pf.txt
[ "$rc" -eq 0 ] && git push
```

`set -o pipefail` also works, but only if it is set before the pipeline — and it makes the
pipeline report the *first* failure, which is not always the one you meant.

**To find out whether it happened to you:** compare the pushed commit against the gate.
`tools/ci_status.sh` will tell you within a minute or two either way — CI runs the same set,
so a gate that was genuinely red locally comes back red there.

## `ai/SESSION_JOURNAL.md` has no `correction candidate` lines

The capture tool is wired to the **Stop** hook and needs the client to pass a transcript
path. Work through it in this order — each step distinguishes a different cause:

```bash
tools/session_hook.sh --dump-payload < /dev/null     # expect: session=unknown transcript=
tools/correction_capture.py --selftest               # the rules themselves
tools/scaffold_log.sh --report                       # has the hook gone quiet?
tools/session_hook.sh --check-wiring                 # is Stop still on the old literal?
```

**The common cause is that nothing was said that matches.** That is the intended state,
not a fault: the rules are narrow by measurement, and a normal working session can easily
contain zero explicit corrections. To confirm the tool sees your transcript at all:

```bash
tools/correction_capture.py --measure ~/.claude/projects/<project>/<session>.jsonl
```

That prints every match with the rule that fired it. Zero matches on a transcript you know
contains a correction means the rules are too narrow for how you phrase things — widen
them **after** running `--measure`, never before, and read `tools/README.md` on why a rule
gets deleted rather than tuned.

**If `--dump-payload` shows a session but an empty transcript**, the client is not sending
`transcript_path`. Set it explicitly:

```bash
export CLAUDE_TRANSCRIPT_PATH=/path/to/session.jsonl   # or SCAFFOLD_HOOK_TRANSCRIPT
```

**If the journal is missing entirely**, the hook never ran — that is `session_hook.sh`'s
problem, not this tool's, and `--check-wiring` names the events still on the old literal.

## The journal filled up with lines that are not corrections

Something widened the patterns. The shipped rules match 3 times on a 484-turn transcript;
if yours is producing dozens, a rule is matching prose rather than instruction.

```bash
tools/correction_capture.py --measure <transcript>   # matches grouped by rule
```

Read the matches for the noisiest rule. **Delete the rule rather than tuning it** if most
of its matches are not corrections — that is the project's own precedent, from an advisory
that fired 53 times and was noise 41 of those times. Two rules were already removed on
exactly this evidence: a bare `instead of` (0 for 12 — "cost 7 minutes instead of 11") and
a bare `never|always` (about 2 for 40 — "that copy never runs").

Also check `MAX_TURN` in the tool. It is 2000 characters, and it is the filter doing most
of the work: user turns are bimodal, and everything past p90 is pasted material rather
than something a person typed at you. Raising it restores the noise.

Deleting the noisy lines from `ai/SESSION_JOURNAL.md` is always safe — it is an append-only
scratch file, and `.correction-capture-state` means past turns are not re-read.

## Version file format doesn't match

**Symptom:** CI check warns about version format.

**Expected format:** `MAJOR.MINOR.PATCH.YYYYMMDD.HHMM`
**Example:** `1.2.0.20260420.1400`

**Fix:** Edit the `version` file to match the format. Timestamp should be actual build time in 24-hour format.

**If your repo ships nothing** — a context, docs or research repo — it should have **no
`version` file at all**, and should say so:

```
<!-- scaffold:no-artifact -->
```

in `ai/STANDARDS.md`. `setup.sh --check` and CI then treat the absence as correct. Without the
marker a missing `version` still fails, because inferring the exemption from absence would
turn a real omission into a silent pass.

---

## Updating to a newer scaffold release

**Symptom:** `sync-check.sh` says the scaffold is BEHIND, or you want changes from a newer
release.

```bash
./setup.sh --upgrade --dry-run    # show the plan, change nothing
./setup.sh --upgrade              # do it
```

It three-way merges the standards files against the release named in your `.scaffold-version`,
so your overlay appendix, your ceilings marker and your filled-in `AGENTS.md` command table
survive while upstream changes land. It **never** writes `ai/SESSION.md`, `ai/BACKLOG.md`,
`ai/MEMORY.md`, `ai/TEAM.md`, `version`, `.github/CODEOWNERS` or any `*_ARCHIVE.md`.

| symptom | cause and fix |
|---|---|
| "working tree is not clean" | Deliberate — a clean tree makes `git checkout .` a complete undo. Commit or stash first |
| "no .scaffold-version" | You predate release tracking. `echo <release> > .scaffold-version` if you know which you are on |
| "`<stamp>` is not a tag" | Normal when tracking `main` — build stamps advance every PR, tags exist only at releases. It falls back to the newest release at or below yours, which costs extra conflicts, never silent wrongness |
| `<<<<<<<` markers in an `ai/` file | You and upstream edited the same region. Resolve by hand — that is the case where guessing would be wrong. Then run `tools/conflict_scan.sh` to confirm none are left; CI and `./setup.sh --check` fail while any remain |
| CI newly failing after an upgrade | Build stamps and file headers block (0.6.1). Archive ceilings do **not** — they were blocking from 2026-08-05 until 0.14.0 and now only report. See the two sections above |

**If the command is not in your project yet** (it shipped in 0.5.2):

```bash
gh api "repos/Robiton/ai-project-scaffold/contents/tools/scaffold_upgrade.sh?ref=main" \
  --jq .content | base64 -d > tools/scaffold_upgrade.sh
chmod +x tools/scaffold_upgrade.sh
```

---

## Tool creates local memory files instead of using ai/

**Symptom:** Claude Code writes to `.claude/projects/*/memory/` or creates local session files instead of updating `ai/SESSION.md`.

**Fix:** This happens when the tool doesn't load AGENTS.md properly. Verify:
1. CLAUDE.md contains the `@AGENTS.md` import line
2. AGENTS.md content begins with the correct load order prompt
3. At session start, explicitly say: "Read ai/STANDARDS.md and load all files in the order it specifies"

---

## Wrong overlay applied / need to switch overlays

**Symptom:** You ran `setup.sh` and selected the wrong project type, or your project type changed.

**Why this is hard:** Overlays append content to `ai/STANDARDS.md` and `ai/CODING.md`. There's no automatic "undo" because your own edits may also be in those files.

**Fix:**
1. Open `ai/STANDARDS.md` and find the line `# Overlay: <wrong-overlay-name>`
2. Delete everything from that line to the end of the file (or to the next `# Overlay:` marker)
3. Do the same in `ai/CODING.md`
4. Run `setup.sh` again and select the correct overlay
5. If setup.sh says the overlay is already applied, you missed some content in step 2

**Prevention:** setup.sh (v0.2.1+) now guards against duplicate appends. If an overlay is already applied, it skips rather than duplicating.

---

## Git workflow confusion

**Symptom:** Team member rebased, force-pushed, or committed directly to main.

**Rules (this org uses merge-only):**
- Never rebase — always merge origin/main into your branch
- Never commit directly to main — always use a feature branch + PR
- Never force-push — if the remote has commits you don't have, merge them

**Recovery (if someone force-pushed):**
```bash
git fetch origin
git reset --soft origin/main   # preserve local changes
git stash
git checkout main
git pull origin main
git checkout -b feature/recovery
git stash pop
```

---

## AppInspect failures (Splunk overlay)

**Symptom:** `splunk-appinspect inspect` fails with errors.

**Common failures:**

| Error | Fix |
|-------|-----|
| "No app.conf found" | Ensure `default/app.conf` exists with required stanzas |
| "passwords.conf committed" | Add `**/passwords.conf` to .gitignore, remove from repo |
| "Python 2 syntax" | Ensure all `.py` files use Python 3 syntax (print function, not statement) |
| "Missing metadata" | Create `metadata/default.meta` with appropriate export settings |

---

## Need more help?

- Log the issue in `ai/SESSION.md` so it persists across sessions
- Check `ai/MEMORY.md` — your answer may already be documented
- See `docs/ADOPTION_GUIDE.md` for detailed setup instructions
- See `.github/CONTRIBUTING.md` for workflow guidance
- Benchmarking the local model: `docs/benchmarks/README.md` (optional — nothing fails without it)
