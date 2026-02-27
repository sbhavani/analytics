# Tasks: Dark Mode Theme Switching

**Feature**: Dark Mode Theme Switching
**Branch**: 005-dark-mode
**Generated**: 2026-02-26

## Implementation Strategy

This feature builds on existing dark mode infrastructure (database field, backend endpoint, ThemeContext). The main gap is a quick-access theme toggle in the dashboard header.

**MVP Scope**: User Story 1 - Theme Toggle Access
- A visible toggle button in the dashboard header that allows users to switch themes instantly
- Works with existing persistence (database) and styling (TailwindCSS)

**Incremental Delivery**:
- Phase 1: MVP - Theme toggle component + header integration
- Phase 2: Enhance toggle with visual feedback and keyboard shortcuts
- Phase 3: System preference detection (if not already working)
- Phase 4: Ensure all components have dark mode styling

## Phase 1: Setup

*No setup tasks required - existing infrastructure already in place*

---

## Phase 2: Foundational

*No foundational tasks - existing ThemeContext and backend endpoint are available*

---

## Phase 3: User Story 1 - Theme Toggle Access (Priority: P1)

**Goal**: Provide a visible, accessible theme toggle control in the dashboard header

**Independent Test**: Navigate to dashboard, locate and click theme toggle, verify theme changes immediately without page reload

### Tasks

- [x] T001 [P] [US1] Create ThemeToggle component in assets/js/dashboard/components/theme-toggle.tsx
- [x] T002 [US1] Implement toggleTheme function using existing SettingsController endpoint in assets/js/dashboard/components/theme-toggle.tsx
- [x] T003 [P] [US1] Add accessible button with sun/moon icons in assets/js/dashboard/components/theme-toggle.tsx
- [x] T004 [US1] Integrate ThemeToggle into dashboard header in assets/js/dashboard/nav-menu/top-bar.tsx
- [x] T005 [US1] Add visual feedback (loading state) during theme switch in assets/js/dashboard/components/theme-toggle.tsx
- [ ] T006 [US1] Test theme toggle on all dashboard pages

---

## Phase 4: User Story 2 - Persistent Theme Preference (Priority: P1)

**Goal**: Theme preference persists across sessions (already implemented in backend)

**Independent Test**: Select theme, refresh page, verify same theme persists

### Tasks

- [ ] T007 [US2] Verify existing backend persistence works with new toggle (integration test)
- [x] T008 [P] [US2] Add optimistic UI update for instant feedback in assets/js/dashboard/components/theme-toggle.tsx

---

## Phase 5: User Story 3 - Consistent Styling Across Dashboard (Priority: P1)

**Goal**: All dashboard components respond to theme changes

**Independent Test**: Enable dark mode, verify all pages (nav, cards, tables, forms, modals, charts) use dark theme colors

### Tasks

- [x] T009 [US3] Audit dashboard components for missing dark mode classes
- [x] T010 [US3] Add dark mode classes to navigation components in assets/js/dashboard/nav-menu/*.tsx
- [x] T011 [US3] Add dark mode classes to report/list components in assets/js/dashboard/stats/reports/*.tsx
- [x] T012 [US3] Add dark mode classes to modal components in assets/js/dashboard/stats/modals/*.tsx
- [x] T013 [US3] Add dark mode classes to graph/chart components in assets/js/dashboard/stats/graph/*.tsx
- [x] T014 [US3] Verify Chart.js charts update colors on theme change in assets/js/dashboard/stats/graph/line-graph.js

---

## Phase 6: User Story 4 - System Preference Detection (Priority: P2)

**Goal**: Detect and apply OS theme preference on first visit

**Independent Test**: Set OS to dark mode, visit dashboard with no saved preference, verify dark theme loads automatically

### Tasks

- [x] T015 [US4] Verify existing theme_script in lib/plausible_web/components/layout.ex handles system preference correctly
- [x] T016 [US4] Add listener for OS preference changes while user is on dashboard in assets/js/dashboard/theme-context.tsx

---

## Phase 7: Polish & Cross-Cutting Concerns

### Tasks

- [x] T017 [P] Write Jest tests for ThemeToggle component in assets/js/dashboard/components/theme-toggle.test.tsx
- [x] T018 [P] Write Jest tests for ThemeContext in assets/js/dashboard/theme-context.test.tsx
- [ ] T019 Test theme toggle with keyboard navigation (accessibility)
- [ ] T020 Test theme toggle with screen reader (accessibility)
- [ ] T021 Verify no FOUC (flash of unstyled content) on page load

---

## Dependencies

```
Phase 3 (US1) ──┬──> Phase 4 (US2) ──> Phase 5 (US3) ──> Phase 6 (US4) ──> Phase 7
                │                     │                    │
                └─────────────────────┴────────────────────┘
```

**Parallel Opportunities**:
- T001, T003 can run in parallel (component creation and styling)
- T010, T011, T012, T013 can run in parallel (different component files)
- T017, T018 can run in parallel (different test files)

---

## Summary

| User Story | Tasks | Status |
|------------|-------|--------|
| US1: Theme Toggle Access | T001-T006 | 5/6 complete, T017 complete (T006/T019-T021 testing pending) |
| US2: Persistent Preference | T007-T008 | 1/2 complete (T007 testing pending) |
| US3: Consistent Styling | T009-T014 | Complete |
| US4: System Preference | T015-T016 | Complete |
| Polish | T018-T021 | T017 complete |
| **Total** | **21 tasks** | **16 complete, 5 pending** |

---

## File Paths Reference

### New Files to Create
- `assets/js/dashboard/components/theme-toggle.tsx` - Theme toggle component
- `assets/js/dashboard/components/theme-toggle.test.tsx` - Tests for toggle

### Files to Modify
- `assets/js/dashboard/nav-menu/top-bar.tsx` - Add toggle to header
- `assets/js/dashboard/theme-context.tsx` - Add OS preference listener
- `assets/js/dashboard/nav-menu/*.tsx` - Add dark mode classes
- `assets/js/dashboard/stats/reports/*.tsx` - Add dark mode classes
- `assets/js/dashboard/stats/modals/*.tsx` - Add dark mode classes
- `assets/js/dashboard/stats/graph/*.tsx` - Add dark mode classes

### Existing Infrastructure (No Changes Needed)
- `lib/plausible/auth/user.ex` - theme field and changeset
- `lib/plausible_web/controllers/settings_controller.ex` - update_theme endpoint
- `lib/plausible_web/components/layout.ex` - theme_script
- `assets/js/dashboard/theme-context.tsx` - existing context
- `assets/css/app.css` - existing dark mode styles
