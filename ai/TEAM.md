<!-- scaffold:ai-file-kind template -->
# Team Roster and Ownership

_Updated when team membership or ownership changes._
_AI tools read this to know who owns what and who to involve in decisions._

---

## Team members

| Name | Role | AI tool | GitHub handle | Contact |
|------|------|---------|---------------|---------|
| [Your Name] | [Role] | [AI tools] | [@handle] | |

_When initializing a new project from this scaffold, update this table_
_with the actual team for that project. setup.sh seeds the first row._

---

## Project ownership

_Who is responsible for what. "Owner" means the person whose judgment
is final on decisions in that area, and who reviews PRs touching it._

| Area | Owner | Notes |
|------|-------|-------|
| [Area or component] | [Name] | |

---

## Working agreements

These are the rules this team has agreed to follow when collaborating.
Update here when new agreements are made — not just in conversation.

- Never commit directly to `main` — always branch and PR
- Use merge-only to keep branches current — never rebase against main
- Merge main into your branch (not rebase) when main moves ahead of you
- SESSION.md and BACKLOG.md must be updated before closing any session
- MEMORY.md conflicts must be resolved by the project owner — do not auto-merge
- Tag all releases before merging to main
- Notify the team (or document in SESSION.md) before making changes to
  shared standards files (`ai/CODING.md`, `ai/SECURITY.md`, `ai/STANDARDS.md`)
- Run `sync-check.sh` before starting work on any machine

---

## Escalation

If a standards conflict arises between two tools or teammates, document it in
SESSION.md immediately and flag the project owner. Do not resolve standards
conflicts unilaterally — they affect every tool and every project.
