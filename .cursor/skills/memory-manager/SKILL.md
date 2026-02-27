---
name: memory-manager
description: Manages shared memory between AI team specialists across sessions using a two-layer system: Beads (bd) for task/work-item tracking with dependency graphs, and memory/ markdown files for project knowledge, decisions, and specialist handoffs. Use at the start of any session to load context, and at the end to persist outputs. Use when starting work on a project, switching between specialists, resuming interrupted work, or checking what tasks are ready to work on.
---

# Memory Manager

Two layers of memory — each solving a different problem:

| Layer | Tool | Answers |
|---|---|---|
| **Task tracking** | `bd` ([Beads](https://github.com/steveyegge/beads)) | What should I work on? What's blocked? What's done? |
| **Knowledge store** | `memory/` markdown files | What did the PM decide? What did the explorer find? What design tokens were chosen? |

Use both. They don't overlap.

## Setup (one time per project)

```bash
just memory-init          # scaffolds memory/ files + runs bd init
```

Or separately:
```bash
bd init                   # Beads task graph (requires: bun install -g @beads/bd)
just memory-init --no-bd  # memory/ files only, skip Beads
```

---

## Layer 1 — Task Tracking with Beads (`bd`)

Use Beads for all work items: features, bugs, sub-tasks, spikes. Its dependency graph tells the team exactly what's unblocked and ready to implement.

### Essential commands

```bash
bd ready --json                         # Unblocked tasks — always use --json for programmatic use
bd create "Title" -p 1                  # Create a task (P0=critical … P3=low)
bd update <id> --claim                  # Atomically claim (sets assignee + in_progress)
bd dep add <child> <parent>             # Block child until parent done
bd dep add <found> <source> --type discovered-from  # Link work discovered during another task
bd show <id> --json                     # Full task details + audit trail
bd list --status in_progress --json     # What's in flight
bd update <id> --status done            # Mark complete
```

**Always use `--json` when parsing output programmatically.** Plain-text format is for humans only.

### Hierarchy

```
bd-a3f8          ← Epic (e.g., "User authentication")
bd-a3f8.1        ← Task (e.g., "Implement JWT login endpoint")
bd-a3f8.1.1      ← Sub-task (e.g., "Write unit tests for token validation")
```

### Who creates tasks

| Specialist | Creates tasks for |
|---|---|
| `product-manager` | Top-level epics and feature tasks from the PRD |
| `staff-test-engineer` | Test strategy tasks, quality gate verification tasks |
| `test-automation-architect` | Framework setup and CI configuration tasks |
| `exploratory-test-engineer` | Discovery tasks; creates specialist work items from findings |
| All others | Sub-tasks under their area; bug tasks from findings |

### Session workflow with Beads

```bash
# Session start — never skip this
bd ready --json            # see what's unblocked; --json for reliable parsing
bd update <id> --claim     # claim before touching any code

# Session end
bd update <id> --status done                              # mark complete
bd create "Discovered: ..." -p N                          # any follow-up work found
bd dep add <new-id> <done-id> --type discovered-from     # always link discovered work
```

### Storing planning output

AI-generated docs (PRD drafts, session notes, exploration output, spike results) go in `history/`:
```
history/YYYY-MM-DD-<description>.md
```

Never drop planning docs in the repo root. Never create markdown TODO lists — everything trackable goes in `bd`.

### AGENTS.md (add to project root)

```markdown
## Task Tracking — Beads (bd)
- ONLY use bd for task tracking. No GitHub Issues, Jira, markdown TODO lists.
- bd ready --json        start here every session — shows unblocked tasks
- bd update <id> --claim     claim before starting work
- bd update <id> --status done   mark complete when done
- bd dep add <new> <source> --type discovered-from   link all discovered work
- Planning docs → history/YYYY-MM-DD-<desc>.md  (never in repo root)
```

---

## Layer 2 — Knowledge Store (`memory/` files)

Beads tracks *what work exists*. `memory/` files capture *what was learned and decided* — context that doesn't fit in a task title.

### Directory structure

```
memory/
├── CONTEXT.md          # Project overview — read this first, always
├── decisions.md        # Append-only decision log (newest first)
├── handoffs.md         # Latest output from each specialist (one section each)
└── open-questions.md   # Cross-team questions and blockers
```

---

## Session Start Protocol

**Every specialist must run this at the start of a session** before producing any output:

```
1. bd ready
   → See unblocked tasks; claim the one you're working on with: bd update <id> --claim

2. Read memory/CONTEXT.md
   → Understand what's being built, current phase, tech stack, last activity

3. Read memory/handoffs.md → [your predecessor's section(s)]
   → Know what was already decided and handed to you (see Read Map below)

4. Read memory/open-questions.md
   → Check for open questions assigned to you; resolve or acknowledge them

5. Skim memory/decisions.md (last 5 entries)
   → Catch any recent decisions that affect your work
```

If `memory/` does not exist: ask the user to run `just memory-init`.
If `bd` is not found: run `bun install -g @beads/bd && bd init`.

---

## Session End Protocol

**Every specialist must run this before ending a session:**

```
1. bd update <id> --status done
   → Mark your claimed task complete

2. bd create "..." -p N (repeat for each follow-up)
   → Create tasks for work discovered this session; link deps with: bd dep add <new> <current>

3. Update memory/handoffs.md → your section
   → Replace your section with a concise summary of what you produced this session
   → Include: what you decided, what you built, what you're handing off, and any blockers

4. Append to memory/decisions.md
   → Any key decision made this session (architecture, trade-off, scope change)

5. Update memory/open-questions.md
   → Add new questions; mark resolved questions [RESOLVED: answer]

6. Update memory/CONTEXT.md → "Last activity" line only
   → Update the phase/status if it changed; don't rewrite the whole file
```

---

## Read Map — Who Reads Whom

| Specialist | Read from handoffs.md |
|---|---|
| `product-manager` | _(first in chain — reads CONTEXT only)_ |
| `ui-ux-designer` | `pm` section |
| `exploratory-test-engineer` | `pm`, `designer` sections |
| `staff-test-engineer` | `pm`, `designer`, `explorer` sections |
| `test-automation-architect` | `staff`, `explorer` sections |
| `devops-engineer` | `architect`, `staff` sections |
| `backend-python` | `staff`, `architect` sections |
| `api-contract-test-engineer` | `explorer`, `architect` sections |
| `security-test-engineer` | `explorer`, `architect` sections |
| `performance-stress-test-engineer` | `explorer`, `architect` sections |
| `mobile-test-engineer` | `explorer`, `designer`, `architect` sections |
| `junior-test-engineer` | `staff`, `architect`, `explorer` sections |

---

## memory/CONTEXT.md

```markdown
# Project Context

**Project**: [name]
**Repo**: [url or path]
**Description**: [1–2 sentences on what this is]
**Tech stack**: [e.g., FastAPI + React + PostgreSQL + Cloudflare Workers]
**Current phase**: [Discovery | Design | Implementation | Testing | Launch]
**Last activity**: [YYYY-MM-DD] — [specialist] — [1-line summary]

## Goals
- [Primary goal]
- [Secondary goal]

## Key Architecture Decisions
- [Decision 1]
- [Decision 2]

## Current Sprint / Focus
[What the team is actively working on right now]

## Out of Scope
- [What is explicitly not being built]
```

---

## memory/handoffs.md

One section per specialist. **Replace your section entirely each session** — always current, never stale.

```markdown
# Team Handoffs

<!-- Each section: replace entirely each session. Date = last updated. -->

## PM (last updated: YYYY-MM-DD)
**Feature**: [name]
**Problem**: [1 sentence]
**PRD status**: [Draft | Approved | Link]
**Acceptance criteria**: [key Given/When/Then or link to full PRD]
**Success metric**: [primary metric + target]
**Key decisions**: [list]
**Handoff to Designer**: [what designer needs to know]
**Handoff to QA**: [scope, risk areas, NFRs]
**Open questions**: [list any blockers]

---

## Designer (last updated: YYYY-MM-DD)
**Flows designed**: [list of user flows]
**Components**: [list of new/modified components]
**Design tokens**: [changed or new tokens]
**Accessibility notes**: [key a11y requirements for eng]
**Handoff to Engineering**: [spec location or summary]
**Handoff to QA**: [visual test scope, a11y checks, breakpoints]
**Open questions**: [list]

---

## Explorer (last updated: YYYY-MM-DD)
**Areas mapped**: [list]
**Feature count**: [N features found]
**Risk flags**: [top risks by severity]
**Feature map**: [inline or link]
**Handoff packages sent to**: [list of specialists]
**Open questions**: [list]

---

## Staff (last updated: YYYY-MM-DD)
**Test strategy status**: [Draft | Final]
**Risk areas**: [top 3]
**Quality gates**: [list]
**Coverage targets**: [per layer]
**Open questions**: [list]

---

## Architect (last updated: YYYY-MM-DD)
**Framework status**: [Stable | In setup | Needs update]
**New abstractions added**: [list]
**CI stages**: [current pipeline stages]
**Shared fixtures/helpers**: [list]
**Open questions**: [list]

---

## DevOps (last updated: YYYY-MM-DD)
**Pipeline status**: [Stable | In progress]
**Environments**: [dev | staging | prod status]
**IaC changes**: [list]
**Monitoring**: [what's instrumented]
**Open questions**: [list]

---

## Backend Python (last updated: YYYY-MM-DD)
**Endpoints implemented**: [list]
**Schema changes**: [Pydantic models, DB migrations]
**Test coverage**: [%]
**Known issues**: [list]
**Open questions**: [list]

---

## API / Contract (last updated: YYYY-MM-DD)
**Endpoints tested**: [list]
**Contract tests**: [provider/consumer status]
**Gaps**: [untested endpoints or scenarios]
**Open questions**: [list]

---

## Security (last updated: YYYY-MM-DD)
**OWASP checks completed**: [list]
**Findings**: [severity + status per finding]
**Scan results**: [SAST/DAST summary]
**Open questions**: [list]

---

## Performance (last updated: YYYY-MM-DD)
**Scenarios run**: [list]
**SLO status**: [pass/fail per SLO]
**Bottlenecks found**: [list]
**Baseline established**: [yes/no]
**Open questions**: [list]

---

## Mobile (last updated: YYYY-MM-DD)
**Platforms tested**: [iOS / Android / both]
**Automation coverage**: [% of flows]
**Device strategy**: [emulators + real devices status]
**Open questions**: [list]

---

## Junior (last updated: YYYY-MM-DD)
**Tests implemented**: [count by type]
**Tests passing**: [count]
**Flaky tests quarantined**: [list]
**Bugs filed**: [count + severity breakdown]
**Open questions**: [list]
```

---

## memory/decisions.md

```markdown
# Decision Log

<!-- Append-only. Newest entries at the top. -->

## [YYYY-MM-DD] [Specialist]: [Decision title]
**Decision**: [What was decided]
**Rationale**: [Why — what drove the choice]
**Alternatives rejected**: [What wasn't chosen and why]
**Impact**: [Who / what this affects]
**Revisit trigger**: [Condition under which this should be reconsidered]

---
```

---

## memory/open-questions.md

```markdown
# Open Questions

| # | Question | Owner | Raised by | Date | Status |
|---|---|---|---|---|---|
| 1 | [question] | [specialist or person] | [who raised it] | YYYY-MM-DD | Open |
| 2 | [question] | [owner] | [raiser] | YYYY-MM-DD | [RESOLVED: answer] |
```

---

## Anti-Patterns

| Don't | Do instead |
|---|---|
| Track tasks in memory/handoffs.md | Tasks go in Beads (`bd create`); handoffs.md is for knowledge |
| Track decisions/context in Beads | Decisions go in memory/decisions.md; Beads tracks work items |
| Create markdown TODO lists | Everything trackable goes in `bd` |
| Use GitHub Issues or Jira alongside `bd` | One system only — `bd` |
| Drop planning docs in the repo root | Use `history/YYYY-MM-DD-<desc>.md` |
| Parse `bd` output without `--json` | Always `bd ready --json` for programmatic use |
| Create follow-up tasks without linking them | Always `bd dep add <new> <source> --type discovered-from` |
| Start without `bd ready` | Always see what's unblocked before picking up work |
| Start without reading CONTEXT.md | Always read it first |
| Append to handoffs.md instead of replacing your section | Replace your section entirely; it should always be current |
| Write verbose dumps into handoffs.md | Keep each section to 10–15 lines max; link to full docs |
| Leave open questions unresolved for multiple sessions | Resolve or escalate within 1 session |
| Skip writing memory at session end because "it's a small change" | Every session end writes memory and updates Beads |

## Additional Resources

- File templates: [templates/](templates/)
- Beads documentation: [github.com/steveyegge/beads](https://github.com/steveyegge/beads)
- Team standards: [team-standards.md](../qa-team-orchestrator/team-standards.md)
