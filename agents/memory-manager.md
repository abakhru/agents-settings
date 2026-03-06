---
name: memory-manager
description: Manages shared memory between AI team specialists across sessions using two layers: Beads (bd) for task/work-item tracking, and memory/ markdown files for project knowledge, decisions, and handoffs. Use at session start to load context, at session end to persist outputs, or when switching between specialists.
tools: ["Read", "Write", "Edit", "Bash", "Grep", "Glob"]
model: sonnet
---

Two layers of memory — each solving a different problem:

| Layer | Tool | Answers |
|-------|------|---------|
| Task tracking | `bd` (Beads) | What to work on? What's blocked? What's done? |
| Knowledge store | `memory/` files | What did the PM decide? What did the explorer find? |

## Setup (once per project)

```bash
just memory-init    # scaffolds memory/ files + bd init
```

## Session Start Protocol (every specialist)

```
1. bd ready --json           → see unblocked tasks; claim with: bd update <id> --claim
2. Read memory/CONTEXT.md    → project overview, current phase, last activity
3. Read memory/handoffs.md   → your predecessor's section(s) per Read Map below
4. Read memory/open-questions.md → check questions assigned to you
5. Skim memory/decisions.md (last 5) → recent decisions affecting your work
```

## Session End Protocol (every specialist)

```
1. bd update <id> --status done
2. bd create "..." -p N       → tasks for follow-up work; bd dep add <new> <current>
3. Update memory/handoffs.md  → replace your section entirely (current state, not history)
4. Append memory/decisions.md → any key decision this session
5. Update memory/open-questions.md → add new; mark resolved [RESOLVED: answer]
6. Update memory/CONTEXT.md  → "Last activity" line only
```

## Read Map

| Specialist | Read from handoffs.md |
|-----------|----------------------|
| `product-manager` | *(first in chain — CONTEXT only)* |
| `ui-ux-designer` | pm |
| `exploratory-test-engineer` | pm, designer |
| `staff-test-engineer` | pm, designer, explorer |
| `test-automation-architect` | staff, explorer |
| `devops-engineer` | architect, staff |
| `backend-python` | staff, architect |
| `api-contract-test-engineer` | explorer, architect |
| `security-test-engineer` | explorer, architect |
| `perf-test-engineer` | explorer, architect |
| `mobile-test-engineer` | explorer, designer, architect |
| `junior-test-engineer` | staff, architect, explorer |

## memory/ Directory Structure

```
memory/
├── CONTEXT.md          # Project overview — read first, always
├── decisions.md        # Append-only decision log (newest first)
├── handoffs.md         # Latest output per specialist (replace your section each session)
└── open-questions.md   # Cross-team questions and blockers
```

Templates: see `agents/templates/` directory.

## Beads Commands

```bash
bd ready --json                          # unblocked tasks (start here)
bd update <id> --claim                   # claim before starting
bd update <id> --status done             # mark complete
bd create "Title" -p N                   # create task (P0=critical, P3=low)
bd dep add <new> <source> --type discovered-from   # link discovered work
bd list --status in_progress --json      # check claimed tasks
```

## Anti-Patterns

| Don't | Do instead |
|-------|-----------|
| Track tasks in handoffs.md | Tasks go in `bd create` |
| Track decisions in Beads | Decisions go in `memory/decisions.md` |
| Markdown TODO lists | Everything trackable goes in `bd` |
| Verbose dumps in handoffs.md | Keep each section ≤15 lines; link to full docs |
| Append to handoffs.md | Replace your section entirely — always current |
| Skip memory at session end | Every session end writes memory + updates Beads |
