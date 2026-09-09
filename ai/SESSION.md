<!-- scaffold:ai-file-kind template -->
# Session Log

_Updated at the end of every working session, by every tool and every person._
_Most recent session at the top._

## 2026-09-09 — Claude Code (claude-opus-5) — scaffold adoption + viewer fixes

**What happened.** Adopted the AI project scaffold (0.104.1.20260909.0327) into this
repository at Brian's direction, and fixed four field-name mismatches in `viewer.html`
found while checking whether the standalone JSON viewer still works with the collection
app's current export format.

**The viewer bugs, two of which predate this week:**
- `viewer.html` read `item.type` in four places — the type filter's match, the search
  haystack, the card badge, and the dropdown builder — while the app exports `itemType`.
  So on the live site the Type filter was **empty**, type was not searchable, and no card
  displayed its type. That has presumably never worked.
- The viewer never showed or searched `editionMarker`, `collectorNumber` or `castingName`.
  Two collectibles can share a barcode, a name and a photo and differ **only** in edition
  (a McFarlane Platinum vs a regular), so a viewer that omits it cannot answer the question
  the collection exists to answer.

**Also found:** this repository's `viewer.html` and the deployed one had diverged — the
deployed page was 396 lines to the repo's 285. Reconverged on the deployed version before
fixing, so there is one source again.

**Verified** by driving the real drop handler with a real `File` containing an export in
today's shape: 2 cards, edition and collector number displayed, type displayed, search by
edition returns 1, search by collector number returns 1, type filter populated, no page
errors. `tools/viewer_smoke.js`.

**Scaffold notes.** `LICENSE` was deliberately NOT copied: the scaffold ships MIT, and this
repository holds a privacy policy and legal pages whose licensing is Brian's decision
rather than a tooling default. `scaffold:no-artifact` is declared in `ai/STANDARDS.md` —
static HTML on GitHub Pages produces nothing to version, and a version file would describe
a release that does not exist.

**Next steps.** Brian to decide on the LICENSE question. The viewer fix is live-affecting:
this repository IS zmwapps.com.

_This file is what makes context portable across machines and tools._
_When this file exceeds its archive line (800 by default, burst at 900), move older entries to SESSION_ARCHIVE.md — `tools/session_archive.py --apply` does it, losslessly._
_That number is `DEFAULT_LIMITS` in `tools/session_archive.py`; ask the tool rather than trusting this line, which said 600 for eleven days after the default moved to 800._
_Keep only the most recent 5 sessions here — it is loaded at every session start._

---

## Template — copy this block for each new session

## [YYYY-MM-DD] — [Person or Tool] — [Tool used: Claude Code / Cursor / Codex / Windsurf / Copilot / Other]

**Who worked on this:**

**What we worked on:**

**Decisions made:**

**Problems encountered:**

**State changed outside git (only if this session mutated live data/config/infra):**
- Snapshot taken: [path] — restore verified: [yes/no + how]
- Reconciliation invariant: [what must hold] → [the number you got]
- Deliberately deferred: [what, and why]

**Next steps:**

**Backlog changes:**
- Added:
- Completed:
- Moved:

---

## Project start — [YYYY-MM-DD]

**Who worked on this:** [Name]

**What we worked on:**
Project initialized from ai-project-scaffold. Standards loaded.

**Decisions made:**
- Chose project type: [type]
- Initial version set to: [version]

**Next steps:**
- Fill in ai/MEMORY.md with project overview
- Fill in ai/TEAM.md with team roster
- Define initial backlog items in ai/BACKLOG.md
- Begin first work session
