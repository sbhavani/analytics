# Implementation Plan: Dark Mode Theme

**Branch**: `003-dark-mode` | **Date**: 2026-02-26 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

**Primary Requirement**: Implement dark mode theme switching that persists user preference and applies consistent styling across the dashboard.

**Technical Approach**:
- Use CSS variables + TailwindCSS dark mode for instant theme switching
- Detect system preference via `prefers-color-scheme` media query
- Store preference in localStorage (anonymous) or database (authenticated users)
- Add theme toggle component to header/navigation

**Scope**: Frontend-only feature. No backend changes required unless storing preferences for authenticated users.

## Technical Context

**Language/Version**: TypeScript (React frontend), Elixir/Phoenix (backend)
**Primary Dependencies**: React, TailwindCSS, CSS Variables for theming
**Storage**: localStorage (browser) for user preference, user account database for authenticated users
**Testing**: Jest (JavaScript), ExUnit (Elixir backend)
**Target Platform**: Web browser (responsive - desktop and mobile)
**Project Type**: Web application (frontend feature)
**Performance Goals**: Theme toggle completes in under 2 seconds
**Constraints**: All UI components must use theme variables consistently
**Scale/Scope**: Dashboard UI across all pages

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Privacy-First Development (Principle I)
- **Status**: PASS
- **Analysis**: Dark mode is a purely UI feature. Theme preference is stored locally or in user account. No personal data collection or tracking involved.

### Test-Driven Development (Principle II) - NON-NEGOTIABLE
- **Status**: PASS
- **Analysis**: Tests required for theme toggle component, preference persistence, and consistent styling. Jest tests for frontend behavior.
- **Action**: Tests must be written before implementation.

### Performance as a Feature (Principle III)
- **Status**: PASS
- **Analysis**: CSS variables enable instant theme switching. Target is under 2 seconds per SC-001. No performance concerns.

### Observability and Debuggability (Principle IV)
- **Status**: PASS
- **Analysis**: Theme toggle events can be logged for debugging. Simple feature with clear user feedback.

### Simplicity and YAGNI (Principle V)
- **Status**: PASS
- **Analysis**: CSS variables with TailwindCSS dark mode is the simplest implementation. No unnecessary complexity.

## Project Structure

### Documentation (this feature)

```text
specs/003-dark-mode/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (if needed - not applicable for UI feature)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

Based on Plausible Analytics project structure:

```text
lib/plausible_web/
├── components/
│   └── layouts/         # Main layout components (header, footer)
├── controllers/         # Phoenix controllers
└── views/                # Phoenix views and templates

assets/
├── css/
│   └── app.css          # Main CSS with Tailwind imports
├── js/
│   ├── components/      # React components
│   └── lib/            # Utilities (theme management)
└── tailwind.config.js   # Tailwind configuration

priv/
└── repo/               # Database migrations (if user preference stored in DB)
```

**Structure Decision**: This is a frontend-only feature using React + TailwindCSS.
- Theme toggle component: `assets/js/components/ThemeToggle.tsx`
- Theme management: `assets/js/lib/theme.ts`
- CSS variables: Added to `assets/css/app.css`
- Backend storage (if needed for logged-in users): User preferences table

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
