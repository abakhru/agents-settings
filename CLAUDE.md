# Global Claude Rules

> Applies to every repo. Repo-level `CLAUDE.md` overrides on conflict.

---

## Session Protocol

### START (every session)
1. If `memory/` or `.beads` missing → `ai memory-init`
2. `bd ready --json` + `bd list --status in_progress --json`
3. Read: `memory/CONTEXT.md` → your predecessor's section in `memory/handoffs.md` → skim `open-questions.md` → last 5 entries in `decisions.md`

### END (every session — no exceptions)
1. File `bd` tasks for remaining work; run quality gates
2. `bd update <id> --status done`; add follow-ups via `bd dep add`
3. `git pull --rebase && bd sync && git push` — **work is not done until pushed**
4. Update `memory/handoffs.md` (your section, ≤15 lines), append `decisions.md`, update `open-questions.md` and `CONTEXT.md` last-activity line

**NEVER say "ready to push when you are." You must push.**

---

## Beads (Task Tracker)

```bash
bd ready --json                          # always start here
bd list --status in_progress --json      # check claimed tasks
bd create "Title" -p 1 --description "Recommended Agent: <name>\n..."
bd update <id> --claim
bd update <id> --status done
bd dep add <child> <parent>
bd dep add <found> <source> --type discovered-from
bd sync                                  # required before every git push
```

**Rules:** Always `--json` for programmatic output · Every task description must include `Recommended Agent: <name>` · Claim format: `[Claimed by <agent> at <timestamp>]` · 10-min takeover rule · No markdown TODOs · No external trackers · Planning docs go in `history/`

---

## Agent Team

### Activation
| Agent | When to use |
|---|---|
| `qa-team-orchestrator` | Broad "what needs testing?" or feature-level requests — **use first** |
| `product-manager` | PRDs, feature definitions, success metrics |
| `ui-ux-designer` | User flows, component specs, design tokens, a11y |
| `exploratory-test-engineer` | Unknown app/feature — map before others work |
| `staff-test-engineer` | Test strategy, risk prioritization, quality gates, testability |
| `test-automation-architect` | Framework setup, shared abstractions, CI/CD test integration |
| `devops-engineer` | CI/CD, IaC, Docker/K8s, environments, observability |
| `backend-python` | FastAPI, SQLAlchemy 2.0, Pydantic v2, uv, async |
| `junior-test-engineer` | Writing tests from specs, fixing flaky tests, bug reports |
| `api-contract-test-engineer` | REST/GraphQL tests, Pact contracts, mocking strategy |
| `security-test-engineer` | OWASP, auth/authz, scan triage |
| `performance-stress-test-engineer` | Load/stress/spike/soak, k6, capacity planning |
| `mobile-test-engineer` | iOS/Android automation, Appium, device strategy |
| `memory-manager` | Cross-session knowledge, handoffs, decisions |

### Default Sequence
```
PM → Designer → Explorer → DevOps → Architect → Staff
  → Backend + API + Security + Perf + Mobile (parallel)
  → Junior → Staff (final review)
```
Skip any step whose output already exists.

### Memory Read Map
| Agent | Read from `handoffs.md` |
|---|---|
| `product-manager` | CONTEXT.md only |
| `ui-ux-designer` | pm |
| `exploratory-test-engineer` | pm, designer |
| `staff-test-engineer` | pm, designer, explorer |
| `test-automation-architect` | staff, explorer |
| `devops-engineer` | architect, staff |
| `backend-python` | staff, architect |
| `api-contract-test-engineer` | explorer, architect |
| `security-test-engineer` | explorer, architect |
| `performance-stress-test-engineer` | explorer, architect |
| `mobile-test-engineer` | explorer, designer, architect |
| `junior-test-engineer` | staff, architect, explorer |

---

## Standards

### Toolchain
| Purpose | Tool | Never use |
|---|---|---|
| Python packages | `uv` | pip, poetry |
| Python lint | `ruff` (line-length=120, double quotes) | — |
| Python types | `ty` (Astral) | — |
| JS/TS packages | `bun` | npm, yarn, pnpm |
| Web UI | `vinext` (Cloudflare Next.js on Vite) | — |
| Task runner | `just` (CI calls `just <target>`) | make |
| Tool versions | `mise.toml` at repo root | — |
| Search | `rg` | grep |
| Web E2E | `stagehand` | — |
| Performance | `k6` | — |
| Contract | Pact | — |
| Security SAST | Semgrep | — |
| Security DAST | OWASP ZAP (staging only) | — |
| Dependency scan | `osv-scanner` (CRITICAL = blocks merge) | — |
| Image scan | `trivy` (HIGH/CRITICAL = fails CI) | — |

### Code & Test Rules
- Minimal code · DRY · atomic & independent tests · clean up in tearDown
- Integration tests: real services via testcontainers/Compose — mocks in unit tests only
- Docker: `--mount=type=cache` for all package layers
- UI tests: `video/screenshot/trace: retain-on-failure` · produce UI Fix Suggestion before filing a bug
- Git commits: short, imperative, ≤72 chars · **strip all AI footers** (Claude Code, Cursor, Co-authored-by)

### Coverage Targets
| Layer | Target |
|---|---|
| Unit | ≥ 80% |
| Integration | 100% on critical paths |
| E2E | All P0 user journeys |
| Contract | All service boundaries |

### Severity
| Level | Definition |
|---|---|
| P0 | Outage or security breach |
| P1 | Major user impact, no workaround |
| P2 | Workaround exists |
| P3 | Cosmetic |