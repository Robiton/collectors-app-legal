#!/usr/bin/env bash
# Project:  ai-project-scaffold
# File:     tools/lint_python.sh
# Modified: 2026-08-10
# Version:  0.2.0.20260810.0010
# Purpose:  Lint the scaffold's own Python at a pinned ruff — ONE definition, run by CI and locally.
# Changelog:
#   2026-08-10 v0.2.0 — Could-not-run is exit 3, not 2 (#188). Both paths: no runner,
#                        and no git to list files from. This tool had the right idea first
#                        and the wrong number — 2 meant usage error elsewhere in the
#                        toolchain, so no caller could act on it.
#   2026-08-09 v0.1.1 — No code change. Re-stamped: this file shipped at mode 644, so its
#                        suite did not run at all on the pull request that introduced it —
#                        the exact defect tools/mode_scan.sh now catches locally.
#   2026-08-09 v0.1.0 — New, extracted from .github/workflows/scaffold-check.yml (#166).
#                        The rule was ~40 lines of shell inside a `run:` block, which means
#                        it could only ever run in CI: an adopter who wanted to know whether
#                        their push would be linted had to read YAML and retype the command,
#                        pin included. Two people did that and got two answers, because the
#                        PIN IS THE LOAD-BEARING PART — this repo's tools produce 8 findings
#                        under the declared E4,E7,E9,F set and 66 under ruff 0.16.1's own
#                        defaults, so an unpinned local run disagrees with the build in the
#                        direction that reads as "my code is fine".
#                        As a file it is linted, it has a selftest, and CI's discovery loops
#                        pick it up with no edit to the workflow. The workflow now calls it.
#                        A LOCAL RUNNER IS RESOLVED RATHER THAN REQUIRED. CI has pipx; a Mac
#                        usually has uv and not pipx, and `pipx run` was the only spelling,
#                        so "run the linter before pushing" was unavailable to the machine
#                        the code is written on. A system `ruff` is used ONLY when its
#                        version equals the pin — a different ruff is a different gate, and
#                        answering with it would be the drift this file exists to remove.
#                        EXIT 3 IS "DID NOT RUN", DISTINCT FROM EXIT 1 "FOUND SOMETHING" (#188).
#                        It was exit 2 until 2026-08-10; 2 is the usage-error code
#                        everywhere else in this toolchain, and one number cannot
#                        mean both "you typed it wrong" and "I checked nothing".
#                        Collapsing them would let a machine with no runner report a clean
#                        lint, which is the failure this project keeps finding in itself.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# THE PIN AND THE RULE SET ARE DECLARED HERE, AND THIS IS NOW THE ONLY COPY.
#
# ruff's DEFAULT selection is not stable across releases, so `ruff check` unpinned goes from
# green to dozens of failures on a ruff release, in code nobody touched. Widening SELECT is a
# deliberate PR with the findings fixed in the same change — never a side effect of a bump.
RUFF_PIN="0.16.1"
RUFF_SELECT="E4,E7,E9,F"
RUFF_LINE_LENGTH="100"

# THE SCOPE STOPS AT CODE THE ADOPTER DID NOT WRITE, AND THAT IS THE POINT.
#
# scaffold_upgrade.sh force-installs tools/, so an adopting project's tools/ holds our files
# AND theirs — it states plainly that "adopter-added files under these directories are never
# deleted". Linting theirs would fail their build on a ruff version and a rule set the
# scaffold chose for them: that is #76, and it contradicts the argument two files away, where
# `formatters.python.expect` ships EMPTY because a guessed version fails every adopter whose
# toolchain differs. Demonstrated before this scoping existed: an adopter's tools/my_helper.py
# failed their build on E401+E731 in code we never wrote.
#
# THE FILE SAYS WHO OWNS IT, SO ASK THE FILE. Every source file carries a `# Project:` header
# (header_check.sh makes it mandatory) and a vendored copy keeps the scaffold's name because
# it is copied verbatim. So "did we write this?" has an answer in the file itself and there is
# no list to maintain. In this repo everything says ai-project-scaffold and everything is
# linted; in an adoption their eval_tasks.py and their own helpers drop out by saying theirs.
#
# EXTENSIONLESS PYTHON IS THE CASE THAT WAS MISSED. The first version of this rule listed
# `tools/*.py ai/*.py`, which skipped `tools/localcoder` — 1,900 lines of Python with no
# extension, and the actual product. The largest Python file in the repo was the one the new
# linter could not see.
#
# bash 3.2 — still the system bash on macOS — cannot parse a `case` inside `$(...)`, so the
# tests below are `if`/`elif`. CI runs bash 5 and would not have caught it.
OWNER_RE='^#[[:space:]]*Project:[[:space:]]*ai-project-scaffold[[:space:]]*$'

discover() {
  git -C "$ROOT" ls-files tools ai 2>/dev/null | while read -r f; do
    [ -f "$ROOT/$f" ] || continue
    ispy=0
    if [ "${f##*.}" = "py" ]; then
      ispy=1
    elif head -1 "$ROOT/$f" 2>/dev/null | grep -q '^#!.*python'; then
      ispy=1
    fi
    if [ "$ispy" = "1" ] && head -8 "$ROOT/$f" | grep -qE "$OWNER_RE"; then
      echo "$f"
    fi
  done
}

# Resolve a runner that gives EXACTLY the pinned ruff, and say which one was used.
# Prints the command on stdout; empty means none is available.
runner() {
  if command -v pipx >/dev/null 2>&1; then
    echo "pipx run ruff==$RUFF_PIN"
    return
  fi
  if command -v uvx >/dev/null 2>&1; then
    echo "uvx ruff@$RUFF_PIN"
    return
  fi
  # A system ruff counts ONLY at the pinned version. `ruff --version` prints "ruff 0.16.1".
  if command -v ruff >/dev/null 2>&1; then
    have="$(ruff --version 2>/dev/null | awk '{print $2}')"
    if [ "$have" = "$RUFF_PIN" ]; then
      echo "ruff"
      return
    fi
  fi
  echo ""
}

lint() {
  local files cmd
  # "NOTHING TO LINT" AND "COULD NOT ASK" ARE DIFFERENT ANSWERS, and discovery collapses
  # them: `git ls-files` prints nothing both when the tree holds no Python and when git is
  # absent or this is not a repository. Found by the no-runner selftest case below, which
  # emptied PATH and got a clean pass out of a machine that could not run anything at all.
  if ! git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    echo "lint_python: DID NOT RUN — not a git repository, or git is unavailable."
    echo "  The file list comes from 'git ls-files', so there is nothing to lint FROM."
    echo "  This is exit 3: NOT a pass. Nothing was examined."
    return 3
  fi
  files="$(discover)"
  if [ -z "$files" ]; then
    echo "lint_python: no scaffold-owned Python found under tools/ or ai/."
    echo "  That is correct for a project that ships none, and WRONG here if tools/ exists."
    return 0
  fi
  cmd="$(runner)"
  if [ -z "$cmd" ]; then
    echo "lint_python: DID NOT RUN — no way to reach ruff $RUFF_PIN on this machine."
    echo "  Install one of: pipx, uv (provides uvx), or ruff $RUFF_PIN exactly."
    echo "  A different ruff is a different gate and will not be used in its place."
    echo "  This is exit 3: NOT a pass. Nothing was examined."
    return 3
  fi
  echo "lint_python: $cmd  (--select $RUFF_SELECT, --line-length $RUFF_LINE_LENGTH)"
  printf '%s\n' "$files" | sed 's/^/  /'
  # shellcheck disable=SC2086
  ( cd "$ROOT" && printf '%s\n' "$files" | xargs $cmd check \
      --line-length "$RUFF_LINE_LENGTH" --isolated --select "$RUFF_SELECT" )
}

selftest() {
  local pass=0 fail=0 skip=0 tmp
  echo "lint_python selftest — the scope is the rule, so the scope is what is tested"
  case_ok()   { echo "  ok    $1"; pass=$((pass + 1)); }
  case_bad()  { echo "  FAIL  $1"; fail=$((fail + 1)); }
  case_skip() { echo "  skip  $1"; skip=$((skip + 1)); }

  # 1. The pin is a real version, not a floating spec. An unpinned gate drifts on someone
  #    else's release schedule, which is the whole argument for this file.
  if echo "$RUFF_PIN" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    case_ok "the ruff version is pinned exactly ($RUFF_PIN)"
  else
    case_bad "RUFF_PIN is not an exact version: '$RUFF_PIN'"
  fi

  # 2..6 run in a throwaway git repo, because discovery reads `git ls-files` and an
  #      UNTRACKED file must not be lintable — CI lints what is committed.
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/lintpy.XXXXXX")"
  mkdir -p "$tmp/tools" "$tmp/ai"
  cp "${BASH_SOURCE[0]}" "$tmp/tools/lint_python.sh"
  chmod +x "$tmp/tools/lint_python.sh"
  printf '#!/usr/bin/env python3\n# Project:  ai-project-scaffold\nx = 1\n' > "$tmp/tools/noext"
  printf '# Project:  ai-project-scaffold\ny = 1\n' > "$tmp/tools/ours.py"
  printf '# Project:  someone-else\nz = 1\n' > "$tmp/tools/theirs.py"
  printf '# Project:  ai-project-scaffold\n\nnot python\n' > "$tmp/tools/README.md"
  printf '# Project:  ai-project-scaffold\nq = 1\n' > "$tmp/tools/untracked.py"
  ( cd "$tmp" && git init -q . && git add tools/noext tools/ours.py tools/theirs.py \
      tools/README.md tools/lint_python.sh ) >/dev/null 2>&1

  local list
  list="$("$tmp/tools/lint_python.sh" --list 2>/dev/null)"

  if printf '%s\n' "$list" | grep -qx 'tools/noext'; then
    case_ok "an extensionless file with a python shebang is linted"
  else
    case_bad "extensionless python was missed — the defect this discovery exists for"
  fi
  if printf '%s\n' "$list" | grep -qx 'tools/ours.py'; then
    case_ok "a .py we own is linted with no shebang needed"
  else
    case_bad "tools/ours.py was not discovered"
  fi
  if printf '%s\n' "$list" | grep -qx 'tools/theirs.py'; then
    case_bad "an adopter's own .py was linted — that is #76"
  else
    case_ok "a .py whose Project: names someone else is left alone"
  fi
  if printf '%s\n' "$list" | grep -qx 'tools/README.md'; then
    case_bad "a non-python file with our header was sent to ruff"
  else
    case_ok "a non-python file with our header is not linted"
  fi
  if printf '%s\n' "$list" | grep -qx 'tools/untracked.py'; then
    case_bad "an untracked file was linted — CI lints what is committed"
  else
    case_ok "an untracked file is not linted"
  fi

  # 7. A real finding must exit 1. SKIPPED, NOT PASSED, when no runner is reachable —
  #    a suite that quietly drops its only end-to-end case is the failure mode this
  #    project keeps finding, and a skip has to look different from a pass.
  if [ -n "$(runner)" ]; then
    printf '# Project:  ai-project-scaffold\nimport os, sys\n' > "$tmp/ai/bad.py"
    ( cd "$tmp" && git add ai/bad.py ) >/dev/null 2>&1
    if "$tmp/tools/lint_python.sh" >/dev/null 2>&1; then
      case_bad "E401 in a scaffold-owned file did not fail the lint"
    else
      case_ok "a real finding exits non-zero"
    fi
    ( cd "$tmp" && git rm -q --cached ai/bad.py ) >/dev/null 2>&1
    rm -f "$tmp/ai/bad.py"
  else
    case_skip "no ruff runner here — the end-to-end finding case DID NOT RUN"
  fi

  # 8. No runner must be exit 3 ("did not run"), never 0. The resolution order is exercised
  #    for real rather than mocked behind a flag — but the FIRST version of this case was an
  #    invalid setup that proved nothing, which is the trap #166 was filed about. It set
  #    PATH=/nonexistent, so `#!/usr/bin/env bash` could not find bash and the script never
  #    started; the 127 that came back read as "correctly refused". So PATH here is a real
  #    working environment with EXACTLY the three runners removed.
  #    AND IT ASSERTS THE MESSAGE, NOT ONLY THE CODE. The second version of this case was
  #    ALSO invalid: `dirname` was missing from the stripped PATH, so ROOT resolved to
  #    nonsense, the git probe failed and the 2 came back from "not a git repository". It
  #    reported ok against a defect that made runner() claim ruff was present — the case had
  #    never once reached the code it names. Two exits of 2 with different causes are two
  #    different answers, so the reason is checked as well.
  mkdir -p "$tmp/bin"
  local need src out2 rc=0
  for need in bash sh env git dirname basename pwd head grep sed awk xargs printf cat; do
    src="$(command -v "$need" 2>/dev/null || true)"
    [ -n "$src" ] && ln -sf "$src" "$tmp/bin/$need"
  done
  if [ -x "$tmp/bin/bash" ] && [ -x "$tmp/bin/git" ] && [ -x "$tmp/bin/dirname" ]; then
    out2="$( PATH="$tmp/bin" "$tmp/tools/lint_python.sh" 2>&1 )" || rc=$?
    if [ "$rc" -eq 3 ] && printf '%s' "$out2" | grep -q 'no way to reach ruff'; then
      case_ok "a machine with no pipx/uvx/ruff exits 3 (verified nothing), never 0"
    elif [ "$rc" -eq 2 ]; then
      case_bad "exit 3 expected; got $rc, or for another reason — never reached runner(): $(
                printf '%s' "$out2" | head -1)"
    else
      case_bad "no reachable ruff reported '$rc' instead of 2 (did not run)"
    fi
  else
    case_skip "could not build a runner-free PATH — the 'did not run' case DID NOT RUN"
  fi

  rm -rf "$tmp"
  echo "  $pass passed, $fail failed, $skip skipped"
  [ "$fail" -eq 0 ]
}

case "${1:-}" in
  --list)     discover ;;
  --pin)      echo "ruff==$RUFF_PIN --select $RUFF_SELECT --line-length $RUFF_LINE_LENGTH" ;;
  --selftest) selftest ;;
  "")         lint ;;
  *)          echo "usage: lint_python.sh [--list | --pin | --selftest]" >&2; exit 2 ;;
esac
