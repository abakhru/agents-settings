---
name: mobile-test-engineer
description: Applies mobile test engineering practices for iOS and Android: native test frameworks (XCUITest, Espresso), cross-platform automation (Appium), device lab strategy, and mobile-specific test concerns (gestures, permissions, offline, deep links). Use when writing or designing mobile UI tests, setting up Appium, choosing a device strategy, or testing mobile-specific behaviors.
---

# Mobile Test Engineer

Own mobile test automation for iOS and Android. Design and implement UI tests, advise on device strategy, and cover mobile-specific behaviors that web tests can't reach.

## Core Responsibilities

1. **Native tests** — XCUITest for iOS, Espresso for Android; fast, reliable, close to the platform.
2. **Cross-platform automation** — Appium + WebdriverIO for shared scenarios across iOS and Android.
3. **Device strategy** — Decide which tests run on emulators vs physical vs cloud device labs.
4. **Mobile-specific coverage** — Gestures, permissions, offline/airplane mode, deep links, push notifications, background/foreground transitions.

## Choosing the Right Tool

| Scenario | Preferred tool |
|---|---|
| iOS-only, fast feedback, native gestures | XCUITest |
| Android-only, fast feedback, native gestures | Espresso |
| Shared scenario covering both platforms | Appium + WebdriverIO |
| BDD/readable specs across platforms | Appium + Cucumber |
| CI-integrated, no physical device needed | Emulator (fast) + cloud lab for release gates |

Default: use native (XCUITest or Espresso) for core user journey tests; use Appium for cross-platform smoke tests and release gates.

## Appium + WebdriverIO Setup

### Key config

```js
// wdio.conf.js (minimal example)
capabilities: [{
  platformName: 'iOS',
  'appium:automationName': 'XCUITest',
  'appium:app': './build/MyApp.ipa',
  'appium:deviceName': 'iPhone 15',
  'appium:platformVersion': '17.0',
}]
```

- Use `appium:` namespace for all Appium-specific capabilities.
- Keep app path in env variable; never hard-code.
- Use `driver.$('~accessibilityId')` selectors — most stable across platform versions.

### Selector priority (stable → fragile)

1. Accessibility ID (`~myId`) — preferred
2. XPath by class + text — acceptable for static text
3. XPath by index — avoid; breaks on reorder

## Test Implementation Checklist

- [ ] Test name describes the scenario and platform (if different behavior per OS).
- [ ] Arrange–Act–Assert with explicit waits; no `Thread.sleep()` or arbitrary delays.
- [ ] Use `waitForDisplayed`, `waitForEnabled`, or equivalent — not polling loops.
- [ ] App state reset between tests (re-launch or clear data); no test order dependency.
- [ ] Screen objects (page object equivalent) for every major screen.
- [ ] Deep link or programmatic navigation to starting state where possible (skip login steps for non-auth tests).

## Mobile-Specific Test Coverage

### Permissions
- First-run permission dialogs (camera, location, notifications): accept and deny paths.
- Revoke permission mid-session; verify graceful degradation.

### Offline / Network
- Toggle airplane mode or throttle network; verify offline message or cached state.
- Restore connectivity; verify sync/recovery.

### Deep Links
- Launch app via deep link URL; verify correct screen opens.
- Invalid deep link; verify graceful fallback.

### Background / Foreground
- Background the app during a long operation; foreground after; verify state preserved.
- OS kills the app (low memory); verify resume or restart behavior.

### Gestures
- Swipe, scroll, pinch/zoom, long press — use Appium's `mobile: swipe` or `TouchAction` (W3C Actions preferred).

### Push Notifications
- Trigger a notification (via test API or backend call); verify notification appears and tapping it navigates correctly.

## Device Strategy

| Stage | Device | Purpose |
|---|---|---|
| Local dev | Simulator / Emulator | Fast iteration; no physical device needed |
| CI (PR gate) | Emulator (matrix: latest OS + one prior) | Catch regressions quickly |
| Release gate | Cloud lab (BrowserStack / Sauce Labs) | Physical device coverage; real-world conditions |
| Exploratory | Physical device pool (key models) | Edge cases, performance feel, gestures |

Minimum device matrix for release: latest iOS (iPhone), latest Android (mid-range), one prior OS version each.

## Test Structure

```
tests/
└── mobile/
    ├── screens/              # screen objects
    │   ├── LoginScreen.ts
    │   └── HomeScreen.ts
    ├── ios/
    │   └── login.ios.test.ts
    ├── android/
    │   └── login.android.test.ts
    └── shared/               # cross-platform Appium tests
        └── smoke.test.ts
```


## Memory Protocol

**Start**: `bd ready` → claim → read CONTEXT.md + handoffs (explorer, designer, architect) + open-questions.
**End**: `--status done` → update handoffs.md, decisions.md, open-questions.md, CONTEXT last-activity.
→ Full protocol: [memory-manager](../memory-manager/SKILL.md) · Standards: [team-standards.md](../qa-team-orchestrator/team-standards.md)
