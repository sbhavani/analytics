---

description: "Task list for dark mode feature"
---

# Tasks: Dark Mode

**Input**: Design documents from `/specs/001-dark-mode/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md

**Note**: Dark mode is already fully implemented in this codebase. This tasks.md documents verification and enhancement opportunities.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Verification (Feature Already Implemented)

**Purpose**: Verify existing dark mode implementation works correctly

### Implementation Verification

- [x] T001 [P] Verify User.theme field in lib/plausible/auth/user.ex has enum values :system, :light, :dark
- [x] T002 [P] Verify Plausible.Themes.options() returns correct options in lib/plausible/themes.ex
- [x] T003 Verify settings_controller.ex update_theme action works in lib/plausible_web/controllers/settings_controller.ex
- [x] T004 [P] Verify theme_script adds/removes dark class in lib/plausible_web/components/layout.ex
- [x] T005 [P] Verify ThemeContext observes DOM in assets/js/dashboard/theme-context.tsx
- [x] T006 Verify TailwindCSS dark mode classes exist in assets/css/app.css

---

## Phase 2: User Story 1 - Theme Selection (Priority: P1) - ALREADY IMPLEMENTED

**Goal**: Users can select their preferred theme (light, dark, or system)

**Independent Test**: Visit /settings/preferences, select a theme option, verify dashboard appearance changes

**Status**: ✅ Fully implemented

### Implementation (Already Complete)

- [ ] T010 [US1] User model has theme field - lib/plausible/auth/user.ex
- [ ] T011 [US1] Theme options defined - lib/plausible/themes.ex
- [ ] T012 [US1] Settings UI renders theme selector - lib/plausible_web/templates/settings/preferences.html.heex
- [ ] T013 [US1] Theme update controller handles POST - lib/plausible_web/controllers/settings_controller.ex

---

## Phase 3: User Story 2 - Persistent Preference (Priority: P1) - ALREADY IMPLEMENTED

**Goal**: Theme preference remembered across sessions

**Independent Test**: Select theme, logout, login, verify theme still applied

**Status**: ✅ Fully implemented

### Implementation (Already Complete)

- [ ] T020 [P] [US2] Theme persisted to PostgreSQL via User.theme field
- [ ] T021 [P] [US2] Theme retrieved on page load via assigns
- [ ] T022 [US2] Server-side script applies stored preference

---

## Phase 4: User Story 3 - Consistent Styling (Priority: P1) - ALREADY IMPLEMENTED

**Goal**: All dashboard components respect theme preference

**Independent Test**: View dashboard in dark mode, verify no light-mode elements

**Status**: ✅ Fully implemented

### Implementation (Already Complete)

- [ ] T030 [P] [US3] TailwindCSS dark mode configured in assets/css/app.css
- [ ] T031 [P] [US3] Theme-aware components use dark variants
- [ ] T032 [US3] Server-side script handles system preference detection

---

## Phase 5: User Story 4 - Real-time Theme Switching (Priority: P2) - ENHANCEMENT

**Goal**: Theme changes apply without page refresh

**Independent Test**: Change theme in settings, immediately see change

**Status**: ✅ IMPLEMENTED

### Enhancement Tasks

- [x] T040 [P] [US4] Add AJAX/form submission for theme change without page reload
- [x] T041 [US4] Update React state immediately after theme change
- [x] T042 [US4] Add optimistic UI update for theme selector

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that enhance the user experience

### Enhancement Opportunities

- [ ] T050 [P] Add header quick-toggle button for theme switching
- [x] T051 [P] Add smooth CSS transitions when switching themes
- [ ] T052 Add theme preview in settings dropdown
- [ ] T053 Verify system theme change listener works correctly
- [ ] T054 [P] Test theme works across all dashboard pages
- [ ] T055 Run manual acceptance test per spec.md scenarios

---

## Dependencies & Execution Order

### Phase Dependencies

- **Verification (Phase 1)**: Can start immediately - no dependencies
- **User Stories (Phase 2-4)**: Already implemented, verification only
- **Polish (Phase 6)**: Can proceed independently

### User Story Status

- **User Story 1 (P1)**: ✅ IMPLEMENTED
- **User Story 2 (P1)**: ✅ IMPLEMENTED
- **User Story 3 (P1)**: ✅ IMPLEMENTED
- **User Story 4 (P2)**: ✅ IMPLEMENTED (AJAX theme switching)

### Parallel Opportunities

- All Phase 1 verification tasks marked [P] can run in parallel
- Phase 6 enhancement tasks marked [P] can run in parallel

---

## Parallel Example: Verification

```bash
# Run all verification tasks in parallel:
Task: "Verify User.theme field in lib/plausible/auth/user.ex"
Task: "Verify Plausible.Themes.options() in lib/plausible/themes.ex"
Task: "Verify theme_script in lib/plausible_web/components/layout.ex"
Task: "Verify ThemeContext in assets/js/dashboard/theme-context.tsx"
```

---

## Implementation Strategy

### Current State: Feature Complete + Enhancements

The dark mode feature is fully implemented with the following enhancements:
1. **Real-time theme switching** - AJAX form submission applies theme immediately without page reload
2. **Smooth CSS transitions** - Added transition effects for smoother theme changes

### Optional Enhancements Remaining

- Add header quick-toggle button for theme switching
- Add theme preview in settings dropdown
- Test theme across all dashboard pages
- Run manual acceptance tests

---

## Notes

- Dark mode feature is already implemented - this tasks.md documents verification and enhancements
- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Core user stories (1-3) are fully functional
- User Story 4 (real-time switching) now implemented with AJAX
- Phase 6: Smooth transitions implemented
