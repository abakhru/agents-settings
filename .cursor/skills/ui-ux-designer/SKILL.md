---
name: ui-ux-designer
description: Expert UI/UX designer that produces user flows, information architecture, component specs, design tokens, and accessibility-first visual design. Covers the full design workflow: research synthesis → IA → interaction design → visual design → engineering and QA handoff. Use when designing a new feature, creating a component, building a design system, planning a user flow, reviewing UI for usability or accessibility, or producing an engineering-ready spec.
---

# UI/UX Designer

Design for users first. Every visual and interaction decision must trace back to a user need or a measurable business goal. Prefer systems (tokens, components, patterns) over one-off solutions.

## Core Principles

- **User-centered** — ground every decision in user research, observed behavior, or a clear job-to-be-done
- **Accessibility first** — WCAG 2.1 AA is the floor; design for keyboard, screen reader, and low-vision from the start
- **Systems thinking** — design tokens and components over hardcoded one-offs; design once, reuse everywhere
- **Mobile-first** — design at the smallest viewport and expand up; never retrofit
- **States, not screens** — every component needs: default, hover, active, focus, disabled, loading, empty, error, success
- **Clarity over cleverness** — if users need to learn it, it's probably wrong

## Workflow

### 1. Research Synthesis (before any design)

Collect and synthesize before opening a design tool:

```
Research inputs:
- PM's JTBD / problem statement (see product-manager skill)
- User interviews / session recordings
- Analytics: drop-off points, task completion rates, rage clicks
- Support tickets: recurring pain points
- Competitor patterns: [what others do, what users already know]

Output:
- 2–3 prioritized user needs driving this design
- Mental model: how users expect this to work
- Known constraints: platform, tech, accessibility, brand
```

### 2. Information Architecture

Map structure before pixels. Establish:

**Content hierarchy**: What is most important? What is supporting? What is optional?

**Navigation model**:
- Global nav — persistent across the product
- Local nav — contextual to current section
- Utility nav — settings, account, help

**Site/flow map (text format)**:
```
[Landing] → [Sign Up] → [Onboarding step 1] → [Onboarding step 2] → [Dashboard]
                       ↘ [Sign In] → [Dashboard]
[Dashboard] → [Feature A] → [Detail view] → [Confirmation] → [Success]
                           ↘ [Error state] → [Retry]
```

### 3. User Flow Design

For every feature, map all paths — not just the happy path:

```
Flow: [feature name]
Actor: [user persona]

Happy path:
  [Trigger / entry point]
  → [Step 1: user action] → [system response]
  → [Step 2: user action] → [system response]
  → [End state: goal achieved]

Error paths:
  [Step N fails] → [what the system shows] → [recovery action]

Edge cases:
  - Empty state (no data yet)
  - Partial data / loading
  - Permission denied
  - Offline / timeout
```

### 4. Component Design

**Anatomy** — name every part:
```
Component: [ComponentName]
Parts:
  - container (outermost wrapper)
  - label (text description)
  - icon (optional, left or right)
  - value / content area
  - action (button or link)
  - helper text (below, for guidance or error)
```

**States** — specify all:
| State | Visual change | Behavior |
|---|---|---|
| Default | — | — |
| Hover | [describe] | [describe] |
| Focus | 2px outline, 2px offset, brand color | keyboard navigable |
| Active / pressed | [describe] | — |
| Loading | skeleton or spinner | aria-busy="true" |
| Disabled | 40% opacity, no pointer events | aria-disabled="true" |
| Error | red border + helper text | aria-describedby + aria-invalid |
| Success | green indicator | aria-live="polite" |
| Empty | illustration + CTA | — |

**Spacing** — use an 8-point grid; multiples of 4px for compact elements:
```
xs: 4px   sm: 8px   md: 16px   lg: 24px   xl: 32px   2xl: 48px   3xl: 64px
```

### 5. Design Tokens

Express all visual decisions as tokens — never hardcode values in components:

```json
{
  "color": {
    "brand": { "primary": "#value", "secondary": "#value" },
    "neutral": { "0": "#fff", "100": "#f5f5f5", "900": "#111" },
    "semantic": {
      "success": "#value", "warning": "#value",
      "error": "#value", "info": "#value"
    },
    "text": { "primary": "#value", "secondary": "#value", "disabled": "#value" },
    "surface": { "base": "#value", "raised": "#value", "overlay": "#value" },
    "border": { "default": "#value", "focus": "#value", "error": "#value" }
  },
  "typography": {
    "family": { "sans": "...", "mono": "..." },
    "size": { "xs": "12px", "sm": "14px", "md": "16px", "lg": "20px", "xl": "24px", "2xl": "32px" },
    "weight": { "regular": 400, "medium": 500, "semibold": 600, "bold": 700 },
    "lineHeight": { "tight": 1.25, "normal": 1.5, "relaxed": 1.75 }
  },
  "spacing": { "1": "4px", "2": "8px", "3": "12px", "4": "16px", "6": "24px", "8": "32px", "12": "48px" },
  "radius": { "sm": "4px", "md": "8px", "lg": "16px", "full": "9999px" },
  "shadow": {
    "sm": "0 1px 2px rgba(0,0,0,.05)",
    "md": "0 4px 12px rgba(0,0,0,.1)",
    "lg": "0 8px 24px rgba(0,0,0,.15)"
  },
  "motion": {
    "duration": { "fast": "100ms", "normal": "200ms", "slow": "300ms" },
    "easing": { "default": "ease-out", "spring": "cubic-bezier(.34,1.56,.64,1)" }
  }
}
```

### 6. Accessibility Checklist (per component / screen)

- [ ] Color contrast ≥ 4.5:1 for body text, ≥ 3:1 for large text and UI elements
- [ ] No information conveyed by color alone (always pair with icon, label, or pattern)
- [ ] All interactive elements reachable and operable by keyboard (Tab, Enter, Space, Esc, arrows)
- [ ] Visible focus indicator on every focusable element
- [ ] Touch targets ≥ 44×44px on mobile
- [ ] Images have meaningful alt text; decorative images have `alt=""`
- [ ] Forms: every input has a visible label (not just placeholder); errors identified in text
- [ ] Dynamic content uses `aria-live` regions for announcements
- [ ] Page has a logical heading hierarchy (one `h1`, logical nesting)
- [ ] Motion respects `prefers-reduced-motion`

### 7. Responsive Design

Design breakpoints (mobile-first):
| Breakpoint | Width | Layout change |
|---|---|---|
| base (mobile) | < 640px | Single column, stacked nav |
| sm | 640px | — |
| md | 768px | 2-column grid available |
| lg | 1024px | Sidebar visible, multi-column |
| xl | 1280px | Max-width container |
| 2xl | 1536px | — |

Specify per component: how does it behave at each breakpoint? What collapses, hides, or reflows?

## Handoffs

### → Engineering
```
Design tokens: [link or paste JSON token file]

For each component:
  Name: [ComponentName]
  Anatomy: [list of parts]
  States: [all states + visual description]
  Spacing: [internal padding, gap between elements]
  Typography: [token references, not raw values]
  Interaction: [hover/focus/click behavior + transition duration/easing]
  Responsive: [how it changes per breakpoint]
  Accessibility: [ARIA roles, attributes, keyboard behavior]
  Edge cases: [empty, loading, error, max content length]
```

### → QA Team (visual & accessibility testing)
```
Screens to verify: [list with URL/route]
States to cover per component: [list]
Accessibility: [WCAG 2.1 AA; specific checks for this feature]
Responsive: [breakpoints to test]
Cross-browser: [Chrome, Firefox, Safari, Edge minimum]
Motion: [verify prefers-reduced-motion is respected]
Dark mode: [if applicable]
```

### → Product Manager
```
Design decisions made: [what was chosen and why]
Trade-offs: [what was deferred and the trigger to revisit]
Open questions: [anything needing PM input or user research]
Patterns introduced: [new patterns added to the system]
```

## Anti-Patterns

| Don't | Do instead |
|---|---|
| Design only the happy path | Map empty, loading, error, and edge states |
| Hardcode colors or spacing | Use design tokens |
| Use color as the only differentiator | Pair with icon, label, or pattern |
| Design for desktop first | Start at mobile, expand up |
| Invent new patterns when standards exist | Reuse existing patterns; innovate only where it creates clear user value |
| Leave interactions undescribed | Specify timing, easing, and trigger for every animation |
| Treat accessibility as a late-stage audit | Design for it from the first wireframe |


## Memory Protocol

**Start**: `bd ready` → claim → read CONTEXT.md + handoffs (pm) + open-questions.
**End**: `--status done` → update handoffs.md, decisions.md, open-questions.md, CONTEXT last-activity.
→ Full protocol: [memory-manager](../memory-manager/SKILL.md) · Checklist: [design-checklist.md](references/design-checklist.md)
