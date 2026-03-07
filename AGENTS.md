# Amit's Claude Code (ACC) — Agent Instructions

This is a **production-ready AI coding plugin** providing 30 specialized agents, 28 UI analysis skills, 33 commands, and automated hook workflows for software development.

## Core Principles

1. **Agent-First** — Delegate to specialized agents for domain tasks
2. **Test-Driven** — Write tests before implementation, 80%+ coverage required
3. **Security-First** — Never compromise on security; validate all inputs
4. **Immutability** — Always create new objects, never mutate existing ones
5. **Plan Before Execute** — Plan complex features before writing code, give me options for approval

## Available Agents

| Agent | Purpose | When to Use |
|-------|---------|-------------|
| planner | Implementation planning | Complex features, refactoring |
| architect | System design and scalability | Architectural decisions |
| tdd-guide | Test-driven development | New features, bug fixes |
| code-reviewer | Code quality and maintainability | After writing/modifying code |
| security-reviewer | Vulnerability detection | Before commits, sensitive code |
| build-error-resolver | Fix build/type errors | When build fails |
| e2e-runner | End-to-end Playwright testing | Critical user flows |
| refactor-cleaner | Dead code cleanup | Code maintenance |
| doc-updater | Documentation and codemaps | Updating docs |
| go-reviewer | Go code review | Go projects |
| go-build-resolver | Go build errors | Go build failures |
| database-reviewer | PostgreSQL/Supabase specialist | Schema design, query optimization |
| python-reviewer | Python code review | Python projects |
| chief-of-staff | Communication triage (email/Slack/LINE) | Managing multi-channel comms |
| harness-optimizer | Agent harness configuration | Reliability, cost, throughput |
| loop-operator | Autonomous loop monitoring | When loops stall or need oversight |
| qa-team-orchestrator | QA team coordination | Broad "what needs testing?" requests |
| product-manager | PRDs, feature specs, RICE prioritization | Defining features, writing specs |
| ui-ux-designer | User flows, component specs, design tokens | Designing UI/UX, a11y reviews |
| exploratory-test-engineer | Application discovery and mapping | Unknown app/feature — map first |
| staff-test-engineer | Test strategy, risk-based design, quality gates | Strategy, testability, mentoring |
| test-automation-architect | Test framework, CI/CD integration | Framework setup, tooling decisions |
| devops-engineer | CI/CD, IaC, Docker/K8s, observability | Pipeline, infra, environments |
| backend-python | FastAPI, SQLAlchemy, Pydantic v2, uv | Python API/service development |
| junior-test-engineer | Writing tests from specs, bug reports | Test implementation, flaky fixes |
| api-contract-test-engineer | REST/GraphQL tests, Pact contracts | API testing, service contracts |
| security-test-engineer | OWASP checklists, auth/authz testing, scan triage | Security testing, SAST/DAST |
| perf-test-engineer | Load/stress/spike/soak tests, k6/Locust | Performance testing, capacity |
| mobile-test-engineer | iOS/Android automation, Appium | Mobile UI tests, device strategy |
| memory-manager | Cross-session knowledge, Beads (bd) task tracking | Session handoffs, project memory |

## Agent Orchestration

Use agents proactively without user prompt:
- Complex feature requests → **planner**
- Code just written/modified → **code-reviewer**
- Bug fix or new feature → **tdd-guide**
- Architectural decision → **architect**
- Security-sensitive code → **security-reviewer**
- "What needs testing?" → **qa-team-orchestrator**
- Defining a feature/spec → **product-manager**
- Designing UI/UX → **ui-ux-designer**
- Unknown app to map → **exploratory-test-engineer**
- Test strategy needed → **staff-test-engineer**
- Python backend work → **backend-python** + **python-reviewer**
- Go project → **go-reviewer** + **go-build-resolver**

Use parallel execution for independent operations — launch multiple agents simultaneously.

## Security Guidelines

**Before ANY commit:**
- No hardcoded secrets (API keys, passwords, tokens)
- All user inputs validated
- SQL injection prevention (parameterized queries)
- XSS prevention (sanitized HTML)
- CSRF protection enabled
- Authentication/authorization verified
- Rate limiting on all endpoints
- Error messages don't leak sensitive data

**Secret management:** NEVER hardcode secrets. Use environment variables or a secret manager. Validate required secrets at startup. Rotate any exposed secrets immediately.

**If security issue found:** STOP → use security-reviewer agent → fix CRITICAL issues → rotate exposed secrets → review codebase for similar issues.

## Coding Style

**Immutability (CRITICAL):** Always create new objects, never mutate. Return new copies with changes applied.

**File organization:** Many small files over few large ones. 200-400 lines typical, 800 max. Organize by feature/domain, not by type. High cohesion, low coupling.

**Error handling:** Handle errors at every level. Provide user-friendly messages in UI code. Log detailed context server-side. Never silently swallow errors.

**Input validation:** Validate all user input at system boundaries. Use schema-based validation. Fail fast with clear messages. Never trust external data.

**Code quality checklist:**
- Functions small (<50 lines), files focused (<800 lines)
- No deep nesting (>4 levels)
- Proper error handling, no hardcoded values
- Readable, well-named identifiers

## Testing Requirements

**Minimum coverage: 80%**

Test types (all required):
1. **Unit tests** — Individual functions, utilities, components
2. **Integration tests** — API endpoints, database operations
3. **E2E tests** — Critical user flows

**TDD workflow (mandatory):**
1. Write test first (RED) — test should FAIL
2. Write minimal implementation (GREEN) — test should PASS
3. Refactor (IMPROVE) — verify coverage 80%+

Troubleshoot failures: check test isolation → verify mocks → fix implementation (not tests, unless tests are wrong).

## Development Workflow

1. **Plan** — Use planner agent, identify dependencies and risks, break into phases
2. **TDD** — Use tdd-guide agent, write tests first, implement, refactor
3. **Review** — Use code-reviewer agent immediately, address CRITICAL/HIGH issues
4. **Commit** — Conventional commits format, comprehensive PR summaries

## Git Workflow

**Commit format:** `<type>: <description>` — Types: feat, fix, refactor, docs, test, chore, perf, ci

**PR workflow:** Analyze full commit history → draft comprehensive summary → include test plan → push with `-u` flag.

## Architecture Patterns

**API response format:** Consistent envelope with success indicator, data payload, error message, and pagination metadata.

**Repository pattern:** Encapsulate data access behind standard interface (findAll, findById, create, update, delete). Business logic depends on abstract interface, not storage mechanism.

**Skeleton projects:** Search for battle-tested templates, evaluate with parallel agents (security, extensibility, relevance), clone best match, iterate within proven structure.

## Performance

**Context management:** Avoid last 20% of context window for large refactoring and multi-file features. Lower-sensitivity tasks (single edits, docs, simple fixes) tolerate higher utilization.

**Build troubleshooting:** Use build-error-resolver agent → analyze errors → fix incrementally → verify after each fix.

## Project Structure

```
agents/          — 30 specialized subagents (coding + QA workflow)
cursor/skills/   — 28 UI analysis micro-specialists (Cursor-only)
commands/        — 33 slash commands
hooks/           — Trigger-based automations
rules/           — Always-follow guidelines (common + per-language)
scripts/         — Cross-platform Node.js utilities
mcp-configs/     — 14 MCP server configurations
tests/           — Test suite
```

## Success Metrics

- All tests pass with 80%+ coverage
- No security vulnerabilities
- Code is readable and maintainable
- Performance is acceptable
- User requirements are met
