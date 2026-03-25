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


## AI-Assisted QA for Hybrid (Capacitor/WebView) Apps

Source: [Teaching Claude to QA a Mobile App](https://christophermeiklejohn.com/ai/zabriskie/development/android/ios/2026/03/22/teaching-claude-to-qa-a-mobile-app.html) — Meiklejohn, 2026

### Android via Chrome DevTools Protocol (CDP)

Capacitor's WebView exposes a CDP socket on Android. Use it for programmatic control without coordinate guessing:

```bash
# Port-forward app backend (emulator localhost ≠ host localhost)
adb reverse tcp:3000 tcp:3000
adb reverse tcp:8080 tcp:8080

# Discover and forward the WebView DevTools socket
WV_SOCKET=$(adb shell "cat /proc/net/unix" | grep webview_devtools_remote | grep -oE 'webview_devtools_remote_[0-9]+' | head -1)
adb forward tcp:9223 localabstract:$WV_SOCKET
curl http://localhost:9223/json   # list debuggable pages
```

With CDP connected you can:
- **Authenticate** via `localStorage.setItem(...)` — no UI login flow needed.
- **Navigate** screens via `window.location.href` or framework router calls.
- **Screenshot** each screen programmatically, upload to S3, file bug reports.

A Python sweep of 25 screens completes in ~90 seconds. File bugs as `[Android QA] [Screen Name]: [Issue]`.

### iOS Simulator — the Hard Path

iOS WKWebView does **not** expose CDP (Safari uses a proprietary binary protocol). Workarounds:

**Authentication:**
- Deep linking often fails (stale bundles, IPv6/IPv4 mismatch, JWT issues). Fallback: modify backend to accept `username` in addition to `email`, change `<input type="email">` → `type="text"`, use a simple test username with no `@` (AppleScript can't type `@`).

**Dismissing native permission dialogs before they block the WebView:**
```bash
# Write TCC permissions directly before app install
sqlite3 ~/Library/Developer/CoreSimulator/Devices/<UDID>/data/Library/TCC/TCC.db \
  "INSERT OR REPLACE INTO access VALUES('kTCCServiceUserNotification','<bundle_id>',0,2,4,1,NULL,NULL,0,'',0,0,NULL,NULL,0);"
# Restart SpringBoard, then install app
xcrun simctl spawn booted launchctl stop com.apple.SpringBoard
```

Sequence matters: **uninstall → write TCC → restart SpringBoard → reinstall → launch → login**.

**UI Coordinate Navigation (three approaches, ranked):**

| Approach | Accuracy | Notes |
|---|---|---|
| AppleScript `click at {x,y}` | ~42% | Window/device offsets, scaling modes make translation unreliable |
| Facebook `idb ui tap` | ~57% | Logical points are better but dropdown coords still drift |
| `ios-simulator-mcp ui_describe_point` + `idb ui tap` | ~100% | Probe in 48pt increments to discover real button positions, then tap with idb |

Always add 1.5 s wait after each tap to allow animations to complete before screenshotting.

### Visual QA Workflow

1. Iterate all target screens; take a screenshot of each.
2. Analyze each screenshot for: broken layouts, missing images, blank screens, unexpected auth errors.
3. Maintain a **known-issues allowlist** (empty avatars, "Forbidden" for non-member views) to suppress false positives.
4. Upload failing screenshots to cloud storage; file structured bug reports with screen name, platform, and description.
5. Schedule as a daily morning job to catch overnight breakage.

### Isolation Discipline (AI-specific)

When Claude drives the QA scripts, run in a **git worktree** (`git worktree add`). Without isolation, a "quick look" outside the worktree can accidentally commit unrelated changes (QA endpoints, unrelated features) in the same branch, requiring painful untangling across multiple PRs.

Always: run tests → read output → fix → verify locally → push. Never "push and pray."

### Key Platform Difference

| | Android | iOS Simulator |
|---|---|---|
| WebView protocol | CDP (open, scriptable) | Proprietary (Safari only) |
| Auth approach | `localStorage` via CDP | Coordinate-based UI + backend hack |
| Navigation | JS evaluation via CDP | Tap coordinates (idb + describe_point) |
| Setup time | ~90 min | 6+ hours |

**Recommended ask to Apple:** expose CDP or WebDriver for Simulator WebViews.

## Memory Protocol

**Start**: `bd ready` → claim → read CONTEXT.md + handoffs (explorer, designer, architect) + open-questions.
**End**: `--status done` → update handoffs.md, decisions.md, open-questions.md, CONTEXT last-activity.
→ Full protocol: [memory-manager](../memory-manager/SKILL.md) · Standards: [team-standards.md](../qa-team-orchestrator/team-standards.md)
