# amit-claude

Personal AI agent skills and configuration for Cursor and Claude CLI.

---

## QA Agent Team

A team of 14 specialized AI agent skills covering the full product and software quality lifecycle — from problem framing and design through delivery and beyond — with shared memory management to keep the team in sync across sessions. Each skill gives the AI a specific persona, checklist-driven workflow, and structured output format. An orchestrator coordinates them.

### Team Members

| Skill | Role | Activate when... |
|---|---|---|
| [qa-team-orchestrator](#orchestrator) | Coordinator | You have a broad request: "what do we need to test for X?" |
| [memory-manager](#memory-manager) | Shared memory | Starting a new session, switching specialists, resuming interrupted work |
| [product-manager](#product-manager) | Problem framing & specs | Defining a feature, writing a PRD, prioritizing a backlog, defining success metrics |
| [ui-ux-designer](#ui-ux-designer) | Design & UX | User flows, component design, design tokens, accessibility, engineering handoff |
| [exploratory-test-engineer](#exploratory-test-engineer) | Discovery | Application or feature is unknown/undocumented |
| [staff-test-engineer](#staff-test-engineer) | Strategy & risk | Defining test strategy, quality gates, risk-based design |
| [test-automation-architect](#test-automation-architect) | Framework & CI | Setting up test frameworks, CI/CD integration, shared infra |
| [devops-engineer](#devops-engineer) | Pipelines & infra | CI/CD pipelines, IaC, Docker/K8s, environments, observability |
| [backend-python](#backend-python-engineer) | Python backend | FastAPI services, SQLAlchemy, Pydantic, uv, async patterns |
| [junior-test-engineer](#junior-test-engineer) | Implementation | Writing tests from specs, fixing flaky tests, bug reports |
| [api-contract-test-engineer](#api-contract-test-engineer) | API & contracts | REST/GraphQL tests, Pact contract tests, service mocking |
| [security-test-engineer](#security-test-engineer) | Security | OWASP checklist, auth/authz boundaries, scan triage |
| [performance-stress-test-engineer](#performance-stress-test-engineer) | Load & stress | Load tests, stress tests, capacity planning, metrics |
| [mobile-test-engineer](#mobile-test-engineer) | Mobile | iOS/Android automation, Appium, device strategy |

### Default Sequencing

For a greenfield feature or unknown application:

```
0. memory-init     → run `just memory-init` in the project to scaffold memory/ files
1. PM              → problem framing, PRD, acceptance criteria, success metrics, handoffs
2. Designer        → user flows, component specs, design tokens, accessibility, QA/eng handoffs
3. Explorer        → maps the application; produces feature map + specialist handoffs
4. DevOps          → CI/CD pipeline, environments, infra
5. Architect       → test framework, CI hooks (coordinates with DevOps)
6. Staff           → test strategy, risk prioritization, quality gates (PM's AC + Designer specs + Explorer's map)
7. Specialists     → Backend Python implements the service;
                     API, Security, Performance, Mobile cover their layers (all parallel)
8. Junior          → functional test implementation + visual/accessibility checks
9. Staff           → final coverage review before release
```

Skip steps that don't apply — e.g., skip PM if a spec already exists; skip Designer if designs already exist; skip Explorer if the feature is well-understood; skip DevOps/Architect if pipelines and framework are already stable.

---

## How to Use

### Memory Setup (one time per project)

Install Beads once: `bun install -g @beads/bd`

Then initialize each project:

```bash
cd /path/to/your-project
just memory-init        # scaffolds memory/ files + bd init + AGENTS.md
```

Fill in `memory/CONTEXT.md` with the project description and tech stack. Create your first task: `bd create "First task" -p 1`. Then start your first session.

Check memory status anytime: `just memory-status` | See unblocked tasks: `just tasks`

### In Cursor

Both `~/.cursor/skills` and `~/.cursor/rules` are symlinks into this repo. Edits to any skill or rule file are live instantly — no sync step required.

**Start with the orchestrator** for any broad request:

> "Use the QA team orchestrator to plan testing for the new checkout feature."

**Or target a specific specialist** directly:

> "Act as the security test engineer and review this auth flow."
> "Use the exploratory test engineer to map this API."
> "As the devops engineer, write a GitHub Actions pipeline for this service."

You can also @-mention a skill file directly: `@.cursor/skills/staff-test-engineer/SKILL.md`

**First-time machine setup**: `just setup` — creates both symlinks (`~/.cursor/skills` → repo and `~/.claude/CLAUDE.md` → repo).

### With Claude CLI (`claude`)

The full team is loaded globally via `~/.claude/CLAUDE.md`, which is a symlink to `CLAUDE.md` in this repo. Edits here are immediately live — no sync step needed. It applies to every project automatically.

Just describe what you need and Claude will apply the right specialist(s):

```bash
claude "What do we need to test for the new payments feature? Use the QA team."
claude "Act as the devops engineer and write a Terraform module for an ECS service."
claude "Run the OWASP checklist on this login endpoint as the security test engineer."
```

---

## Skill Files

```
.cursor/skills/
├── qa-team-orchestrator/
│   ├── SKILL.md              # Orchestrator: decompose, assign, sequence, output test plan
│   └── team-standards.md     # Shared: tools, naming, severity (P0–P3), CI stages, flakiness
├── memory-manager/
│   ├── SKILL.md              # Memory protocol: session start/end, read map, file formats
│   └── templates/
│       ├── CONTEXT.md        # Project context template
│       ├── decisions.md      # Append-only decision log template
│       ├── handoffs.md       # Per-specialist handoff sections template
│       └── open-questions.md # Cross-team questions table template
├── product-manager/
│   ├── SKILL.md              # Problem framing, RICE/MoSCoW, PRD, acceptance criteria, metrics
│   └── references/
│       └── prd-template.md   # Full PRD template with all sections
├── ui-ux-designer/
│   ├── SKILL.md              # User flows, IA, component specs, design tokens, a11y, handoffs
│   └── references/
│       └── design-checklist.md  # 10-phase design & accessibility checklist
├── exploratory-test-engineer/
│   └── SKILL.md              # SBET sessions, SFDIPOT heuristic, feature map, specialist handoffs
├── staff-test-engineer/
│   └── SKILL.md              # Strategy checklist, risk-based design, testability review, gates
├── test-automation-architect/
│   └── SKILL.md              # Framework setup, shared abstractions, CI integration, tool eval
├── devops-engineer/
│   └── SKILL.md              # Pipeline design, IaC, Docker, Kubernetes, observability, secrets
├── backend-python/
│   ├── SKILL.md              # FastAPI, SQLAlchemy 2.0, Pydantic v2, uv, async patterns, anti-patterns
│   └── references/
│       └── testing.md        # pytest-asyncio, httpx AsyncClient, fixtures, factories, parametrize
├── junior-test-engineer/
│   └── SKILL.md              # Test implementation checklist, bug reports, flaky test fixes
├── api-contract-test-engineer/
│   └── SKILL.md              # REST/GraphQL checklists, Pact consumer/provider, mocking strategy
├── security-test-engineer/
│   └── SKILL.md              # OWASP Top 10, auth/authz boundaries, input validation, scan triage
├── performance-stress-test-engineer/
│   └── SKILL.md              # Load/stress/spike/soak, k6/Locust/Gatling, metrics, reporting
└── mobile-test-engineer/
    └── SKILL.md              # XCUITest/Espresso/Appium, device strategy, mobile-specific coverage
```

---

## Skill Reference

### Orchestrator

**File**: `.cursor/skills/qa-team-orchestrator/SKILL.md`

Takes any feature or product request, decomposes it into test layers, assigns each to the right specialist, defines sequencing and handoffs, and outputs a structured test plan. Start here for any broad "what do we need to test?" question.

**Output format**:
```
## Test Plan: [Feature]
### Scope / Risk Areas / Work Items / Sequencing / Open Questions / Quality Gates
```

---

### Memory Manager

**Files**: `.cursor/skills/memory-manager/SKILL.md`, `templates/`

Keeps all specialists in sync across sessions via four shared files in the project's `memory/` directory. Every session starts by reading memory and ends by writing it — no specialist starts blind, no work is lost between sessions.

Memory uses two complementary layers — use both:

| Layer | Tool | Answers |
|---|---|---|
| Task tracking | `bd` ([Beads](https://github.com/steveyegge/beads)) | What should I work on? What's blocked? |
| Knowledge store | `memory/` files | What did the PM decide? What did the explorer find? |

**Setup** (one time per project): `just memory-init` — scaffolds both `memory/` files and runs `bd init`.

**Knowledge store files**:
```
memory/
├── CONTEXT.md          # Project overview, tech stack, current phase, last activity
├── decisions.md        # Append-only decision log (newest first)
├── handoffs.md         # Latest output from each specialist (replaced each session)
└── open-questions.md   # Cross-team questions (marked resolved, never deleted)
```

**Beads essentials**: `bd ready` (start of session) · `bd update <id> --claim` · `bd update <id> --status done` · `bd create "Title" -p N`

**justfile targets**:
```bash
just memory-init [path]    # Scaffold memory/ + bd init + AGENTS.md (default: current dir)
just memory-status [path]  # Show phase, last activity, open questions, handoff dates
just memory-show [path]    # Print all four memory files to stdout
just memory-reset [path]   # Back up and reinitialize memory/
just tasks                 # bd ready — unblocked tasks
just task "Title" [0-3]    # Create a Beads task
just claim <id>            # Claim a task
just done <id>             # Mark a task complete
just in-progress           # List in-flight tasks
```

---

### Product Manager

**Files**: `.cursor/skills/product-manager/SKILL.md`, `references/prd-template.md`

Goes first on any new feature. Frames the problem using Jobs-to-be-Done, scores options with RICE, and writes a PRD with unambiguous Given/When/Then acceptance criteria, non-functional requirements, and instrumentation events. Defines primary/secondary/guardrail success metrics before build starts and produces structured handoff packages for the QA team, engineering, and design.

**Key outputs**:
- Problem statement + hypothesis with falsifiable metric target
- RICE-scored backlog with explicit trade-offs
- PRD: MoSCoW scope, testable acceptance criteria, NFRs, instrumentation events
- Phased launch plan with feature flag name and rollback trigger

---

### UI/UX Designer

**Files**: `.cursor/skills/ui-ux-designer/SKILL.md`, `references/design-checklist.md`

Translates product requirements into user flows, information architecture, component specs, design tokens, and accessibility-first visual design. Produces structured handoffs for engineering (token JSON, anatomy + states + spacing per component, ARIA/keyboard specs) and QA (visual regression scope, a11y checks, responsive breakpoints).

**Key outputs**:
- Research synthesis: prioritized user needs, mental model, constraints
- Flow maps: happy path + error paths + empty/loading/edge states for every feature
- Component specs: anatomy, all states, 8-point grid spacing, typography tokens, motion spec
- Design tokens: color, typography, spacing, radius, shadow, motion — exported as JSON
- Accessibility checklist: WCAG 2.1 AA verified per component and per screen
- 10-phase design checklist (full detail in `references/design-checklist.md`)

---

### Exploratory Test Engineer

**File**: `.cursor/skills/exploratory-test-engineer/SKILL.md`

Goes first when the application is unknown. Runs charter-based exploration sessions (SBET), applies the SFDIPOT heuristic to avoid blind spots, and produces:
- **Feature map**: full inventory of screens, endpoints, flows, edge cases, undocumented behaviors, and risk flags
- **Specialist handoff packages**: targeted notes for each downstream specialist (Staff, Architect, API, Security, Performance, Mobile, Junior)

---

### Staff Test Engineer

**File**: `.cursor/skills/staff-test-engineer/SKILL.md`

Senior-level strategy and oversight. Produces test strategy docs (scope, risk areas, levels, automation vs manual, exit criteria), defines quality gates, reviews code for testability (observability, controllability, stability), and mentors the team with patterns and rationale rather than one-off answers.

---

### Test Automation Architect

**File**: `.cursor/skills/test-automation-architect/SKILL.md`

Owns the shared test framework. Selects and configures tools per layer, defines folder structure and shared abstractions (page objects, API clients, fixtures, factories), sets up CI pipeline stages and parallel execution, and governs framework-level changes.

---

### DevOps Engineer

**File**: `.cursor/skills/devops-engineer/SKILL.md`

Owns the delivery pipeline and infrastructure. Designs CI/CD pipelines (fail-fast ordering, immutable artifacts, canary deploys), writes IaC (Terraform), configures Docker and Kubernetes, manages environment parity (dev/staging/prod), sets up observability (metrics, logs, traces, SLO-based alerting), and enforces pipeline security (Trivy image scanning, Dependabot, vault-based secrets).

---

### Backend Python Engineer

**Files**: `.cursor/skills/backend-python/SKILL.md`, `references/testing.md`

Builds Python backend services using FastAPI, SQLAlchemy 2.0, Pydantic v2, and `uv`. Enforces async-first patterns, service-layer separation, dependency injection, and typed Pydantic schemas. Testing reference covers `pytest-asyncio`, `httpx.AsyncClient` with ASGI transport, factory fixtures, and `@pytest.mark.parametrize`. Includes an anti-patterns table (e.g., `pip` → `uv`, SQLAlchemy 1.x → 2.0 `Mapped[]`, sync DB → async). Add `use context7` to prompts for live FastAPI/SQLAlchemy/Pydantic docs.

---

### Junior Test Engineer

**File**: `.cursor/skills/junior-test-engineer/SKILL.md`

Implements tests from defined test cases following existing patterns (page objects, fixtures, naming). Covers Arrange–Act–Assert structure, proper assertions, test isolation, and cleanup. Also produces structured bug reports (steps, expected, actual, environment, frequency) and knows when to escalate.

---

### API / Contract Test Engineer

**File**: `.cursor/skills/api-contract-test-engineer/SKILL.md`

Covers REST and GraphQL API test checklists (happy path, auth, input validation, schema, pagination), sets up Pact consumer-driven contract tests at service boundaries, and designs mocking/virtualization strategy for downstream dependencies (WireMock, MSW, test containers).

---

### Security Test Engineer

**File**: `.cursor/skills/security-test-engineer/SKILL.md`

Applies OWASP Top 10 checklist per feature, tests auth/authz boundaries (horizontal and vertical privilege escalation, token misuse, session invalidation), runs input validation tests (SQLi, XSS, path traversal), and triages SAST (Semgrep) and DAST (OWASP ZAP) scanner output with True/False Positive labels.

---

### Performance / Stress Test Engineer

**File**: `.cursor/skills/performance-stress-test-engineer/SKILL.md`

Designs load (target traffic), stress (break point), spike (burst), and soak (leak detection) scenarios. Defines VU profiles, SLOs (p95 latency , error rate), and data strategies. Analyzes p50/p95/p99 latency, throughput, error rate, and resource metrics. Outputs pass/fail reports against SLOs with bottleneck findings and recommendations.

---

### Mobile Test Engineer

**File**: `.cursor/skills/mobile-test-engineer/SKILL.md`

Covers native automation (XCUITest for iOS, Espresso for Android) and cross-platform (Appium + WebdriverIO). Advises on device strategy (emulators in CI, cloud lab for release gates). Tests mobile-specific behaviors: permissions, offline/airplane mode, deep links, background/foreground transitions, gestures, and push notifications.

---

## Shared Standards

**File**: `.cursor/skills/qa-team-orchestrator/team-standards.md`

All specialists operate under the same conventions. Key sections:

- **Tool defaults per layer** — Jest/pytest/XCTest for unit; Playwright for web E2E; Appium for mobile; k6 for perf; Pact for contracts; Semgrep + ZAP for security
- **Naming** — `<subject>.test.ts`, `test_<behavior>_<condition>`, `should <behavior> when <condition>`
- **Severity** — P0 (critical/outage), P1 (major user impact), P2 (partial/workaround), P3 (cosmetic)
- **CI stages** — PR checks (≤5 min), integration gate (≤15 min), full E2E (≤30 min), security scan, perf baseline, stress on-demand
- **Coverage targets** — ≥80% unit, 100% integration on critical paths, all P0 journeys in E2E, all service boundaries in contract tests
- **Flakiness policy** — quarantine within 24h of 3rd unexplained failure; fix or remove within 5 days

---

## Adding or Updating Skills and Rules

**Skills**: edit `.cursor/skills/<skill-name>/SKILL.md` — live instantly via symlink.

**Rules**: edit `.cursor/rules/<name>.mdc` — live instantly via symlink.

**CLAUDE.md**: edit `CLAUDE.md` in this repo — live instantly via symlink to `~/.claude/CLAUDE.md`.

No sync step needed for any of them. On a new machine, run `just setup` to create all three symlinks.

To add a new skill, follow the structure in any existing `SKILL.md`: YAML frontmatter (`name`, `description`), then markdown sections with checklists and output formats. Keep it under 200 lines; use progressive disclosure with reference files for detail.

---

## Other Files in this Repo

- `ux-designer.md` — Project-specific design brief for a fintech/crypto dashboard (used as an example reference by the `ui-ux-designer` skill)
