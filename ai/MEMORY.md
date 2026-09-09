<!-- scaffold:ai-file-kind template -->
# Project Memory

_Persistent context. Updated when architectural or design decisions are made._
_This file is what replaces lost context when switching tools or machines._
_Never store credentials, API keys, or sensitive data here._
_Entries must be specific enough for someone who wasn't there to act on them._
_"Chose X" is not enough. "Chose X over Y because of Z specific constraint" is._
_Entries are STUBS: what was decided + the measurement behind it + the revisit trigger._
_Full rationale and rejected alternatives go to MEMORY_ARCHIVE.md — this file is loaded_
_at every session start, so anything in it is paid for by every future session._
_A superseded decision leaves entirely, with `superseded by <entry/date>`._
_See ai/STANDARDS.md → MEMORY.md quality bar._

---

## Project overview

[One to two paragraph description of what this project is, what it does,
and who uses it. Write this as if briefing someone who has never seen the project.]

## Architecture decisions

_**One dated entry per decision, newest first.** The `### YYYY-MM-DD` heading is not
decoration — `tools/session_archive.py` moves entries into MEMORY_ARCHIVE.md by that heading,
and an entry without one can never be archived. This section used to be a table; a table row
is not an entry the archiver can move, so a project following the template exactly could grow
past its ceiling with no automated way back under it._

### YYYY-MM-DD — [the decision, in a few words]

**Decided:** [what was chosen]
**Why:** [the specific constraint or measurement that forced it, not "it is cleaner"]
**Rejected:** [what else was considered, and the reason it lost]
**Revisit:** [the trigger that would reopen this — a number, a date, a dependency]
**Full rationale:** MEMORY_ARCHIVE.md

## Key conventions

_Project-specific patterns all AI tools should always follow._
_Add anything here that is not already covered by CODING.md or SECURITY.md._

## Known issues and gotchas

_Things that have caused problems. What AI tools should know going in._
_Add these as they are discovered — do not wait until they become bigger problems._

_**The format is load-bearing.** `localcoder` injects from this section into every draft,_
_and it reads **only Markdown list items starting at column 0**. A prose paragraph here_
_is not read — it will say so on stderr rather than injecting nothing quietly, but the_
_entry still does nothing until it is a list item._

_Relevance is scored per task keyword: **1** in the body, **3** in a `**bolded title**`,_
_**5** in a `tags` comment. An entry needs **3** to be injected at all, so lead with a_
_bolded title and tag anything worth finding. Entries about the toolchain itself_
_(localcoder, the scaffold, Ollama) are deliberately never injected._

_Not read as entries: blank lines, fenced examples, HTML comments, and italic guidance_
_lines like these — so the example below cannot inject itself._

_**Say what the entry is a fact ABOUT.** An entry here is injected as a fact about the_
_code; it is a fact about the code **the day you wrote it**. Measured on an adopting_
_project: an entry that was true when written and false on the engine now pinned made the_
_model report a correct function as broken, with correct-looking reasoning, in a codebase_
_with ~180 matching call sites. The model cannot catch that — we told it the rule._

_So name the file the claim depends on and stamp its hash. `localcoder --gotcha-audit`_
_prints the exact line to paste, checks every entry, and exits 1 when a named subject has_
_changed under its claim. **Age is the wrong axis**: an entry about a file untouched for a_
_year is fine; one about a file changed yesterday may already be void._

_A changed subject is **not** withheld — it is still injected, carrying an explicit as-of_
_marker, so the model treats it as a claim to verify rather than a fact. Withholding it_
_silently would be the failure this whole mechanism exists to prevent._

_An entry about the machine or the toolchain has no file to point at. Say so with_
_`<!-- subject: not-file-scoped -->` rather than leaving it blank, so "nobody has stamped_
_this yet" and "this cannot be stamped" stay countable apart._

```text
- **Widget parser:** chokes on CRLF input — normalise line endings before parsing.
  <!-- tags: parser, encoding -->
  <!-- subject: src/widget_parser.py@3f9a1c2b7d04 -->
```

## External dependencies and integrations

_APIs, services, and tools this project connects to._
_List name and purpose only. Never store credentials here._

| Name | Purpose | Where credentials are stored |
|------|---------|------------------------------|
|      |         |                              |

## Team and ownership

| Name | Role | Preferred tool |
|------|------|----------------|
|      |      |                |
