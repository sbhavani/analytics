# Dark Mode Implementation Research

## Summary

**Decision**: Dark mode is already fully implemented in this codebase.

The implementation spans both backend (Elixir/Phoenix) and frontend (React/TypeScript) layers:
- Theme preference is stored in PostgreSQL on the User model
- Server-side script applies theme before page render
- React context observes DOM changes for client-side components
- TailwindCSS provides dark mode styling via `.dark` class

## Current Implementation

### Backend Components

| Component | File | Status |
|-----------|------|--------|
| User.theme field | `lib/plausible/auth/user.ex` | ✅ Implemented (`:system`, `:light`, `:dark`) |
| Theme options | `lib/plausible/themes.ex` | ✅ Implemented |
| Settings controller | `lib/plausible_web/controllers/settings_controller.ex` | ✅ Implemented |
| Server-side theme script | `lib/plausible_web/components/layout.ex` | ✅ Implemented |
| Settings UI | `lib/plausible_web/templates/settings/preferences.html.heex` | ✅ Implemented |

### Frontend Components

| Component | File | Status |
|-----------|------|--------|
| ThemeContext | `assets/js/dashboard/theme-context.tsx` | ✅ Implemented (light/dark only) |
| TailwindCSS dark mode | `assets/css/app.css` | ✅ Implemented |

## Key Technical Details

### Server-Side Theme Application
The theme script in `layout.ex` uses a blocking inline script that:
1. Reads user's theme preference from assigns
2. Checks system preference via `window.matchMedia('(prefers-color-scheme: dark)')`
3. Adds/removes `dark` class on `<html>` element
4. Listens for system theme changes in real-time

### React Theme Context
- Uses MutationObserver to watch for class changes on `<html>`
- Parses current UI mode from classList
- Provides `useTheme()` hook for components
- Only has two modes: `light` and `dark`

### Data Flow
```
User selects theme → POST to /settings/update-theme
    ↓
Controller updates User.theme in PostgreSQL
    ↓
Page reload with new assigns
    ↓
Server-side script reads preference and adds 'dark' class
    ↓
React context observes DOM change and updates components
```

## Identified Gaps

### Gap 1: No Header Quick-Toggle
Users must navigate to Settings > Preferences to change theme. Most modern apps have a quick-toggle in the header.

**Severity**: Low (works but not convenient)

### Gap 2: React Context Missing "System" Mode
The React ThemeContext only handles `light` and `dark`, not `system`. It relies on the HTML class being set correctly by the server-side script.

**Severity**: Low (works but inconsistent with backend model)

### Gap 3: Blocking Render Script
The theme script uses `blocking="rendering"` which delays page render until theme is applied.

**Severity**: Low (prevents flash of wrong theme but adds delay)

### Gap 4: No Auto-Submit on Theme Selection
User must click "Change theme" button after selecting from dropdown.

**Severity**: Low (minor UX improvement opportunity)

## Recommendations

### Priority Enhancements

1. **Add Header Quick-Toggle** (Medium Priority)
   - Add a theme toggle button to the navigation header
   - Quick access without navigating to settings

2. **Add Smooth Transitions** (Low Priority)
   - CSS transitions when switching themes
   - More polished user experience

### Documentation-Only Items (No Changes Needed)

- Theme field on User model: ✅ Complete
- Theme persistence: ✅ Complete
- Theme application: ✅ Complete
- Settings UI: ✅ Complete
- Dark mode styling: ✅ Complete

## Alternatives Considered

### Alternative 1: Client-Side Theme Switching
**Decision**: Rejected in favor of server-side approach

**Rationale**: Server-side script ensures theme is applied before React hydrates, preventing flash of wrong theme.

### Alternative 2: CSS Custom Properties
**Decision**: Not used - using TailwindCSS classes instead

**Rationale**: TailwindCSS already provides comprehensive dark mode support via the `.dark` class selector.

### Alternative 3: LocalStorage-Only Theme
**Decision**: Rejected in favor of database storage

**Rationale**: User preferences should persist across devices and sessions, requiring server-side storage.
