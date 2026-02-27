# Design Checklist

Use at each phase of design. Check items off as you go — don't treat this as a pre-launch audit.

---

## Phase 1: Research & Problem Definition

- [ ] Problem statement written (from PM or your own research synthesis)
- [ ] Target user(s) identified — not "everyone"
- [ ] User jobs-to-be-done (JTBD) stated
- [ ] Existing user research reviewed (interviews, sessions, analytics, support)
- [ ] Competitor / prior art reviewed; patterns users already know identified
- [ ] Key constraints documented (platform, tech, brand, time, accessibility)
- [ ] Success metric defined — how will we know the design is working?

---

## Phase 2: Information Architecture

- [ ] Content inventory created (what exists, what's new, what's removed)
- [ ] Content hierarchy established (primary / secondary / tertiary)
- [ ] Navigation model chosen (global, local, utility) and justified
- [ ] Site map or flow map drafted in text or diagram
- [ ] Entry points and exit points identified
- [ ] Deep links / direct URLs considered
- [ ] Search and discoverability addressed if content volume warrants it

---

## Phase 3: User Flows

For each major flow:
- [ ] Happy path mapped end-to-end
- [ ] All error paths mapped (what can fail, what does the user see, how do they recover)
- [ ] Empty states included (no data yet, just created, nothing matches filters)
- [ ] Loading states included (instant < 100ms, skeleton 100ms–1s, progress indicator > 1s)
- [ ] Edge cases listed (max content length, no permissions, offline, session expired)
- [ ] All user decisions and system responses named explicitly
- [ ] Flow validated against JTBD — does completing the flow fulfill the user's goal?

---

## Phase 4: Visual Design & Components

### Layout
- [ ] 8-point grid used for all spacing
- [ ] Max-width container defined to prevent ultra-wide line lengths
- [ ] Gutters and column counts specified per breakpoint
- [ ] Z-index layers documented (base, sticky, dropdown, modal, toast, tooltip)

### Typography
- [ ] Type scale defined using tokens (not raw pixel values)
- [ ] Font pairing: maximum 2 typefaces
- [ ] Heading hierarchy (h1–h4) defined; only one h1 per page
- [ ] Line length: 45–75 characters for body text
- [ ] Line height: 1.5 for body, 1.25 for headings
- [ ] All text styles covered: headings, body, captions, labels, code, numeric/tabular

### Color
- [ ] All colors expressed as design tokens
- [ ] Color palette covers: brand, neutral scale, semantic (success/warning/error/info)
- [ ] Text color tokens: primary, secondary, disabled, inverse
- [ ] Surface tokens: base, raised, overlay, tooltip
- [ ] Border tokens: default, focus, error, divider
- [ ] Dark mode tokens defined (if applicable)

### Contrast (WCAG 2.1 AA minimum)
- [ ] Normal text (< 18px regular, < 14px bold): contrast ≥ 4.5:1
- [ ] Large text (≥ 18px regular, ≥ 14px bold): contrast ≥ 3:1
- [ ] UI components and graphical objects: contrast ≥ 3:1 against adjacent colors
- [ ] Focus indicators: contrast ≥ 3:1 against adjacent background

### Iconography
- [ ] Icon style consistent (outline, filled, or duotone — pick one)
- [ ] Icon size consistent with touch target requirements (≥ 44×44px interactive area)
- [ ] Icons used alongside text labels wherever possible (don't rely on icon alone)
- [ ] Icon-only controls have accessible name via aria-label or title

### Imagery & Illustration
- [ ] Images have meaningful alt text; decorative images have alt=""
- [ ] No critical information conveyed only through images
- [ ] Images load progressively (blur-up, skeleton, or aspect-ratio placeholder)
- [ ] Retina / @2x assets specified where needed

### Motion & Animation
- [ ] All animations have a purpose (not decorative motion)
- [ ] Duration tokens used: fast (100ms), normal (200ms), slow (300ms)
- [ ] Easing specified per animation type (ease-out for entering, ease-in for exiting)
- [ ] `prefers-reduced-motion` respected — animations collapse to instant transitions
- [ ] No flashing content that exceeds 3 flashes per second

---

## Phase 5: Component Completeness

For every new or modified component:
- [ ] All states designed: default, hover, focus, active, disabled, loading, error, success, empty
- [ ] Anatomy documented (every named sub-part)
- [ ] Spacing specified using tokens (internal padding, gap, margin)
- [ ] Typography specified using tokens
- [ ] Max/min width and overflow behavior defined
- [ ] Truncation strategy for long text (ellipsis, wrap, scroll — when and where)
- [ ] Right-to-left (RTL) considered if internationalization is a requirement
- [ ] Component documented in the design system (or tagged for addition)

---

## Phase 6: Accessibility (WCAG 2.1 AA)

### Perceivable
- [ ] All non-text content has a text alternative (alt, aria-label, aria-labelledby)
- [ ] Color is never the only means of conveying information
- [ ] Content is readable and functional at 200% zoom
- [ ] Text can be resized up to 200% without loss of content or functionality

### Operable
- [ ] All functionality available via keyboard
- [ ] No keyboard trap (user can always Tab out of any component)
- [ ] Focus order is logical and matches visual reading order
- [ ] Visible focus indicator on every focusable element (not hidden by `outline: none`)
- [ ] Skip links provided for repeated navigation blocks
- [ ] Sufficient time for timed interactions; user can extend or disable time limits
- [ ] No content that auto-plays audio or video for > 3 seconds without user control

### Understandable
- [ ] Page language declared (`lang` attribute on `<html>`)
- [ ] Labels and instructions are clear; no placeholder-only form inputs
- [ ] Error messages identify the field and describe how to fix it (not just "invalid")
- [ ] Consistent navigation across pages (same order, same labels)
- [ ] No unexpected context changes on focus or on input (e.g., no auto-submit)

### Robust
- [ ] Semantic HTML used (buttons are `<button>`, links are `<a>`, headings are `<h1>`–`<h6>`)
- [ ] ARIA roles and attributes used correctly; native HTML preferred
- [ ] Live regions (`aria-live`) used for dynamic content (toasts, status updates, errors)
- [ ] Forms: inputs have associated `<label>` (not just aria-label); fieldsets and legends for groups

### Touch & Mobile
- [ ] Touch targets ≥ 44×44px
- [ ] Sufficient spacing between adjacent touch targets (≥ 8px gap)
- [ ] No functionality requires hover-only interaction (hover doesn't exist on touch)
- [ ] Gestures have alternatives (swipe-to-delete also has a visible button)

---

## Phase 7: Responsive Design

For each breakpoint (base, sm 640px, md 768px, lg 1024px, xl 1280px):
- [ ] Layout reflow verified (no horizontal scroll, no overflow)
- [ ] Navigation pattern changes documented (hamburger, bottom bar, etc.)
- [ ] Image sizing and aspect ratios specified per breakpoint
- [ ] Touch target sizes adequate on mobile (≥ 44×44px)
- [ ] Font sizes readable at each breakpoint (body ≥ 16px on mobile)
- [ ] Tables have a responsive strategy (horizontal scroll, card view, or column priority)

---

## Phase 8: Engineering Handoff

- [ ] Design tokens exported as JSON (or Tailwind config, CSS custom properties)
- [ ] Every component has: anatomy, states, spacing, typography, and interaction specs
- [ ] Animations specify: trigger, duration, easing, reduced-motion fallback
- [ ] ARIA roles and keyboard behavior specified for custom interactive components
- [ ] Responsive behavior described per component per breakpoint
- [ ] Edge cases (empty, error, loading, max content) designed and handed off
- [ ] Asset export settings specified (SVG for icons, WebP + fallback for images)

---

## Phase 9: QA Handoff

- [ ] List of screens and states to visually verify
- [ ] Accessibility testing scope (axe-core automated + manual keyboard + screen reader)
- [ ] Responsive breakpoints to test
- [ ] Browsers / OS to cover (minimum: Chrome, Firefox, Safari, Edge; iOS Safari, Android Chrome)
- [ ] Dark mode testing (if applicable)
- [ ] prefers-reduced-motion testing
- [ ] Performance budget: images optimized, no unnecessary animations in critical path

---

## Phase 10: Post-Launch Review

- [ ] Primary success metric measured (defined in Phase 1)
- [ ] Usability issues logged from session recordings / support tickets
- [ ] Accessibility issues from audit or user feedback tracked
- [ ] Design system updated with any new patterns introduced
- [ ] Learnings documented for future features in this area
