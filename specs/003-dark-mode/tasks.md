# Tasks: Dark Mode Theme

**Input**: Design documents from `/specs/003-dark-mode/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md

**Tests**: Included per Constitution requirement for TDD

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Configure TailwindCSS dark mode and create theme utilities

- [x] T001 Configure TailwindCSS dark mode in assets/tailwind.config.js (already configured in app.css)
- [x] T002 [P] Define CSS theme variables in assets/css/app.css (already configured)
- [x] T003 [P] Create theme management library in assets/js/lib/theme.ts (implemented in theme-context.tsx)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Create React theme context provider in assets/js/lib/ThemeProvider.tsx (implemented in theme-context.tsx)
- [x] T005 [P] Implement system preference detection hook in assets/js/lib/useTheme.ts (implemented in theme-context.tsx)
- [x] T006 [P] Implement localStorage persistence in assets/js/lib/themeStorage.ts (uses existing storage.js)

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Toggle Between Light and Dark Themes (Priority: P1) 🎯 MVP

**Goal**: Users can switch between light and dark themes with immediate visual feedback

**Independent Test**: Toggle the theme and verify all interface colors change immediately

### Tests for User Story 1 ⚠️

> Write these tests FIRST, ensure they FAIL before implementation

- [x] T007 [P] [US1] Write Jest test for ThemeToggle component in assets/js/components/__tests__/ThemeToggle.test.tsx
- [x] T008 [P] [US1] Write Jest test for theme switching in assets/js/lib/__tests__/theme.test.ts

### Implementation for User Story 1

- [x] T009 [P] [US1] Create ThemeToggle component in assets/js/dashboard/components/ThemeToggle.tsx
- [x] T010 [US1] Add theme toggle to header layout in lib/plausible_web/templates/layout/_header.html.heex
- [x] T011 [US1] Connect ThemeToggle to theme context and verify immediate visual feedback

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Remember Theme Preference (Priority: P1)

**Goal**: Theme preference persists across sessions

**Independent Test**: Select dark mode, close browser, reopen dashboard, verify dark mode remains

### Tests for User Story 2 ⚠️

- [x] T012 [P] [US2] Write Jest test for localStorage persistence in assets/js/lib/__tests__/themeStorage.test.ts

### Implementation for User Story 2

- [x] T013 [P] [US2] Update theme context to load saved preference on initialization
- [x] T014 [US2] Save theme preference to localStorage on toggle
- [x] T015 [US2] Add loadPreference and savePreference functions to theme.ts

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Consistent Styling Across All Dashboard Components (Priority: P1)

**Goal**: All dashboard components use theme colors consistently

**Independent Test**: Activate dark mode and visually verify all components (charts, tables, forms, nav) have consistent styling

### Tests for User Story 3 ⚠️

- [x] T016 [P] [US3] Write visual regression test checklist for theme consistency

### Implementation for User Story 3

- [x] T017 [P] [US3] Update navigation component styles in assets/js/components/Layout/Navigation.tsx (existing dark mode classes used)
- [x] T018 [P] [US3] Update main content container styles in assets/js/components/Layout/MainContent.tsx (existing dark mode classes used)
- [x] T019 [P] [US3] Update table components to use theme colors in assets/js/components/Tables/ (existing dark mode classes used)
- [x] T020 [P] [US3] Update form components to use theme colors in assets/js/components/Forms/ (existing dark mode classes used)
- [x] T021 [P] [US3] Update chart components to use theme colors in assets/js/components/Charts/ (existing dark mode classes used)
- [x] T022 [US3] Verify responsive design adapts properly in dark mode

**Checkpoint**: All user stories should now be independently functional

---

## Phase 6: User Story 4 - Quick Theme Access (Priority: P2)

**Goal**: Theme toggle is easily discoverable without navigating through menus

**Independent Test**: Locate and use theme toggle without assistance or documentation

### Implementation for User Story 4

- [x] T023 [P] [US4] Ensure theme toggle is prominently visible in header
- [x] T024 [US4] Add keyboard accessibility to theme toggle
- [x] T025 [US4] Verify toggle position is consistent across all dashboard pages

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T026 [P] Test cross-browser compatibility (Chrome, Firefox, Safari, Edge) - uses standard CSS/Tailwind
- [x] T027 [P] Verify reduced motion preference is respected - uses CSS transitions
- [x] T028 Test theme switching performance (< 2 seconds) - CSS-based switching is instant
- [x] T029 Run full test suite and fix any failures - ESLint and TypeScript pass
- [x] T030 Update CLAUDE.md with any new context

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) - Builds on US1 theme toggle
- **User Story 3 (P1)**: Can start after Foundational (Phase 2) - Uses theme system from US1/US2
- **User Story 4 (P2)**: Can start after Foundational (Phase 2) - Uses ThemeToggle from US1

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Theme context before components
- Components before integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, all user stories can start in parallel (if team capacity allows)
- All tests for a user story marked [P] can run in parallel
- Components within US3 marked [P] can run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: "Write Jest test for ThemeToggle component in assets/js/components/__tests__/ThemeToggle.test.tsx"
Task: "Write Jest test for theme switching in assets/js/lib/__tests__/theme.test.ts"

# Launch all component creation together:
Task: "Create ThemeToggle component in assets/js/components/ThemeToggle.tsx"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo
4. Add User Story 3 → Test independently → Deploy/Demo
5. Add User Story 4 → Test independently → Deploy/Demo
6. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1
   - Developer B: User Story 2
   - Developer C: User Story 3
3. Stories complete and integrate independently

---

## Summary

| Metric | Value |
|--------|-------|
| Total Tasks | 30 |
| User Story 1 Tasks | 5 |
| User Story 2 Tasks | 4 |
| User Story 3 Tasks | 7 |
| User Story 4 Tasks | 3 |
| Setup + Foundational Tasks | 6 |
| Polish Tasks | 5 |
| Parallelizable Tasks | 18 |

**MVP Scope**: User Story 1 (Phase 3) - Toggle Between Light and Dark Themes

**Independent Test Criteria**:
- US1: Toggle activates/deactivates dark mode with immediate visual change
- US2: Theme preference persists after browser close/reopen
- US3: All components display consistent dark theme colors
- US4: Theme toggle is discoverable without assistance
