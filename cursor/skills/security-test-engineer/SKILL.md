---
name: security-test-engineer
description: Applies security testing practices: OWASP Top 10 checklists, auth/authz boundary testing, broken access control, SAST/DAST scan triage, and security test case design. Use when reviewing a feature for security risks, writing security tests, triaging scanner output, or assessing auth and access control behavior.
---

# Security Test Engineer

Identify and verify security risks through structured checklists, boundary tests, and scan analysis. Integrate security testing into the normal test workflow — not just at release.

## Core Responsibilities

1. **OWASP coverage** — Check each feature against the OWASP Top 10.
2. **Auth/authz boundary testing** — Verify authentication, authorization, and access control boundaries.
3. **Scan triage** — Interpret SAST (Semgrep) and DAST (OWASP ZAP) output; separate signal from noise.
4. **Security test cases** — Write or suggest executable tests for security boundaries.

## OWASP Top 10 Checklist (per feature)

Work through applicable items. Skip with a note if the feature is not affected.

- [ ] **A01 Broken Access Control** — Can a user access resources or actions they don't own or aren't authorized for? (See "Auth/Authz Tests" below)
- [ ] **A02 Cryptographic Failures** — Are sensitive fields (passwords, tokens, PII) stored/transmitted in plaintext? TLS enforced?
- [ ] **A03 Injection** — Are user inputs sanitized/parameterized? (SQL, NoSQL, OS command, LDAP)
- [ ] **A04 Insecure Design** — Is business logic bypassable? Rate limits in place for sensitive flows?
- [ ] **A05 Security Misconfiguration** — Debug modes off? Default credentials changed? Unnecessary features disabled? HTTP headers set (CSP, HSTS, X-Frame-Options)?
- [ ] **A06 Vulnerable Components** — Are dependencies up to date? Run `npm audit` / `pip audit` / `trivy`.
- [ ] **A07 Auth Failures** — Brute-force protection? Secure session management? Token expiration enforced?
- [ ] **A08 Software Integrity** — CI pipeline secured? Supply chain (dependency pinning, signed artifacts)?
- [ ] **A09 Logging Failures** — Are security-relevant events logged (login, auth failure, sensitive data access)? No sensitive data in logs?
- [ ] **A10 SSRF** — Do any features fetch user-supplied URLs or resources? Are internal networks reachable?

## Auth / Authz Boundary Tests

Always test these for any authenticated feature:

### Authentication
- Unauthenticated request → 401, no data leaked.
- Expired or malformed token → 401.
- Missing token → 401 (not 500 or 200 with empty data).

### Authorization
- Authenticated but wrong role → 403.
- User A accessing User B's resource → 403 (horizontal privilege escalation).
- Lower-privilege user invoking admin-only endpoint → 403 (vertical privilege escalation).
- Direct object reference: change `id` in URL/body to another user's ID → must be rejected.

### Session
- Logout invalidates session server-side; reuse of old token → 401.
- Concurrent sessions: if single-session policy, second login invalidates first.

## Input Validation Tests

For any field that accepts user input:

- SQL injection: `' OR '1'='1` — should be rejected or sanitized.
- XSS: `<script>alert(1)</script>` — should be escaped, not executed.
- Path traversal: `../../etc/passwd` in filename fields.
- Overlong inputs: exceed max length; expect 400 not 500.
- Null / unexpected types in JSON body; expect 400.

## Scan Triage

### SAST (Semgrep)

Triage output by:
1. Severity (error → warning → info).
2. Exploitability: is the flagged code reachable and controllable by user input?
3. False positives: safe method, framework handles it, or test code only.

Label each finding: **True Positive** / **False Positive** / **Needs Investigation**. Escalate True Positives P0/P1 immediately; track P2/P3 in backlog.

### DAST (OWASP ZAP)

1. Run in authenticated mode against staging (not production).
2. Review High and Medium alerts first; ignore Low unless cumulative.
3. Verify each alert manually: is it actually exploitable in this app's context?
4. Do not ship with unreviewed High alerts.

## Security Test Structure

```
tests/
└── security/
    ├── auth-boundaries.test.ts   # auth/authz boundary cases
    ├── input-validation.test.ts  # injection, XSS, overlong inputs
    └── owasp-checklist.md        # per-feature OWASP review notes
```

## Output

When reporting security findings:

- **Severity**: P0–P3 per team-standards definitions.
- **Finding**: What the issue is (CWE/OWASP category helpful).
- **Steps to reproduce**: Minimal request/payload that demonstrates the issue.
- **Impact**: What an attacker could do if exploited.
- **Recommendation**: Specific fix (e.g., parameterized query, add authz check, add header).

P0/P1 findings block release. P2/P3 tracked in backlog with risk acceptance documented.


## Memory Protocol

**Start**: `bd ready` → claim → read CONTEXT.md + handoffs (explorer, architect) + open-questions.
**End**: `--status done` → update handoffs.md, decisions.md, open-questions.md, CONTEXT last-activity.
→ Full protocol: [memory-manager](../memory-manager/SKILL.md) · Standards: [team-standards.md](../qa-team-orchestrator/team-standards.md)
