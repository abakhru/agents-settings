# amit-claude

Personal AI agent skills and rules for Cursor and Claude CLI.

## Quickstart

```bash
# New machine — create all symlinks
just setup

# New project — initialize memory + task tracking
cd /path/to/project
just memory-init

# Discord notifications (optional)
cp config/discord.env.example config/discord.env  # fill in webhook URL
```

## Team

| Skill | When to use |
|---|---|
| `qa-team-orchestrator` | Start here for any broad request |
| `product-manager` | Feature definition, PRD, acceptance criteria |
| `ui-ux-designer` | User flows, component specs, design tokens, a11y |
| `exploratory-test-engineer` | Unknown app/feature — map it first |
| `staff-test-engineer` | Test strategy, risk, quality gates |
| `test-automation-architect` | Framework setup, CI integration |
| `devops-engineer` | CI/CD pipelines, Docker/K8s, infra |
| `backend-python` | FastAPI, SQLAlchemy, Pydantic, uv |
| `junior-test-engineer` | Test implementation, bug reports |
| `api-contract-test-engineer` | REST/GraphQL, Pact contracts |
| `security-test-engineer` | OWASP, auth/authz, scan triage |
| `performance-stress-test-engineer` | Load, stress, k6 |
| `mobile-test-engineer` | iOS/Android, Appium |
| `memory-manager` | Cross-session knowledge and handoffs |

## Usage

**Cursor** — skills and rules are live via symlink. Just prompt:
> "Use the QA team orchestrator to plan testing for the checkout feature."
> "Act as the security test engineer and review this auth flow."

**Claude CLI** — `~/.claude/CLAUDE.md` is a symlink to this repo. Team is always loaded:
```bash
claude "As the devops engineer, write a GitHub Actions pipeline for this service."
```

## justfile targets

```bash
just setup              # first-time machine setup (symlinks)
just status             # verify symlinks
just memory-init        # init memory/ + bd for a project
just memory-status      # show project memory status
just tasks              # unblocked bd tasks
just task "Title" [0-3] # create a task
just claim <id>         # claim a task
just done <id>          # mark complete
just notify "msg"       # Discord notification
just alert "msg"        # Discord alert
just discord-status     # check Discord config
```

## Structure

```
.cursor/
├── skills/   # agent skills (symlinked to ~/.cursor/skills)
└── rules/    # always-on coding rules (symlinked to ~/.cursor/rules)
CLAUDE.md     # Claude CLI global config (symlinked to ~/.claude/CLAUDE.md)
config/
└── discord.env.example
justfile
```
