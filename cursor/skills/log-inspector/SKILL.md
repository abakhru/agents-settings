---
name: log-inspector
description: >
  Analyzes console logs for errors, warnings, and potential security issues.
  Reports JavaScript errors, failed requests, and sensitive information leaks.
---

# Log-Inspector — Console Logs

**check_types**: [console-logs]

## Analysis Criteria

Analyse the console messages for:

**Console Issues:**
- JavaScript errors and exceptions
- Warning messages indicating problems
- Failed network requests
- Deprecation warnings
- Performance warnings
- Memory leak indicators
- Resource loading failures
- Third-party script errors
- Debug logs left in production
- Sensitive information in console logs
- API errors with status codes

*Note: bug_confidence is always 10 for confirmed console issues*
