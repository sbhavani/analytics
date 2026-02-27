# Implementation Plan: Dark Mode Theme Switching

**Branch**: `005-dark-mode` | **Date**: 2026-02-26 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/005-dark-mode/spec.md`

## Summary

Implement theme switching with dark mode option that persists user preference and applies consistent styling across the dashboard. The existing codebase already has TailwindCSS dark mode variant configured (`.dark` class-based), requiring: (1) theme toggle UI component, (2) localStorage persistence, (3) OS preference detection, and (4) comprehensive dark styling for all dashboard components.

## Technical Context

**Language/Version**: TypeScript 5.5.4, React 18.3.1, Elixir 1.16
**Primary Dependencies**: TailwindCSS v4, React Router v6, Chart.js 3.x
**Storage**: localStorage for theme preference persistence
**Testing**: Jest 29.7 (JavaScript), ExUnit (Elixir backend)
**Target Platform**: Web browser (modern browsers supporting CSS custom properties)
**Project Type**: Web application / Analytics dashboard
**Performance Goals**: Theme switch completes in under 2 seconds (per SC-001)
**Constraints**: Must work without JavaScript errors; graceful degradation if localStorage unavailable
**Scale/Scope**: All dashboard pages and components

## Constitution Check

*Gate: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Status | Notes |
|------|--------|-------|
| **Test-Driven Development** | REQUIRES ATTENTION | Frontend tests (Jest) must be written for theme switching functionality |
| **Privacy-First** | PASS | Theme preference is non-personal, stored locally only |
| **Performance** | PASS | No backend impact; frontend-only feature |
| **Simplicity** | PASS | Single toggle component + context provider pattern |

## Project Structure

### Documentation (this feature)

```
specs/005-dark-mode/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (if applicable)
└── tasks.md             # Phase 2 output
```

### Source Code (repository root)

```
assets/
├── js/
│   ├── components/      # Theme toggle component
│   ├── contexts/        # Theme context provider
│   ├── hooks/          # useTheme hook
│   └── lib/            # Theme utilities
├── css/
│   └── app.css         # Existing dark mode styles
└── test/               # Jest tests

lib/plausible_web/
├── components/          # Phoenix components (if needed)
└── templates/          # Layout templates
```

**Structure Decision**: Feature implemented in frontend assets only (React/TypeScript + TailwindCSS). No backend changes required - theme preference stored in browser localStorage.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No complexity violations. Simple frontend-only feature using established patterns.

---

## Phase 0: Research

### Research Findings

**Decision**: Use React Context + Hook pattern with localStorage persistence
**Rationale**: Standard approach for React theme management; works with existing TailwindCSS dark mode variant

**Alternatives considered**:
1. CSS-only with media queries - Rejected: No user preference persistence
2. Redux state - Rejected: Overkill for single preference value
3. Server-side preference storage - Rejected: Adds complexity; localStorage sufficient

### Technical Implementation Notes

- TailwindCSS dark mode uses `.dark` class on HTML element
- Existing CSS already has `@custom-variant dark (&:where(.dark, .dark *))` configured
- Theme detection: `window.matchMedia('(prefers-color-scheme: dark)')`
- Storage key: `theme_preference` (values: 'light' | 'dark' | 'system')

## Phase 1: Design

### Data Model

**ThemePreference** (localStorage)
- `theme_preference`: 'light' | 'dark' | 'system'
- Default: 'system' (falls back to OS preference)

### Interface Contracts

No external API contracts required - pure frontend feature.

### Component Design

```
ThemeProvider (Context)
├── value: { theme, setTheme, toggleTheme }
└── handles: OS detection, localStorage sync, HTML class injection

ThemeToggle (Component)
├── props: { className?, size? }
└── UI: Button with sun/moon icons, accessible
```

### Quickstart

1. Add `ThemeProvider` to app root
2. Place `<ThemeToggle />` in dashboard header/nav
3. All components already have dark mode classes via TailwindCSS

---

## Implementation Approach

1. **Theme Context**: Create React context managing theme state with localStorage sync
2. **Toggle Component**: Build accessible theme toggle with visual feedback
3. **OS Detection**: Implement system preference detection on initial load
4. **HTML Integration**: Apply/remove `.dark` class on `<html>` element
5. **Testing**: Write Jest tests for theme switching, persistence, and OS detection

## Known Considerations

- Chart.js charts need theme-aware color updates
- Flatpickr date picker has separate dark theme CSS file
- Some legacy components may need dark mode class additions
