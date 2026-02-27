# Research: Dark Mode Theme Switching

**Feature**: Dark Mode Theme Switching for Plausible Analytics Dashboard
**Date**: 2026-02-26

## Research Questions

### 1. How to implement theme persistence in React?

**Decision**: Use localStorage with React Context pattern

**Rationale**:
- localStorage is already available in modern browsers
- React Context provides clean state management without external libraries
- Matches the project's simplicity principle (no Redux needed for single value)

**Implementation**:
```typescript
// Store: localStorage key = 'theme_preference'
// Values: 'light' | 'dark' | 'system'
// On read: Check localStorage; if 'system', query prefers-color-scheme
// On write: Save to localStorage, update document classList
```

### 2. How to detect OS theme preference?

**Decision**: Use `window.matchMedia('(prefers-color-scheme: dark)')`

**Rationale**:
- Native browser API, no dependencies
- Supported in all modern browsers
- Can listen for changes (e.g., user changes OS theme while using app)

**Implementation**:
```typescript
const getSystemTheme = () =>
  window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
```

### 3. How does existing TailwindCSS dark mode work?

**Finding**: The project already has dark mode configured!

From `assets/css/app.css` line 120:
```css
@custom-variant dark (&:where(.dark, .dark *));
```

This means:
- Dark mode uses `.dark` class on HTML element
- All `dark:` Tailwind modifiers are already active
- Some components already have dark mode styles

**Action needed**: Apply `.dark` class to `<html>` element based on user preference

### 4. How to handle Chart.js charts in dark mode?

**Finding**: Chart.js uses inline colors, not CSS

**Decision**: Need to update chart colors when theme changes

**Implementation**:
- Listen for theme changes
- Update Chart.js default colors
- Or use chart.js plugin for dark mode (chartjs-plugin-darkmode)

### 5. What about Flatpickr date picker?

**Finding**: There is a separate dark theme CSS file: `flatpickr-colors.css`

**Action needed**: Ensure this file applies when dark mode is active, or toggle a class on flatpickr container

## Best Practices Applied

1. **FOUC Prevention**: Apply theme class in `<head>` or before React hydrates to prevent flash
2. **Accessibility**: Theme toggle must be keyboard accessible and have aria-label
3. **Reduced Motion**: Respect `prefers-reduced-motion` for theme transition
4. **No Layout Shift**: Theme change should not cause content reflow

## Alternatives Considered

| Approach | Rejected Because |
|----------|-----------------|
| CSS-only media queries | Cannot persist user preference |
| Server-side storage | Adds unnecessary backend complexity |
| Redux for state | Overkill - single value, no global state needed |
| Third-party library (react-dark-mode) | Adds dependency; simple enough to implement directly |

## Conclusion

The feature can be implemented with minimal code:
1. ThemeContext provider (state + localStorage)
2. useTheme hook
3. ThemeToggle component
4. Apply `.dark` class to HTML element
5. Test chart color updates work

No external dependencies needed beyond existing stack.
