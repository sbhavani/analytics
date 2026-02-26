# Quickstart: Dark Mode Theme Implementation

**Phase**: 1 - Design
**Feature**: Dark Mode Theme
**Date**: 2026-02-26

## Development Setup

### Prerequisites
- Node.js 18+
- Elixir 1.14+
- Phoenix project running locally

### Frontend Development
```bash
# Install dependencies
cd assets
npm install

# Start development server
npm run dev

# Run JavaScript tests
npm test
```

### Backend Development (if storing preferences for authenticated users)
```bash
# Install Elixir dependencies
mix deps.get

# Run Phoenix server
mix phx.server

# Run tests
mix test
```

---

## Implementation Checklist

### Phase 1: Theme System Setup
- [ ] Configure TailwindCSS dark mode in `tailwind.config.js`
- [ ] Define CSS variables for theme colors in `app.css`
- [ ] Create theme context/hook in React

### Phase 2: Theme Toggle Component
- [ ] Create ThemeToggle component
- [ ] Add toggle to header/navigation
- [ ] Implement immediate visual feedback

### Phase 3: Preference Persistence
- [ ] Implement localStorage storage for anonymous users
- [ ] Add system preference detection (prefers-color-scheme)
- [ ] Add database storage for authenticated users (if needed)

### Phase 4: Consistent Styling
- [ ] Update all dashboard components to use theme CSS variables
- [ ] Test charts, tables, forms, navigation styling
- [ ] Verify responsive design in dark mode

### Phase 5: Testing
- [ ] Write Jest tests for ThemeToggle component
- [ ] Test localStorage persistence
- [ ] Test cross-browser compatibility
- [ ] Test accessibility (contrast, reduced motion)

---

## Key Files to Modify

| File | Purpose |
|------|---------|
| `assets/tailwind.config.js` | Add dark mode configuration |
| `assets/css/app.css` | Add theme CSS variables |
| `assets/js/lib/theme.ts` | Theme management utilities |
| `assets/js/components/ThemeToggle.tsx` | Toggle component |
| `lib/plausible_web/components/layouts/` | Add toggle to header |

---

## Testing Commands

```bash
# Run JavaScript tests
npm test

# Run JavaScript tests with coverage
npm test -- --coverage

# Lint JavaScript
npm run lint
```
