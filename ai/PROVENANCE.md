<!--
Project:  ai-project-scaffold
File:     ai/PROVENANCE.md
Modified: 2026-08-27
Version:  0.1.2.20260827.1015
Purpose:  Every external source this project took something from, with the upstream
          fingerprint AT THE TIME WE TOOK IT — so "have they fixed anything since?" has an
          answer that is not "read the whole repo again".
Changelog:
  2026-08-27 v0.1.2 — The two sources with NO GitHub repository now have rows. `skills-ref` and
                       `splunk-appinspect` were both absent for the same reason — this file was
                       built around owner/repo — and absence read as "nothing to track". They
                       are `unresolved:` rows, which is the honest state: work to do, not a
                       tracked dependency. skills-ref was read at 0.1.5 and demoted out of
                       STANDARDS.md; AppInspect's pin moved 4.1.3 -> 4.3.1.
  2026-08-27 v0.1.1 — Corrected the claude-reflect-system release timing: v1.2/v1.3 shipped
                       2026-01-16/17, seven months before our evaluation, not one. Verified
                       against the GitHub API, not recalled.
  2026-08-26 v0.1.0 — Initial. Created after evaluating claude-reflect-system against a
                       README describing v1.0.0 while v1.3.0 was already out. Both
                       criticisms recorded in that evaluation had upstream answers nobody
                       had seen. That is the entire argument for this file.
-->
<!-- scaffold:ai-file-kind reference -->

# Provenance — what this project took, from where, and at which commit

> ## This file is about the scaffold itself, not about your project.
>
> You received it because the scaffold ships it, and the rows below are the scaffold's own
> borrowings — the linter `tools/lint_python.sh` pins, the action its workflows use, the
> Splunk toolchain its overlay assumes. **They are still worth reading**: you now vendor
> those files, so those pins are yours too.
>
> What this file is *not* is a record of what **your** project borrowed. Add that below,
> under "Your project's sources". An outside reviewer of a real adoption read this file as
> the adopting project's own notes, found it described a different repository, and
> reasonably filed it as leftover noise — this box is the fix for that, and the whole table
> keeps working either way.


`tools/provenance_check.sh` reads the table below. It is **a report, not a gate**: upstream
repositories move constantly, and a check that goes red every time a stranger pushes is red
at a normal moment — see #241 for what that trains.

```bash
tools/provenance_check.sh              # what has moved since we looked
tools/provenance_check.sh --list       # rows only, no network
tools/provenance_check.sh --write      # record that you looked — AFTER you actually did
```

**`--write` is a claim about you, not about them.** It stamps "reviewed on this date at this
ref". Running it without reading the diff converts this file from a record into a decoration.

## `reviewed` and `floor` are different questions, and conflating them is a real error

| column | what it is | does it move? |
|---|---|---|
| `reviewed` | the version we actually read or measured against | **never on its own.** Every number we hold is only interpretable against it |
| `floor` | the minimum version we require, written `>=X` | **yes, deliberately** — when someone verifies a newer one |

**A floor is not a pin.** An exact pin claims one version is acceptable, which is almost
never true and goes stale the day upstream ships a fix. `>=6.3.0` says "below this we know we
are broken" and leaves everything above it permitted.

`--write` refreshes `reviewed` and `checked`. **It never touches `floor`** — that is a policy
a person decided, and a tool that moved it would be granting itself permission.

A `behaviour` or `dependency` row with no floor is flagged: relying on someone else's
internals without saying which versions you mean is an unstated assumption.

## Why the fingerprint column exists

Before this file, the record of a borrowed idea named the source, the licence and the
decision — everything except which version we read. On 2026-08-26 that gap produced a
concrete cost: `claude-reflect-system` was evaluated from a README stating v1.0.0, and the
evaluation's two central criticisms — keyword matching is noisy, and the precision target is
unmeasured — had both been addressed upstream in v1.1–v1.3. The conclusions did not change,
but they were reached against a version that no longer existed, and nothing in the record
would ever have surfaced that.

**Corrected 2026-08-27.** This paragraph originally said those releases landed "a month
earlier". Checked against the API rather than remembered: **v1.2.0 published 2026-01-16 and
v1.3.0 on 2026-01-17 — seven months before the evaluation, not one — and the repository has
had no commit since.** The error is instructive rather than embarrassing: the whole argument
for this file is that a version claim nobody verified is worth nothing, and the paragraph
making that argument contained one. **A `reviewed` column records what we read; it does not
record when they shipped it, so nothing here would have caught this either.** It was caught
by re-verifying every row against the live API during a wider sweep.

## The registry

<!-- scaffold:provenance:begin -->
| source | licence | relation | took | landed | reviewed | floor | checked |
|---|---|---|---|---|---|---|---|
| [`haddock-development/claude-reflect-system`](https://github.com/haddock-development/claude-reflect-system) | **none-declared** | idea | capture-on-Stop-hook. Their confidence tiers and skill-file auto-edit deliberately NOT taken | `tools/correction_capture.py` | v1.3.0 | - | 2026-08-27 |
| [`splunk/addonfactory-ucc-generator`](https://github.com/splunk/addonfactory-ucc-generator) | Apache-2.0 | dependency | build/package toolchain for the Splunk overlay | `overlays/splunk-app/` | v6.6.0 | >=6.6.0 | 2026-08-27 |
| [`actions/checkout`](https://github.com/actions/checkout) | MIT | dependency | the only GitHub Action any shipped workflow uses; 6 call sites | `.github/workflows/` | v7.0.1 | >=v5 | 2026-08-27 |
| [`astral-sh/ruff`](https://github.com/astral-sh/ruff) | MIT | dependency | the pinned linter — `uvx ruff@0.16.1` | `tools/lint_python.sh` | 0.16.1 | >=0.16.1 | 2026-09-06 |
| unresolved:skills-ref (npm, no repository field) | **contradictory** — manifest MIT, bundled LICENSE Apache-2.0 unfilled | evaluated | a skill validator we recommend and no longer require; read the 0.1.5 tarball rather than a repo | `overlays/ai-skill/{CODING,STANDARDS,REFERENCE}.md`, #243 | 0.1.5 | >=0.1.5 | 2026-08-27 |
| unresolved:splunk-appinspect (PyPI, closed source) | proprietary — Splunk | dependency | the packaging gate for Splunkbase and Splunk Cloud; pinned in the overlay | `overlays/splunk-app/REFERENCE.md` | 4.3.1 | >=4.3.1 | 2026-08-27 |
<!-- scaffold:provenance:end -->

## Your project's sources

Rows for what **your** project took from elsewhere. Same columns, same rules. Empty is an
honest state for a project that has borrowed nothing; a row you cannot fill in is not.

`tools/provenance_check.sh` reads every row in the file, so entries added here are checked
exactly like the scaffold's own.

| source | licence | relation | took | landed | reviewed | floor | checked |
|---|---|---|---|---|---|---|---|


## Notes that do not fit in a cell

### The two rows added 2026-08-26 came from sweeping COMMANDS, not URLs

The first pass of this registry was built by grepping for `github.com/…`, which finds
everything we *linked to* and nothing we *run*. A second sweep over `uses:`, `npx`, and `uvx`
found three dependencies with no URL anywhere in the tree:

- **`actions/checkout`** — the only Action in any shipped workflow, at 6 call sites, with a
  floor already enforced by `preflight` (*"shipped workflows pin actions at or above the
  floor"*). It had a floor and no row.
- **`astral-sh/ruff`** — pinned exactly at `0.16.1` by `tools/lint_python.sh`. The pin is
  deliberate: a linter that drifts turns an unrelated change into a red gate. So this row is
  expected to report MOVED against upstream, and that is the pin working.
- **`mcp-remote`** — recorded in `localcoder-dev`, and the interesting one: executed
  **unpinned** on every MCP launch.

**The lesson for anyone extending this file**: a dependency you *execute* leaves no URL. Sweep
`uses:`, `npx`, `uvx`, `pipx`, and whatever your language's runner is — not just links.

### `claude-reflect-system` — the licence is NOT MIT, and that correction matters

The README says MIT. **The repository has no LICENSE file**: `GET /repos/.../license`
returns 404 and the root listing contains no `LICENSE`, `LICENCE` or `COPYING`. A licence
named in prose is not the grant, and GitHub's default for an unlicensed public repo is *all
rights reserved*.

**This does not create exposure for us, and the reason is worth stating precisely: we took
no code.** `correction_capture.py` was written here, its pattern set is different (their
MEDIUM and LOW tiers are not implemented at all), and its architecture is the opposite of
theirs on the one decision that matters — it never writes to a context file. What was taken
is the idea of capturing on the Stop hook, and ideas are not the thing a licence governs.

The row therefore reads `none-declared` rather than `MIT`, and **nothing may be copied from
that repository** until a real licence exists. This project briefly recorded it as MIT in
five places on 2026-08-26, all corrected.

### What v1.1–v1.3 changed, read 2026-08-26

Both were answers to the criticisms in our own evaluation, which had been written against
v1.0.0:

- **v1.1/v1.2 — "Semantic Detection", using Claude itself as the classifier**, plus a SQLite
  cross-repo ledger and auto-promotion of a learning seen in 2+ repos. This addresses the
  keyword-noise problem directly. **We still do not want it**, but the reason has changed
  from *accuracy* to *architecture*: capture runs in a Stop hook on every turn, where a model
  call is neither cheap nor fast, and `ai/STANDARDS.md` puts inference on the agent's side of
  the line, not the hook's. Recording the better reason matters — the old one is now wrong.
- **v1.3 — "Meta-Learning"**: passive logging of the human's Accept/Modify/Skip decision per
  pattern, with per-pattern health thresholds (>80% acceptance "excellent", 50–80%
  "healthy"). **This one is worth taking.** Our `--measure` does the same job by hand, once,
  against one transcript. Theirs closes the loop continuously. The cheap version here needs
  no inference at all: when a captured candidate is promoted into `ai/MEMORY.md` at step 3 of
  *Corrections are learnings*, record which pattern produced it — pattern health is then
  promoted/captured per rule, measured rather than remembered. Filed as an issue.

### `splunk/addonfactory-ucc-generator`

A build dependency of the Splunk overlay rather than a borrowed idea, tracked here because
the question "did the toolchain move under us?" is the same question this file answers.
`overlays/splunk-app/RESEARCH.md` pins UCC 6.3.0 in its notes; upstream is **v6.6.0**.

### 2026-08-27 — every row re-verified against the live API

`checked` moved to 2026-08-27 on all four rows. **`reviewed` deliberately did not** — we verified *metadata*
(stars, last commit, licence, archived, latest release), not diffs, and the columns mean different things.

What the pass found, beyond the date correction above:

- **`haddock-development/claude-reflect-system`** — last commit **2026-01-17**. No LICENSE, re-confirmed: the
  API returns 404 for the licence endpoint. **Nothing may be copied from it.**
- **`splunk/addonfactory-ucc-generator`** — upstream **v6.6.0**. `overlays/splunk-app/RESEARCH.md` was still
  written against **6.3.0**. ~~The floor `>=6.3.0` is satisfied; the research notes have not been re-read.~~
  **Re-read the same day** — see below. The floor moved to **`>=6.6.0`**, because 6.6.0 is where two CVEs in
  the generated UI get fixed, and "satisfied" was the wrong word for a floor set below a known vulnerability.
- **`actions/checkout`** — upstream v7.0.1, we pin `@v7`. **Current.**
- **`astral-sh/ruff`** — upstream **0.16.6**, we pin exactly **0.16.1**. **Expected and correct** — see the note
  above on why a linter pin is deliberate.

⚠️ **Found outside this file, and it is the more serious one:** `overlays/ai-skill/` instructs adopters to run
`npx skills-ref validate`. **`skills-ref` is an npm package with no `repository` field, no homepage, one
maintainer and no release since 2025-12-27.** It was unpinned, had no source anyone could audit, and
`overlays/ai-skill/STANDARDS.md:34` stated passing it as a requirement. **It appeared nowhere in this registry
because it has no GitHub URL to record** — which is exactly the gap the "sweep COMMANDS, not URLs" note warns
about, one layer deeper than the sweep that produced it. Filed as **#243**, and closed the same day by the
audit below.

### 2026-08-27, later — the two sources this file was shaped not to hold

Both gaps had the same cause. Every column here assumes `owner/repo`, so a dependency that lives only on npm
or only on PyPI had nowhere to go, and having nowhere to go read as nothing to record. They are now
`unresolved:` rows — the state this registry already had a word for, meaning *work to do*, not *tracked*.

**`skills-ref` — read the tarball, since there is no repository to read.** 0.1.5, sha256
`0bc9a70d10987a2517d92b0f608fb885eeabd8efcc40ad4c2e338a1c1e8ddc6f`, 16 KB:

| checked | finding |
|---|---|
| what it does | 548 lines of `dist/` JS. `commander` + `js-yaml`. Reads `SKILL.md`, validates frontmatter, exits |
| network | **none** — no `fetch`, no `http`, no `net`, no `dns` |
| execution | **none** — no `child_process`, no `exec`, no `eval`, no `new Function` |
| filesystem | **reads only** — no `writeFile`, no `mkdir`, no `unlink` |
| environment | never reads `process.env` |
| licence | 🚨 `package.json` says **MIT**; the bundled `LICENSE` is an **Apache-2.0 template with `Copyright [yyyy] [name of copyright owner]` never filled in** |
| upstream's own words | 🚨 README: *"This library is intended for demonstration purposes only. It is not meant to be used in production."* |
| authorship | `YanchaoMa <crazyyanchao@gmail.com>` in the manifest; npm maintainer is `yanchaoma@foxmail.com`. **This rules `AkaraChen/skills-ref` out** — that same-named GitHub project is a different author, so it is not the source and never was a candidate |

**The code is harmless and the requirement was not.** #243 recommended pinning; the tarball changed the
answer. A tool whose own README says *demonstration only* cannot be a completion requirement, so
`STANDARDS.md` no longer lists it — it is an optional convenience, pinned at `@0.1.5`, with the licence
contradiction written next to it in `CODING.md`. **The audit is what the pin is for**: unpinned `npx` would
fetch whatever that single maintainer publishes next, and none of the table above would still apply.

**`splunk-appinspect` — a pin that was quietly producing false greens.** `overlays/splunk-app/REFERENCE.md`
pinned `==4.1.3` (published 2026-02-25); current is **4.3.1** (2026-08-19). AppInspect is the gate for
Splunkbase and Splunk Cloud, and **Splunk vets against their current version, not ours** — so an old pin
passes locally and fails on submission. That is worse than no pin, because it returns green. Moved to 4.3.1
and the reason is now written beside it. It has no public repository, so this file can never track its drift;
the revisit trigger in `RESEARCH.md` is the only mechanism, and it now carries a checked date.

**UCC re-read at the same time.** `overlays/splunk-app/RESEARCH.md` was written against 6.3.0 and upstream is
6.6.0. The reason to move is not the features: 6.6.0 raised `react-router-dom` to v7.18.0 for
**CVE-2026-53666 and CVE-2026-53669**, and that code ships inside the generated add-on UI. 6.4.0 also
**tightened the OAuth client-credentials schema to require an access-token endpoint**, so a `globalConfig.json`
that was valid under 6.3.0 can fail validation now. Both are recorded in that file.

## What belongs here, and what does not

| record it | do not record it |
|---|---|
| code copied or adapted | your own dependencies in `pyproject.toml` / `package.json` — the lockfile is the record |
| an idea or design taken | a doc you read and did not act on |
| **behaviour reverse-engineered and depended on** | a one-off Stack Overflow answer |
| a source evaluated and REJECTED, with the reason | |
| a catalogue that led you to the above | |

**`behaviour` is the relation people forget.** Reading a shipped bundle and depending on what
you find there is a real dependency on someone else's internals, with no package manager
watching it. When they change it, nothing tells you.

**Recording a rejection is not bookkeeping.** It is what stops the same source being
re-evaluated from scratch in six months — and, as v1.1–v1.3 above show, what makes it
possible to notice when a rejection has stopped being true.
