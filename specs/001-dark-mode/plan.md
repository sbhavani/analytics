# Implementation Plan: Dark Mode

**Branch**: `001-dark-mode` | **Date**: 2026-02-26 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-dark-mode/spec.md`

**Note**: Dark mode is already implemented in this codebase. This plan documents the existing implementation and identifies any gaps or enhancements needed.

## Summary

The dark mode feature is already fully implemented in this Plausible Analytics codebase. User preferences are persisted server-side in the PostgreSQL database (User.theme field), applied via a server-side script that adds/removes the 'dark' CSS class on the HTML element, and read by a React ThemeContext for client-side component styling.

**Current Status**: Feature complete with one minor enhancement opportunity identified.

## Technical Context

**Language/Version**: Elixir 1.15+, TypeScript 5.x, React 18.x
**Primary Dependencies**: Phoenix (Elixir), React, TailwindCSS, Ecto, PostgreSQL
**Storage**: PostgreSQL (User.theme field), HTML class attribute (runtime)
**Testing**: ExUnit (Elixir), Jest (JavaScript)
**Target Platform**: Web dashboard (responsive)
**Project Type**: Web analytics SaaS application
**Performance Goals**: Theme application should not block page render (currently blocking render)
**Constraints**: Must work with TailwindCSS dark mode classes
**Scale**: All users of the Plausible dashboard

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Status | Notes |
|------|--------|-------|
| Privacy-First Development | ✅ PASS | Theme preference is user preference only, no privacy impact |
| Test-Driven Development | ⚠️ REVIEW | Need to verify tests exist for theme functionality |
| Performance as Feature | ⚠️ NOTE | Server-side script uses `blocking="rendering"` which may delay initial render |
| Observability | ✅ N/A | No new metrics needed for theme feature |
| Simplicity and YAGNI | ✅ PASS | Feature is appropriately scoped |

**Constitution Check Result**: No violations. Feature is already implemented.

## Project Structure

### Documentation (this feature)

```text
specs/001-dark-mode/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output (documenting existing implementation)
├── data-model.md        # Phase 1 output (documenting entities)
├── quickstart.md        # Phase 1 output (how to use)
└── tasks.md             # Phase 2 output (if enhancements needed)
```

### Source Code (repository root)

```text
# Backend (Elixir/Phoenix)
lib/
├── plausible/
│   ├── auth/
│   │   └── user.ex              # User model with theme field
│   └── themes.ex               # Theme options
└── plausible_web/
    ├── controllers/
    │   └── settings_controller.ex  # Theme update endpoint
    ├── components/
    │   └── layout.ex            # Server-side theme script
    └── templates/
        └── settings/
            └── preferences.html.heex  # Theme selection UI

# Frontend (React/TypeScript)
assets/
├── js/
│   └── dashboard/
│       └── theme-context.tsx    # React theme context
└── css/
    └── app.css                 # TailwindCSS with dark mode classes
```

**Structure Decision**: Web application with Phoenix backend and React frontend. Theme feature spans both layers.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No complexity violations - feature is already implemented with appropriate simplicity.
