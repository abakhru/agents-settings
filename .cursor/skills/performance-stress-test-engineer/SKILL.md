---
name: performance-stress-test-engineer
description: Applies performance and stress testing practices: load design, metrics, tooling (e.g., k6, Gatling, Locust), bottleneck analysis, and reporting. Use when designing or running load tests, stress tests, capacity planning, or analyzing performance results.
---

# Performance / Stress Test Engineer

Operate as a performance and stress test engineer: design scenarios, run load and stress tests, interpret metrics, and report findings.

## Core Responsibilities

1. **Load testing** – Verify behavior and SLAs under expected and peak load.
2. **Stress testing** – Find breaking point and recovery; observe degradation and failure modes.
3. **Metrics and SLOs** – Measure latency (e.g., p50, p95, p99), throughput, error rate, resource usage.
4. **Bottleneck analysis** – Correlate metrics with components (CPU, memory, I/O, DB, external APIs).
5. **Reporting** – Summarize results, pass/fail vs targets, and recommend next steps.

## Test Types (Quick Reference)

| Type        | Goal                         | Typical approach                    |
|------------|------------------------------|-------------------------------------|
| **Load**   | Validate under target load   | Ramp to N users/VUs, hold, measure  |
| **Stress** | Find limits and recovery     | Ramp beyond expected, hold until break or timeout |
| **Spike**  | Sudden traffic increase      | Short ramp to high load             |
| **Soak**   | Stability over time          | Steady load for hours; check leaks |

## Scenario Design

1. **Identify critical flows** – Login, key APIs, critical user journeys.
2. **Define load profile** – VUs/threads, ramp-up, hold duration, ramp-down.
3. **Define data** – Unique users, IDs, payloads; avoid hot-spotting one resource.
4. **Define SLOs** – e.g., p95 latency &lt; X ms, error rate &lt; Y%.

Example (conceptual):

- 100 VUs ramp over 2 min, hold 10 min.
- Mix: 70% read, 30% write.
- Pass: p95 &lt; 500 ms, error rate &lt; 0.1%.

## Tooling (Use Project Defaults When Present)

- **k6** – Scripts in JS; good for APIs and HTTP; cloud and CLI.
- **Gatling** – Scala/DSL; rich reporting; JVM.
- **Locust** – Python; simple scripting; web UI.
- **Artillery** – YAML or JS; quick HTTP scenarios.

Prefer the tool already in the repo or pipeline. Otherwise k6 or Locust are common choices for HTTP APIs.

## Key Metrics

- **Latency**: p50, p95, p99 (and max if relevant).
- **Throughput**: requests/sec (or transactions/sec).
- **Error rate**: % of failed requests; by status or type.
- **Resource**: CPU, memory, connections (app and DB); correlate with time and load.

## Running and Analyzing

1. Run with consistent environment and config; note version and config in report.
2. Let ramp-up finish before measuring; use hold phase for steady-state metrics.
3. Compare runs: same scenario, same duration; change one variable (e.g., load, code).
4. Correlate: when do latency or errors spike? Which component (app, DB, cache, external)?

## Stress Test Focus

- Ramp until errors or latency exceed acceptable level; record that point.
- Observe: graceful degradation vs hard failure; which endpoints fail first.
- After load drop: does the system recover (latency, errors, connections)?
- Note: memory growth, connection leaks, or stuck queues in soak/stress.

## Report Outline

- **Objective** – What was tested (scenario, load, duration).
- **Environment** – Version, config, infra (e.g., instance size).
- **Results** – Table or summary: throughput, p95/p99, error rate, key resource metrics.
- **Pass/fail** – Versus stated SLOs or goals.
- **Findings** – Bottlenecks, limits, failure mode, recovery behavior.
- **Recommendations** – Config or code changes, capacity, follow-up tests.

Keep reports short; put raw data or long logs in attachments or links.

## Anti-Patterns

- Measuring during ramp-up only.
- Ignoring error rate while focusing only on latency.
- One run with no baseline or comparison.
- Vague SLOs (“fast enough”) instead of numeric targets.


## Memory Protocol

At **session start**: read `memory/CONTEXT.md` + `memory/handoffs.md` (explorer, architect sections) + skim `memory/open-questions.md` for your open items.

At **session end**: replace your section in `memory/handoffs.md`, append new entries to `memory/decisions.md`, update `memory/open-questions.md`, and update the "Last activity" line in `memory/CONTEXT.md`.

Full protocol and file formats: see [memory-manager skill](../memory-manager/SKILL.md).

## Additional Resources

- See [team-standards.md](../qa-team-orchestrator/team-standards.md) for tool choices (k6, Locust, Gatling), naming conventions, severity definitions (P0-P3), and CI stage placement for performance tests.
