# QA Team Standards

Shared reference for all test engineering specialists. Prefer project-specific tooling when it exists; fall back to these defaults.

---

## Coding Principles

These apply to all code and tests produced by any specialist.

| Principle | Rule |
|---|---|
| **Minimum code** | Write the simplest implementation that satisfies the requirement. No speculative abstractions. |
| **DRY** | Every piece of logic lives in exactly one place. Extract duplicated code immediately. |
| **Modular test design** | Group related tests in classes. Extract shared setup into base classes or mixins. Use inheritance when specialist behaviour extends a common base. |
| **Parameterized Python tests** | Use the [`parameterized`](https://pypi.org/project/parameterized/) library for data-driven test cases. Never duplicate test methods for different inputs. |
| **Performance testing** | Always use **k6**. No Locust or Gatling unless the project already uses them. |
| **Atomic & independent tests** | Every test runs in any order, in isolation, and produces the same result. No test depends on state left by another. |
| **Always clean up** | `tearDown` (or fixture finalizer) undoes every side effect: created data, open connections, written files, changed shared state. |
| **Python linting** | **ruff** — line length 120, double quotes. Config in `pyproject.toml`. Replaces flake8, black, and isort. |
| **Python type checking** | **ty** (Astral). All new code must be fully annotated. No bare `Any` without a comment. |
| **Task runner** | **just** for every project. `just` with no args prints help (`default: @just --list`). CI calls `just <target>`, not raw commands. |
| **Docker caching** | Always use `--mount=type=cache` for uv, bun, apt, and any other package-install layer. Python images use uv; JS images use bun. |
| **uv** | Use `uv` for all new Python projects. Never use bare `pip`, `pip-tools`, or `poetry`. |
| **bun** | Use `bun` for all JavaScript/TypeScript projects. Never use `npm`, `yarn`, or `pnpm` for new projects. |
| **vinext** | Use `vinext` (Cloudflare's Next.js on Vite) for all new web UI and full-stack projects. `bun add vinext`; commands: `vinext dev / build / deploy`. |
| **beads** | Use `bd` (Beads) for all task tracking. Install: `bun install -g @beads/bd`. Init per project: `bd init`. Use `bd ready` at session start. |
| **mise.toml** | Pin all tool versions (Python, Node, just, etc.) in `mise.toml` at repo root. Commit to git. CI calls `mise install` first. |
| **Integration tests** | Use real services (Docker Compose, testcontainers). Mocking only in unit tests. |
| **Dependency scanning** | **osv-scanner** — scans `uv.lock`, `package-lock.json`, etc. Runs every PR; CRITICAL blocks merge. |
| **Image scanning** | **trivy** — scans Docker images before push. Fail CI on HIGH or CRITICAL. Document accepted findings in `.trivyignore` with expiry. |
| **Search** | Always use **rg** (ripgrep) instead of `grep`. Faster, respects `.gitignore`, better defaults. Never use `grep` in scripts or docs. |

---

## Tool Choices by Layer

| Layer | Default Tool(s) | Notes |
|---|---|---|
| Unit (JS/TS) | Jest | Vitest for Vite-based projects |
| Unit (Python) | pytest + `parameterized` | Use `parameterized` library for data-driven tests |
| Unit (Swift) | XCTest | |
| Unit (Kotlin/Java) | JUnit 5 | |
| Web E2E | Playwright | Cypress if already established |
| Mobile E2E | Appium + WebdriverIO | XCUITest (iOS), Espresso (Android) for native |
| API / HTTP | REST Assured, Supertest, or pytest + httpx | Match project language |
| Contract | Pact | Provider + consumer sides |
| Performance / Load | **k6** | Default always. Locust/Gatling only if already established in the project. |
| Security SAST | Semgrep | Integrated in CI |
| Security DAST | OWASP ZAP | Run against staging |
| Test data | Fixtures + factory functions | Avoid production data in tests |
| Mocking | MSW (web), WireMock (JVM/HTTP), responses (Python) | |
| Python package manager | uv | Replaces pip, pip-tools, poetry for new projects |
| Python linting | ruff | line-length = 120, quote-style = "double" |
| Python type checking | ty | All new code must be fully typed |
| JS/TS package manager | bun | Replaces npm, yarn, pnpm for new projects |
| Web UI framework | vinext | Cloudflare's Next.js on Vite; deploy to Workers |
| Task tracking | beads (`bd`) | `bd ready` at session start; `bd update --claim`/`--status done` |
| Task runner | just | `default: @just --list`; CI calls `just <target>` |
| Tool version management | mise | `mise.toml` at repo root; `mise install` in CI |
| Docker builds | BuildKit + uv/bun | `--mount=type=cache` on all layers; uv for Python, bun for JS |
| Dependency scanning | osv-scanner | Scans lockfiles; CRITICAL blocks PR merge |
| Image scanning | trivy | Scans Docker images; fails CI on HIGH/CRITICAL |

---

## Naming Conventions

### Files and Folders

```
tests/
├── unit/
├── integration/
├── e2e/
├── contract/
├── performance/
├── security/
└── fixtures/
```

- Test files: `<subject>.test.ts`, `<subject>.spec.ts`, or `test_<subject>.py`
- Fixture files: `<domain>.fixture.ts` / `<domain>_factory.py`
- Page objects: `<page-name>.page.ts`
- API clients (test helpers): `<service>-client.ts`

### Test Names

- Format: `should <do expected behavior> when <condition>`
  - Example: `should return 401 when auth token is missing`
- Python: `test_<behavior>_<condition>`
  - Example: `test_returns_401_when_token_missing`
- E2E describe blocks: `Feature: <FeatureName>` → `Scenario: <short description>`

---

## Severity Definitions

All bug reports, gate violations, and findings use this scale:

| Severity | Label | Definition |
|---|---|---|
| **P0** | Critical | Data loss, security breach, system outage, complete feature broken in prod |
| **P1** | High | Major user-facing bug, key user journey broken, significant data issue |
| **P2** | Medium | Feature partially broken; workaround exists; non-critical user impact |
| **P3** | Low | Cosmetic, minor UX issue, edge case with negligible user impact |

---

## CI Pipeline Stages

| Stage | Tests | Trigger | Max Duration |
|---|---|---|---|
| **PR checks** | Unit, lint, type-check | Every PR commit | 5 min |
| **Integration gate** | Unit + integration + contract | PR merge to main | 15 min |
| **Full E2E** | Web E2E, mobile E2E (smoke) | Daily + pre-release | 30 min |
| **Security scan** | SAST, dependency audit | Daily + pre-release | 10 min |
| **Performance baseline** | Load test (target load, key APIs) | Pre-release | 20 min |
| **Full stress / soak** | Stress + soak scenarios | On-demand / release only | 60 min+ |

Flaky tests must be quarantined (separate CI job) within 24 hours of first flake report; fixed or removed within 5 business days.

---

## Coverage Targets

These are defaults; adjust by module risk (staff-test-engineer defines per-project targets):

| Layer | Target |
|---|---|
| Unit — new code | ≥ 80% line coverage |
| Critical paths (auth, payments, data) | 100% integration-tested |
| E2E happy paths | All P0 user journeys covered |
| Contract tests | Every service-to-service boundary |
| Security | All OWASP Top 10 checked per feature |
| Performance | Baseline established before first release |

---

## Flakiness Policy

- Flakiness threshold: < 1% failure rate on green builds.
- Any test failing > 3 times in 7 days without a product bug as root cause is quarantined.
- Quarantine label: `[QUARANTINE]` prefix in test name + ticket in backlog.
- Owner: the engineer who last modified the test.
