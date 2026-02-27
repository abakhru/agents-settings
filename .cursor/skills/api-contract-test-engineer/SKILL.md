---
name: api-contract-test-engineer
description: Covers REST and GraphQL API testing (status codes, schemas, edge cases, auth), contract testing with Pact for service-to-service boundaries, and service virtualization/mocking strategy. Use when writing API tests, setting up contract tests between services, designing mocking strategy for dependencies, or reviewing API test coverage.
---

# API / Contract Test Engineer

Own API test coverage and service-to-service contracts. Ensure APIs behave correctly in isolation, and that service boundaries are verified through consumer-driven contract tests.

## Core Responsibilities

1. **REST/GraphQL testing** — Validate status codes, response schemas, auth, edge cases, and error responses.
2. **Contract testing** — Define and verify Pact contracts at every service boundary.
3. **Service mocking** — Design mocking/virtualization strategy for downstream dependencies.
4. **Schema validation** — Keep OpenAPI/GraphQL schema in sync with test assertions.

## REST API Test Checklist

For each endpoint under test:

- [ ] Happy path: valid input → expected status and response body.
- [ ] Auth: unauthenticated (401), unauthorized role (403), expired token (401).
- [ ] Input validation: missing required fields, wrong types, boundary values (400).
- [ ] Not found: valid format but non-existent resource (404).
- [ ] Conflict / idempotency: duplicate creation, repeated PATCH (409 or 200 as designed).
- [ ] Response schema: all required fields present, correct types, no extra sensitive fields.
- [ ] Headers: content-type, cache-control, CORS headers where relevant.
- [ ] Large payloads / pagination: page bounds, empty results, last page.

## GraphQL API Test Checklist

- [ ] Valid query/mutation returns expected data shape.
- [ ] Missing required argument → error with useful message.
- [ ] Auth: unauthenticated and unauthorized queries return proper errors (not 200 with null data).
- [ ] Nested resolvers: verify depth limits and N+1 behavior.
- [ ] Schema: introspection confirms types match expected contract.

## Contract Testing (Pact)

### Consumer side

1. Write a Pact test defining the interaction (request + expected response) from the consumer's perspective.
2. Run the Pact test; it generates a `pact.json` file.
3. Publish the pact to the Pact Broker.

### Provider side

1. Pull the latest pact from the Broker.
2. Run provider verification against a running instance of the provider.
3. Publish verification results to the Broker.
4. CI gate: provider must verify all consumer pacts before merging.

### When to use contract tests

- Any service-to-service HTTP call (microservices, BFF, third-party adapters).
- Replace: integration tests that spin up multiple real services together.
- Do not replace: functional tests of business logic within a single service.

## Service Mocking Strategy

| Dependency type | Preferred mock approach |
|---|---|
| Internal services (same team) | Pact contract; mock with WireMock/MSW in tests |
| Internal services (other team) | Pact contract; stub server in CI |
| Third-party APIs (Stripe, Twilio) | Recorded stub or sandbox environment |
| Databases | Test container or in-memory variant |
| Message queues | In-memory broker (e.g., testcontainers Kafka, fake SQS) |

Keep mocks versioned alongside tests; update when the real API changes.

## Schema Validation

- Maintain an OpenAPI (or GraphQL SDL) schema in the repo.
- Generate types from schema; test assertions use generated types, not raw strings.
- Run schema diff on PRs: flag breaking changes (removed fields, changed types).
- Contract tests are the enforcement mechanism for schema stability across services.

## Test Structure

```
tests/
└── api/
    ├── rest/
    │   ├── users.api.test.ts       # endpoint-level tests
    │   └── orders.api.test.ts
    ├── graphql/
    │   └── products.gql.test.ts
    └── contract/
        ├── consumer/
        │   └── users-service.pact.ts
        └── provider/
            └── users-service.verify.ts
```


## Memory Protocol

At **session start**: read `memory/CONTEXT.md` + `memory/handoffs.md` (explorer, architect sections) + skim `memory/open-questions.md` for your open items.

At **session end**: replace your section in `memory/handoffs.md`, append new entries to `memory/decisions.md`, update `memory/open-questions.md`, and update the "Last activity" line in `memory/CONTEXT.md`.

Full protocol and file formats: see [memory-manager skill](../memory-manager/SKILL.md).

## Additional Resources

- See [team-standards.md](../qa-team-orchestrator/team-standards.md) for tool defaults (REST Assured, Supertest, Pact), naming conventions, and CI stages.
