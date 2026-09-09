#!/usr/bin/env bash
# Project:  ai-project-scaffold
# File:     tools/session_journal.sh
# Modified: 2026-09-01
# Version:  0.4.0.20260901.1656
# Purpose:  Capture session FACTS continuously so a lost session loses narrative, not work.
# Changelog:
#   2026-09-01 v0.4.0.20260901.1656 — a `commit` mode, for every tool that is not Claude
#                        Code (#279). Every record-keeping entry point here is a Claude Code
#                        lifecycle hook, so a Cursor, Codex or plain-terminal session read
#                        the standards and wrote nothing while the README claimed the record
#                        travels regardless of tool. A commit is the one event every tool
#                        produces, and .githooks/post-commit now calls this.
#                        NOT `checkpoint`. checkpoint compares HEAD against a state file only
#                        a session hook ever writes, so on a machine where no Claude session
#                        has run there is no state file, no diff, a clean tree immediately
#                        after the commit, and nothing recorded. Measured: two commits, an
#                        empty journal. This mode records the commit it was called for --
#                        a fact it does not have to infer -- and seeds the state file.
#   2026-08-12 v0.3.1 — Same `grep -c ... || echo 0` defect as setup.sh and the workflow: on
#                        an empty journal this printed a count that was literally two lines
#                        long, mid-sentence. Swept, not fixed one site at a time.
#   2026-08-09 v0.3.0 — THE JOURNAL WAS LOGGING ITSELF ON EVERY TURN, and it now has a
#                        selftest at all. `git status --porcelain` COLLAPSES untracked
#                        files into a directory entry, so with the journal untracked it
#                        reported `?? ai/` and never named ai/SESSION_JOURNAL.md — the
#                        filter on that path matched nothing, and the tool counted its
#                        own directory as a project change. `-uall` lists the files.
#                        The code claimed to be "correct by construction" against exactly
#                        this; the construction filtered a path git had already hidden.
#                        Latent wherever the journal is gitignored — which is every repo
#                        that ran setup.sh — and LIVE for precisely the adopter that
#                        guard was written to protect.
#                        Nine cases. This tool is wired to three hook events, runs on
#                        every session in four repos, and had no test of any kind: every
#                        failure path is swallowed, so it could do anything or nothing
#                        and look identical. It did nothing at all until 0.17.0, and the
#                        first test written after it started running found this.
#   2026-07-31 v0.1.0 — Initial creation
#
# THE PROBLEM THIS SOLVES
#   ai/SESSION.md is written by the agent at the END of a session. If the session
#   dies first — context exhausted, window closed, crash, laptop asleep — the entire
#   record is lost. That is not hypothetical: the project this came from ran sessions
#   long enough that SESSION.md was written once, hours in, from memory.
#
# THE SPLIT THAT MAKES THIS WORK
#   Hooks capture FACTS automatically (what changed, what was committed, when).
#   The agent writes NARRATIVE (why, what was decided, what to do next).
#   If the session dies, the facts survive and the narrative is reconstructable.
#   Trying to make a hook write narrative would produce noise nobody reads.
#
# Usage (wired via .claude/settings.json hooks — see tools/README.md):
#   session_journal.sh start        # SessionStart
#   session_journal.sh checkpoint   # Stop — i.e. after every assistant turn
#   session_journal.sh end          # SessionEnd
#
# Portable bash rather than zsh: the scaffold ships to Linux and WSL as well as
# macOS, and its other scripts (setup.sh, sync-check.sh) are already bash.
set -u

# Resolve this script's directory without zsh's ${0:A:h}, following one symlink
# level so an installed copy still finds its repo.
self="${BASH_SOURCE[0]}"
[ -L "$self" ] && self="$(readlink "$self")"
here="$(cd "$(dirname "$self")" && pwd)"

# SESSION_JOURNAL_ROOT, not LOCALCODER_ROOT: the journal is not part of the
# local-coder workflow, and sharing that variable meant setting it for a
# localcoder reason silently relocated an unrelated tool's output.
ROOT="${SESSION_JOURNAL_ROOT:-$(cd "$here/.." && pwd)}"
JOURNAL="$ROOT/ai/SESSION_JOURNAL.md"
STATE="$ROOT/.session-journal-state"
mode="${1:-checkpoint}"

# ------------------------------------------------------------------ selftest
#
# THIS TOOL RAN ON EVERY SESSION IN FOUR REPOS WITH NO TEST OF ANY KIND. It is wired to three
# hook events, it appends to a file nobody reads until something has gone wrong, and every
# failure path is swallowed by `2>/dev/null || true` — so it could do anything, or nothing,
# and look identical either way. It did in fact do nothing at all until 0.17.0 fixed the
# hooks, and the first thing a test found once it started running was that it logged ITSELF
# on every turn.
if [ "$mode" = "--selftest" ]; then
  fails=0
  T="$(mktemp -d)" || exit 1
  SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

  chk() {  # chk <label> <expected> <actual>
    if [ "$2" = "$3" ]; then printf '  ok   %-58s\n' "$1"
    else printf '  FAIL %-58s expected=%s got=%s\n' "$1" "$2" "$3"; fails=$((fails + 1)); fi
  }
  fixture() {  # fixture [gitignore-the-journal]
    rm -rf "$T/r"; mkdir -p "$T/r/ai"
    ( cd "$T/r" && git init -q . && git config user.email a@b.c && git config user.name t
      printf 'x\n' > f.txt
      [ "${1:-}" = "ignored" ] && printf 'ai/SESSION_JOURNAL.md\n.session-journal-state\n' > .gitignore
      git add -A >/dev/null 2>&1 && git commit -qm one >/dev/null 2>&1 )
  }
  jlines() { wc -l < "$T/r/ai/SESSION_JOURNAL.md" 2>/dev/null | tr -d ' '; }
  run() { ( cd "$T/r" && SESSION_JOURNAL_ROOT="$T/r" bash "$SELF" "$@" ); }

  echo "session_journal selftest — it runs every session; it had no test at all"

  fixture
  run start >/dev/null 2>&1
  chk "start writes a session header" 1 \
      "$(grep -c '^## Session started' "$T/r/ai/SESSION_JOURNAL.md" 2>/dev/null | tr -d ' ')"

  # THE DEFECT THIS SUITE WAS WRITTEN FOR. Untracked files are collapsed by git into a
  # DIRECTORY entry, so filtering the journal's own path matched nothing and the journal
  # counted itself as a project change — logging a line on every turn, forever.
  before="$(jlines)"; run checkpoint >/dev/null 2>&1
  chk "a no-change checkpoint writes NOTHING" "$before" "$(jlines)"

  # And with the journal gitignored, which is every repo that ran setup.sh.
  fixture ignored
  run start >/dev/null 2>&1
  before="$(jlines)"; run checkpoint >/dev/null 2>&1
  chk "no-change checkpoint, journal gitignored" "$before" "$(jlines)"

  # A REAL change must still be recorded, or the fix above has broken the feature.
  printf 'changed\n' >> "$T/r/f.txt"
  run checkpoint >/dev/null 2>&1
  chk "a real edit IS recorded" 1 \
      "$(grep -c 'uncommitted file' "$T/r/ai/SESSION_JOURNAL.md" 2>/dev/null | tr -d ' ')"
  chk "and the file is named, so a dead session says what was in flight" 1 \
      "$(grep -c 'f\.txt' "$T/r/ai/SESSION_JOURNAL.md" 2>/dev/null | tr -d ' ')"

  # A NEW COMMIT is the other thing worth a line.
  ( cd "$T/r" && git add -A >/dev/null 2>&1 && git commit -qm two >/dev/null 2>&1 )
  run checkpoint >/dev/null 2>&1
  chk "a new commit is recorded" 1 \
      "$(grep -c 'committed:' "$T/r/ai/SESSION_JOURNAL.md" 2>/dev/null | tr -d ' ')"

  run end >/dev/null 2>&1
  chk "end writes a footer" 1 \
      "$(grep -c '^## Session ended' "$T/r/ai/SESSION_JOURNAL.md" 2>/dev/null | tr -d ' ')"

  # UN-DISTILLED ENTRIES ARE THE POINT OF THE TOOL: a session that ended without anyone
  # writing SESSION.md must be announced at the next start.
  out="$(run start 2>&1)"
  case "$out" in *"un-distilled"*) chk "start announces un-distilled entries" 1 1 ;;
                 *)                 chk "start announces un-distilled entries" 1 0 ;; esac

  # NEVER BREAK A SESSION. Outside a git repo, or with an unwritable tree, it must exit 0 —
  # it is wired to SessionStart, and a non-zero exit there is a developer's first impression.
  rm -rf "$T/nogit"; mkdir -p "$T/nogit/ai"
  ( cd "$T/nogit" && SESSION_JOURNAL_ROOT="$T/nogit" bash "$SELF" checkpoint >/dev/null 2>&1 )
  chk "outside a git repo it still exits 0" 0 $?

  rm -rf "$T"
  echo ""
  if [ "$fails" -eq 0 ]; then echo "  all checks passed"; exit 0; fi
  echo "  $fails check(s) FAILED"; exit 1
fi

stamp="$(date "+%Y-%m-%d %H:%M:%S")"

cd "$ROOT" 2>/dev/null || exit 0

# Never let a journal problem break the developer's session.
{
  case "$mode" in
    start)
      branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
      head_sha="$(git rev-parse --short HEAD 2>/dev/null || echo '?')"
      # An un-distilled journal from last time means a session ended without the
      # agent writing SESSION.md — say so loudly, because that is the exact
      # failure this tool exists to make visible.
      if [ -s "$JOURNAL" ]; then
        # `grep -c` prints "0" AND exits 1 on no matches; `|| echo 0` appended a second
        # line, so this printed a two-line count mid-sentence. Swept 2026-08-11.
        entries="$(grep -c '^- ' "$JOURNAL" 2>/dev/null || true)"
        case "$entries" in ''|*[!0-9]*) entries=0 ;; esac
        printf '[journal] %s un-distilled entries from a previous session are in ai/SESSION_JOURNAL.md\n' "$entries"
        printf '[journal] Fold them into ai/SESSION.md before starting new work.\n'
      fi
      printf '\n## Session started %s (branch %s @ %s)\n' "$stamp" "$branch" "$head_sha" >> "$JOURNAL"
      git rev-parse HEAD 2>/dev/null > "$STATE"
      ;;

    checkpoint)
      # Only record when something actually changed. A turn that answered a
      # question does not deserve a line, and a journal full of no-ops is a
      # journal nobody reads.
      last="$(cat "$STATE" 2>/dev/null || echo '')"
      now="$(git rev-parse HEAD 2>/dev/null || echo '')"
      # Never count the journal's OWN artefacts as project changes. They should be
      # gitignored (setup.sh adds the entries), but if that line is ever missing the
      # journal makes the tree permanently dirty and then logs itself every single
      # turn, forever. Correct by construction rather than by config.
      # `-uall` IS LOAD-BEARING, AND ITS ABSENCE MADE THIS COMMENT FALSE.
      #
      # By default git COLLAPSES untracked files into a directory entry: with the journal
      # untracked, `git status --porcelain` says `?? ai/` and never names
      # `ai/SESSION_JOURNAL.md` at all — so a filter on the file path matched nothing, the
      # journal counted its own directory as a project change, and it logged itself on every
      # turn, forever. Exactly the failure the paragraph above claims to be correct by
      # construction against; the construction was filtering a path git had already hidden.
      #
      # Latent wherever the journal IS gitignored, which is every repo that ran `setup.sh` —
      # and live for precisely the adopter that guard was written to protect.
      dirty="$(git status --porcelain -uall 2>/dev/null \
               | grep -v 'ai/SESSION_JOURNAL\.md' \
               | grep -v '\.session-journal-state')"
      changed="$(printf '%s' "$dirty" | grep -c . | tr -d ' ')"
      newcommits=""
      if [ -n "$last" ] && [ -n "$now" ] && [ "$last" != "$now" ]; then
        newcommits="$(git log --oneline "$last..$now" 2>/dev/null | sed 's/^/    - /')"
        printf '%s\n' "$now" > "$STATE"
      fi
      if [ -z "$newcommits" ] && [ "$changed" = "0" ]; then
        exit 0
      fi
      {
        printf -- '- %s — %s uncommitted file(s)\n' "$stamp" "$changed"
        if [ -n "$newcommits" ]; then
          printf '  committed:\n'
          printf '%s\n' "$newcommits"
        fi
        # Name the files so a dead session still says WHAT was being worked on.
        printf '%s\n' "$dirty" | grep . | head -8 | sed 's/^/    /'
      } >> "$JOURNAL"
      ;;

    commit)
      # ---- THE ONE EVENT EVERY TOOL PRODUCES (#279) ----------------------------------
      #
      # Called from .githooks/post-commit, which git runs for Cursor, Codex, a plain
      # terminal and anything else. Every other entry point here is a Claude Code
      # lifecycle hook, so without this the journal is empty for most of the world.
      #
      # NOT `checkpoint`. checkpoint compares HEAD against the state file and exits 0 when
      # they match -- and on a machine where no session hook has ever run there IS no state
      # file, so `last` is empty, `newcommits` is empty, the tree is clean immediately after
      # a commit, and it records nothing. Tried it: two commits, an empty journal. This mode
      # records the commit it was called for, which is a fact it does not have to infer, and
      # seeds the state file so a later checkpoint has a floor to compare against.
      now="$(git rev-parse HEAD 2>/dev/null || echo '')"
      [ -n "$now" ] || exit 0
      subject="$(git log -1 --format='%h %s' 2>/dev/null || echo '')"
      {
        printf -- '- %s — committed\n' "$stamp"
        printf '  committed:\n'
        printf '    - %s\n' "$subject"
      } >> "$JOURNAL"
      printf '%s\n' "$now" > "$STATE"
      ;;

    end)
      printf '## Session ended %s\n' "$stamp" >> "$JOURNAL"
      printf '[journal] session recorded in ai/SESSION_JOURNAL.md — distil into ai/SESSION.md\n'
      ;;
  esac
} 2>/dev/null || true
exit 0
