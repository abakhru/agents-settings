# AI Agent Team

Specialized agents for the full product and quality lifecycle. For broad requests use the Orchestrator first.

---

## Session Protocol

### Start (always)
1. If `memory/` or `.beads` missing → `ai memory-init`
2. `bd ready --json` + `bd list --status in_progress --json` — see what's available and what's claimed
3. Read `memory/CONTEXT.md`, predecessor's section in `memory/handoffs.md`, skim `open-questions.md` and last 5 `decisions.md` entries

### End — Land the Plane (always)
1. File `bd` tasks for remaining work; run quality gates
2. `bd update <id> --status done`; create follow-up tasks with `bd dep add`
3. `git pull --rebase && bd sync && git push` — work is not done until pushed
4. Replace your section in `memory/handoffs.md` (≤15 lines); append to `decisions.md`; update `open-questions.md` and `CONTEXT.md` last-activity line

**NEVER** say "ready to push when you are" — you must push.

### Beads Commands
```bash
bd ready --json                                            # start here
bd list --status in_progress --json                        # check what's claimed
bd create "Title" -p 1 --description "Recommended Agent: <name>\n..."
bd update <id> --claim && bd update <id> --status done
bd dep add <child> <parent>
bd dep add <found> <source> --type discovered-from
bd sync                                                    # before git push
```

### Beads Rules
- `bd ready --json` before every session; `--json` for all programmatic output
- Every task description must include `Recommended Agent: <name>`
- Claim with `[Claimed by <agent> at <timestamp>]` in description; 10-min takeover rule applies
- `bd sync` before `git push`; no markdown TODOs; no external trackers; planning docs in `history/`

### Memory Read Map
| Specialist | Read from handoffs.md |
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

## Team

| Specialist | Activate when |
|---|---|
| `qa-team-orchestrator` | Any broad "what do we need to test?" or feature-level request |
| `product-manager` | Defining a feature, writing a PRD, prioritizing, defining success metrics |
| `ui-ux-designer` | User flows, component specs, design tokens, accessibility |
| `exploratory-test-engineer` | App/feature is unknown — map it before others can work |
| `staff-test-engineer` | Test strategy, risk prioritization, quality gates, testability review |
| `test-automation-architect` | Framework setup, shared abstractions, CI/CD test integration |
| `devops-engineer` | CI/CD pipelines, IaC, Docker/K8s, environments, observability |
| `backend-python` | FastAPI, SQLAlchemy 2.0, Pydantic v2, uv, async patterns |
| `junior-test-engineer` | Writing tests from specs, fixing flaky tests, bug reports |
| `api-contract-test-engineer` | REST/GraphQL tests, Pact contracts, mocking strategy |
| `security-test-engineer` | OWASP checklist, auth/authz, scan triage |
| `performance-stress-test-engineer` | Load/stress/spike/soak tests, k6, capacity planning |
| `mobile-test-engineer` | iOS/Android automation, Appium, device strategy |
| `memory-manager` | Cross-session knowledge, handoffs, decisions |

### Default Sequencing
PM → Designer → Explorer → DevOps → Architect → Staff → Backend+API+Security+Perf+Mobile (parallel) → Junior → Staff (final review)

Skip any step where the output already exists.

---

## Team Standards

### Tools
| Purpose | Tool |
|---|---|
| Python package manager | `uv` — never pip/poetry |
| Python linting | `ruff` (line-length=120, double quotes) |
| Python type checking | `ty` (Astral) |
| JS/TS package manager | `bun` — never npm/yarn/pnpm |
| Web UI framework | `vinext` (Cloudflare Next.js on Vite) |
| Task runner | `just` — CI calls `just <target>` |
| Tool versions | `mise.toml` at repo root |
| Web E2E | Playwright |
| Performance | k6 |
| Contract | Pact |
| Security SAST | Semgrep |
| Security DAST | OWASP ZAP (staging only) |
| Dependency scan | `osv-scanner` (CRITICAL blocks merge) |
| Image scan | `trivy` (HIGH/CRITICAL fails CI) |
| Search | `rg` — never grep |

### Key Rules
- Minimum code, DRY, atomic & independent tests, clean up in tearDown
- Integration tests use real services (testcontainers/Compose) — mocks only in unit tests
- Docker: `--mount=type=cache` for all package layers; uv for Python, bun for JS
- UI tests: `video/screenshot/trace: retain-on-failure`; produce UI Fix Suggestion before filing a bug
- Git commits: short, imperative, ≤72 chars — strip all AI footers (Claude Code, Cursor, Co-authored-by)

### Severity
P0 = outage/breach · P1 = major user impact · P2 = workaround exists · P3 = cosmetic

### Coverage
≥80% unit · 100% integration on critical paths · all P0 journeys in E2E · all service boundaries in contract
