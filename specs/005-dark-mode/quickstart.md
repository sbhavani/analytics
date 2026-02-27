# Quickstart: Dark Mode Theme Switching

**Feature**: Dark Mode Theme Switching
**Date**: 2026-02-26

## Implementation Overview

This guide helps developers implement dark mode theme switching in the Plausible Analytics dashboard.

## Prerequisites

- Node.js 18+
- npm or yarn
- Access to `assets/js` directory

## Quick Start

### Step 1: Add ThemeProvider to App Root

Wrap your application with the ThemeProvider in the main entry point.

```tsx
// assets/js/app.tsx
import { ThemeProvider } from './contexts/ThemeContext'

function App() {
  return (
    <ThemeProvider>
      <Dashboard />
    </ThemeProvider>
  )
}
```

### Step 2: Add ThemeToggle to Header

Place the theme toggle component in the dashboard header or navigation.

```tsx
// In your header component
import { ThemeToggle } from './components/ThemeToggle'

function Header() {
  return (
    <nav>
      <Logo />
      <ThemeToggle />
      {/* other nav items */}
    </nav>
  )
}
```

### Step 3: Verify Dark Mode Works

The TailwindCSS dark mode is already configured. Components using `dark:` modifiers will automatically respond to the `.dark` class on the `<html>` element.

```tsx
// Example component with dark mode
function Card({ children }) {
  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg shadow">
      {children}
    </div>
  )
}
```

## Files to Create

| File | Purpose |
|------|---------|
| `assets/js/contexts/ThemeContext.tsx` | React context for theme state |
| `assets/js/hooks/useTheme.ts` | Hook for accessing theme |
| `assets/js/components/ThemeToggle.tsx` | Toggle button component |
| `assets/js/lib/theme.ts` | Theme utility functions |

## Testing

Run Jest tests:

```bash
cd assets
npm test
```

## Common Issues

### Flash of Wrong Theme (FOUC)

If theme flashes on page load, add this script to the HTML `<head>`:

```html
<script>
  (function() {
    const theme = localStorage.getItem('theme_preference');
    const systemDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    if (theme === 'dark' || (!theme && systemDark)) {
      document.documentElement.classList.add('dark');
    }
  })();
</script>
```

### Charts Not Updating

Chart.js uses inline colors. Update chart options when theme changes:

```tsx
useEffect(() => {
  Chart.defaults.color = theme === 'dark' ? '#9ca3af' : '#374151'
  // Update existing charts
}, [theme])
```

## Next Steps

1. Run existing tests to ensure no regressions
2. Add theme toggle to all dashboard pages
3. Test on multiple browsers
4. Verify accessibility (keyboard navigation, screen readers)
