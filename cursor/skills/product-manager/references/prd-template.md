# PRD Template

Copy this template for every new feature. Delete sections that don't apply. Never ship a PRD without TL;DR, Problem, Acceptance Criteria, and Success Metrics.

---

# PRD: [Feature Name]

**Author**: [name]
**Status**: Draft | In Review | Approved | Shipped
**Target release**: [quarter or sprint]
**Last updated**: [date]

---

## TL;DR

[3 sentences max. Problem + solution + expected outcome. If you can't summarize it in 3 sentences, the feature is too vague.]

---

## Problem

### Who is affected
[Persona(s) — be specific. "Power users who manage >10 team members" beats "users".]

### Job to be done
[What are they trying to accomplish? Use the JTBD format: "When I [situation], I want to [motivation], so I can [outcome]."]

### Current friction
[What breaks today? Include evidence: error rates, support ticket volume, NPS verbatims, funnel data, user research quotes.]

### Cost of inaction
[What happens if we don't solve this? Revenue at risk, churn rate, ops cost, competitive gap.]

---

## Hypothesis

We believe **[intervention]** will **[outcome]** for **[persona]**.

We'll know we're right when **[primary metric]** changes from **[current]** to **[target]** within **[timeframe]**.

---

## RICE Score

| Factor | Value | Notes |
|---|---|---|
| Reach (users/quarter) | — | — |
| Impact (0.25–3) | — | — |
| Confidence (%) | — | — |
| Effort (person-months) | — | — |
| **RICE score** | **—** | |

**Runner-up considered**: [feature name] — RICE [score] — deprioritized because [reason].

---

## Scope

### Must (launch-blocking)
- [ ] [Requirement 1]
- [ ] [Requirement 2]

### Should (high value, not blocking)
- [ ] [Requirement]

### Could (cut first under pressure)
- [ ] [Requirement]

### Won't (explicitly out of scope)
- [Item] — deferred because [reason]. Revisit trigger: [condition].

---

## Acceptance Criteria

Write every criterion as a testable Given/When/Then statement.

```
GIVEN [precondition]
WHEN [action]
THEN [expected outcome]
```

**Happy path**

```
GIVEN [...]
WHEN [...]
THEN [...]
```

**Error states**

```
GIVEN [...]
WHEN [...]
THEN [...]
```

**Edge cases**

```
GIVEN [...]
WHEN [...]
THEN [...]
```

**Permissions / auth boundaries**

```
GIVEN a user without [permission]
WHEN they attempt [action]
THEN they receive [403 / redirect / error message]
```

---

## Non-Functional Requirements

| Requirement | Target | Notes |
|---|---|---|
| Performance (p95 latency) | ≤ [X]ms on [endpoint] | Measured under [Y] concurrent users |
| Availability | [99.9%] | — |
| Data retention | [X days / delete on account close] | Jurisdiction: [GDPR / CCPA / none] |
| Accessibility | WCAG 2.1 AA | [any exceptions] |
| Scalability ceiling | [X] concurrent users / [Y] requests/sec | — |
| Browser/OS support | [Chrome 120+, Safari 17+, ...] | — |

---

## Success Metrics

**Define before build. Measure after launch.**

### Primary (the hypothesis)
| Metric | Current | Target | Owner |
|---|---|---|---|
| [metric name] | [baseline] | [goal] | [team] |

### Secondary (leading indicators)
| Metric | Direction | Alert threshold |
|---|---|---|
| [metric] | ↑ / ↓ | [value] |

### Guardrails (must not worsen)
| Metric | Current | Alert if worse than |
|---|---|---|
| Page load time (p95) | [Xms] | [Xms + 10%] |
| Error rate | [X%] | [X% + 0.5%] |
| Support ticket volume | [X/week] | [X + 20%] |

---

## Instrumentation Requirements

List every event engineering must instrument. Agreed before development starts.

```
Event: checkout_started
  Properties: user_id, session_id, cart_value (int cents), item_count
  Triggered: when user clicks "Begin Checkout"

Event: checkout_step_completed
  Properties: step (string: address|payment|review), time_on_step (ms)
  Triggered: when user advances to next step

Event: checkout_abandoned
  Properties: step, reason (optional, user-provided)
  Triggered: when user navigates away or closes tab mid-flow

Event: order_placed
  Properties: order_id, user_id, payment_method, subtotal, tax, total
  Triggered: on successful order confirmation
```

---

## Dependencies

| Dependency | Type | Owner | Status | Risk |
|---|---|---|---|---|
| [Service / team / library] | Internal API / 3rd party / migration | [owner] | Ready / Blocked / TBD | [Low / Med / High] |

---

## Open Questions

| # | Question | Owner | Due | Status |
|---|---|---|---|---|
| 1 | [question] | [name] | [date] | Open / Resolved |

---

## Launch Plan

| Phase | Audience | Duration | Gate to proceed |
|---|---|---|---|
| Internal dog-food | Team only | [1 week] | Zero P0 bugs; core flows working |
| Canary 5% | Random sample | [3 days] | Error rate ≤ baseline; no P0 |
| Ramp to 25% | [cohort definition] | [3 days] | Primary metric trending toward target |
| Ramp to 100% | All users | [2 days] | Primary metric at target or acceptable |

**Feature flag name**: `[flag_name]` — owner: [name]

**Rollback trigger**: Immediately roll back if any of the following occur:
- Error rate exceeds [X%] for more than [Y minutes]
- [P0 scenario description]
- Primary metric moves in wrong direction by >[Z%]

**Communication plan**:
- [ ] Changelog entry (user-facing)
- [ ] Internal announcement (Slack #product)
- [ ] Support team briefed

---

## Handoffs

### → QA Team
```
Feature map: [link to exploratory notes if available]
Risk areas: [highest-impact flows needing deepest coverage]
Performance SLO: p95 ≤ [X]ms on [critical endpoint]
Launch gates: [conditions required before each rollout phase]
Out of scope for QA: [explicitly excluded]
```

### → Engineering
```
Non-functional requirements: [summarize from NFR table above]
Feature flag: [flag_name]
Open technical decisions needing engineering input: [list]
Deferred to v2: [list with reopen condition]
```

### → Design
```
Personas: [list]
Core JTBD: [statement]
Happy path flow: [describe or link]
Key error paths: [list]
Constraints: [accessibility, brand, platform, time]
```

---

## Appendix

### Alternatives considered

| Alternative | Why rejected |
|---|---|
| [Option A] | [reason] |
| [Option B] | [reason] |

### User research / data sources

- [Link to user interview recordings / synthesis]
- [Link to relevant analytics dashboard]
- [Support ticket query / NPS verbatims]

### Prior art / competitive analysis

- [Competitor A approach]: [notes]
- [Competitor B approach]: [notes]
