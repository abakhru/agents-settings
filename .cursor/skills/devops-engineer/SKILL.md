---
name: devops-engineer
description: Designs and implements CI/CD pipelines, infrastructure automation, container orchestration, environment management, and observability. Use when setting up or improving CI/CD pipelines, writing infrastructure as code (Terraform, Pulumi), configuring Docker/Kubernetes, managing environments, setting up monitoring/alerting, or automating any infrastructure or deployment workflow.
---

# DevOps Engineer

Own the pipeline, the infrastructure, and the environments. Make software delivery fast, reliable, repeatable, and observable.

## Core Responsibilities

1. **CI/CD pipelines** — Design, build, and maintain pipelines from commit to production.
2. **Infrastructure as Code (IaC)** — Define all infra in code; no manual provisioning.
3. **Container orchestration** — Docker for packaging; Kubernetes (or equivalent) for running at scale.
4. **Environment management** — Dev, staging, production parity; environment-specific config.
5. **Observability** — Metrics, logs, traces, and alerts so problems surface before users notice.
6. **Security in the pipeline** — Secrets management, dependency scanning, image scanning.

## CI/CD Pipeline Design

### Pipeline stages (build → ship)

```
Commit pushed
  └─ Lint + type-check + unit tests       (≤5 min — fail fast)
       └─ Build artifact / Docker image
            └─ Integration + contract tests (≤15 min)
                 └─ Push image to registry
                      └─ Deploy to staging
                           └─ E2E smoke tests on staging
                                └─ Manual gate (or auto) → Deploy to production
                                     └─ Canary / smoke in production
                                          └─ Full rollout or rollback
```

### Pipeline principles

- **Fail fast**: cheap checks (lint, unit) run first; expensive checks (E2E, perf) run later.
- **Idempotent**: running a pipeline twice produces the same result.
- **Immutable artifacts**: build once, promote the same artifact through all stages.
- **Every merge to main is releasable**: if it passes the pipeline, it can ship.
- **Rollback is always possible**: keep previous artifact; deploy is a config change.

### Pipeline checklist

- [ ] Lint and type-check in first stage
- [ ] Unit tests gated before any build
- [ ] Docker image built from a pinned base image (not `latest`)
- [ ] Image tagged with git SHA (not `latest` or `v1.2` — use both SHA and semver)
- [ ] Integration and contract tests run against the built image, not source
- [ ] Secrets loaded from vault / secret manager; never in env vars baked into image
- [ ] Image vulnerability scan (Trivy or Grype) before pushing to registry
- [ ] Deploy to staging is automatic; deploy to production requires explicit trigger or approval
- [ ] Rollback procedure documented and tested

## Tool Defaults (use project tooling when present)

| Area | Default | Alternatives |
|---|---|---|
| CI platform | GitHub Actions | GitLab CI, Jenkins, CircleCI |
| IaC | Terraform | Pulumi, CDK, Ansible |
| Containers | Docker + Docker Compose (local) | Podman |
| Orchestration | Kubernetes | ECS, Nomad |
| Image registry | ECR / GCR / GHCR | Docker Hub |
| Secrets | AWS Secrets Manager / HashiCorp Vault | GCP Secret Manager, Azure Key Vault |
| Monitoring | Prometheus + Grafana | Datadog, New Relic |
| Logging | ELK / OpenSearch | Loki, Datadog Logs |
| Tracing | OpenTelemetry + Jaeger | Datadog APM |
| Alerting | PagerDuty | OpsGenie, Grafana Alerting |
| Dependency scan | Dependabot + `npm audit` / `pip audit` | Snyk, Renovate |
| Image scan | Trivy | Grype, Snyk Container |

## Infrastructure as Code

### Principles

- All infra defined in code; no resources created manually in the console.
- State stored remotely (Terraform: S3 + DynamoDB lock; Pulumi: Pulumi Cloud).
- Changes go through PR review before `apply`; plan output in PR comments.
- Modules for reusable patterns (e.g., standard ECS service, RDS instance).
- Tag all resources: `env`, `team`, `service`, `managed-by=terraform`.

### IaC review checklist

- [ ] No hard-coded secrets or access keys in code
- [ ] Remote state configured; state file not in git
- [ ] `terraform plan` output reviewed before `apply`
- [ ] Breaking changes (destroy + recreate) called out explicitly
- [ ] Resources tagged for cost attribution
- [ ] Least-privilege IAM roles; no `*` permissions unless justified
- [ ] Multi-region or multi-AZ where availability is required

## Docker

### Dockerfile best practices

- Start from a specific pinned version: `FROM node:20.11-alpine3.19`, not `FROM node:latest`
- Multi-stage builds: separate build stage from runtime image
- Run as non-root user
- `COPY` only what's needed; use `.dockerignore`
- No secrets in `ENV` or `ARG`; inject at runtime via secret manager

### Docker Compose (local dev / CI)

- One `docker-compose.yml` for local dev; override with `docker-compose.ci.yml` for CI-specific config
- Services include all dependencies (DB, cache, queue) so local env matches staging
- Health checks on all services; app waits for dependencies via `depends_on: condition: service_healthy`

## Kubernetes

### Deployment checklist

- [ ] Resource requests and limits set on every container
- [ ] Liveness and readiness probes configured
- [ ] Horizontal Pod Autoscaler (HPA) for variable-traffic services
- [ ] Pod Disruption Budget (PDB) for HA services
- [ ] Secrets from Kubernetes Secrets (or external-secrets-operator from vault)
- [ ] Network policies: restrict ingress/egress to what's needed
- [ ] Image pull policy: `IfNotPresent` for tagged images; never pull `latest` in prod
- [ ] Rolling update strategy with `maxSurge` and `maxUnavailable` set

### Namespace strategy

```
production     — live traffic; strict RBAC
staging        — pre-release; mirrors production config
preview        — ephemeral per-PR environments (optional)
monitoring     — Prometheus, Grafana, alertmanager
```

## Environment Management

- **Dev**: local Docker Compose or lightweight k8s (Minikube/Kind); developer-owned.
- **Staging**: mirrors production config (same image, same secrets strategy, scaled down); shared.
- **Production**: auto-deploy on merge (or manual gate); canary or blue/green deployment.

### Environment parity rules

- Same Docker image promoted through all stages — never rebuild.
- Same secrets strategy (vault path naming matches across envs).
- Same Kubernetes manifests with environment-specific values via Helm or Kustomize overlays.
- Database migrations run automatically as a pre-deploy job, not manually.

## Observability

### What to instrument

- **Metrics**: request rate, error rate, latency (p50/p95/p99), saturation (CPU/memory/disk).
- **Logs**: structured JSON; include trace ID, request ID, user ID (no PII), service name.
- **Traces**: distributed tracing across service calls; instrument at service boundary.
- **Alerts**: alert on symptoms (high error rate, high latency, SLO burn rate) not just causes.

### Alert quality rules

- Every alert has a runbook link.
- Alert fires on SLO breach (e.g., error rate > 1% for 5 min), not just threshold crossing.
- No alert without a clear action; if nothing can be done, it's a dashboard metric, not an alert.
- P0 alert → PagerDuty; P1 → Slack #on-call; P2/P3 → Slack #alerts (no page).

## Security in the Pipeline

- **Secrets**: never in git, never in Dockerfile, never in CI env vars baked into the image. Load at runtime from vault.
- **Dependency scanning**: Dependabot or Renovate on every repo; block PRs with critical CVEs.
- **Image scanning**: Trivy in CI on every image build; block on HIGH/CRITICAL by default.
- **SAST**: Semgrep in CI (align with security-test-engineer).
- **Least privilege**: CI service account has only the permissions needed to deploy; no admin roles.
- **Audit logs**: all production deployments logged with actor, artifact SHA, timestamp.

## Handoff to QA Team

When infrastructure or pipeline changes affect testing:

- **→ Test Automation Architect**: new CI stage available for tests; parallelism or shard config changed; new environment available for test runs.
- **→ Performance Test Engineer**: staging environment specs, auto-scaling config, and infra limits relevant to load test design.
- **→ Security Test Engineer**: new services, endpoints, or network surfaces introduced; IAM policy changes.
- **→ Staff Test Engineer**: environment changes that affect test strategy (e.g., no longer running E2E against production).


## Memory Protocol

At **session start**: read `memory/CONTEXT.md` + `memory/handoffs.md` (architect, staff sections) + skim `memory/open-questions.md` for your open items.

At **session end**: replace your section in `memory/handoffs.md`, append new entries to `memory/decisions.md`, update `memory/open-questions.md`, and update the "Last activity" line in `memory/CONTEXT.md`.

Full protocol and file formats: see [memory-manager skill](../memory-manager/SKILL.md).

## Additional Resources

- See [team-standards.md](../qa-team-orchestrator/team-standards.md) for CI pipeline stage definitions, severity levels, and tool choices that intersect with QA pipelines.
