# Data Model: Dark Mode Theme Switching

**Feature**: Dark Mode Theme Switching
**Date**: 2026-02-26

## Entities

### ThemePreference

Represents the user's selected theme mode.

| Field | Type | Values | Default | Description |
|-------|------|--------|---------|-------------|
| `preference` | string | `'light'`, `'dark'`, `'system'` | `'system'` | User's theme selection |
| `resolvedTheme` | string | `'light'`, `'dark'` | (computed) | Actual theme after resolving system preference |

**Storage**: localStorage
**Key**: `theme_preference`

**State Transitions**:
```
[Initial Load]
  ├─ localStorage has value → use stored preference
  └─ localStorage empty → use 'system'

[System Preference]
  └─ preference === 'system' → use OS prefers-color-scheme

[User Changes Theme]
  └─ preference ∈ {light, dark} → save to localStorage, apply immediately
```

### ThemeContext

React Context providing theme state to components.

| Property | Type | Description |
|----------|------|-------------|
| `theme` | `'light'` \| `'dark'` | Current resolved theme |
| `preference` | `'light'` \| `'dark'` \| `'system'` | User's stored preference |
| `setPreference` | `(pref: ThemePreference) => void` | Update stored preference |
| `toggleTheme` | `() => void` | Toggle between light and dark |

## Validation Rules

1. **Preference Value**: Must be one of: `'light'`, `'dark'`, `'system'`
2. **localStorage Availability**: Must handle gracefully if localStorage unavailable
3. **OS Media Query**: Must handle if `prefers-color-scheme` not supported

## Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      User Visits                            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              Check localStorage 'theme_preference'          │
└─────────────────────────────────────────────────────────────┘
          │                                       │
          ▼                                       ▼
    [Has Value]                              [No Value]
          │                                       │
          ▼                                       ▼
┌─────────────────────┐                ┌─────────────────────┐
│ Use stored value    │                │ Detect OS preference│
│                    │                │ (prefers-color-scheme)
└─────────────────────┘                └─────────────────────┘
          │                                       │
          ▼                                       ▼
┌─────────────────────────────────────────────────────────────┐
│                  Resolve Theme                              │
│  - If 'system', query OS                                    │
│  - If 'light' or 'dark', use directly                       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│         Apply '.dark' class to <html> element               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│         TailwindCSS dark: variants activate                 │
└─────────────────────────────────────────────────────────────┘
```

## Integration Points

| Component | Integration | Notes |
|-----------|-------------|-------|
| `ThemeProvider` | Wraps app root | Initializes theme on mount |
| `ThemeToggle` | Uses ThemeContext | UI for changing preference |
| Chart.js charts | Listen to theme changes | Update chart colors |
| Flatpickr | CSS class toggle | Apply dark theme CSS |
| Phoenix Layouts | May need initial script | Prevent FOUC |

## Edge Cases

1. **localStorage blocked**: Fall back to 'system' preference
2. **No OS preference support**: Default to 'light'
3. **Multiple tabs open**: Use `storage` event listener to sync
4. **SSR (if applicable)**: Apply theme class before hydration
