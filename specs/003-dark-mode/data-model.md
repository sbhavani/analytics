# Data Model: Dark Mode Theme

**Phase**: 1 - Design
**Feature**: Dark Mode Theme
**Date**: 2026-02-26

## Entities

### User Preference (Theme Mode)

Represents a user's theme selection.

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| user_id | UUID (optional) | User identifier for authenticated users | Null for anonymous |
| theme | String | Theme mode: "light" or "dark" | Must be "light" or "dark" |
| source | String | How preference was set: "manual", "system" | Must be valid source |
| updated_at | Timestamp | Last modification time | Auto-generated |

**Storage Locations**:
- Anonymous users: localStorage key `plausible_theme`
- Authenticated users: Database table `user_preferences`

---

### Theme Configuration

CSS variable definitions for each theme.

| Variable | Light Value | Dark Value | Usage |
|----------|-------------|------------|-------|
| --bg-primary | #ffffff | #1a1a2e | Main background |
| --bg-secondary | #f8f9fa | #16213e | Secondary background |
| --text-primary | #1a1a2e | #e8e8e8 | Main text |
| --text-secondary | #6c757d | #a0a0a0 | Secondary text |
| --border-color | #dee2e6 | #2d3a4f | Borders |
| --accent-color | #6366f1 | #818cf8 | Interactive elements |
| --hover-color | #f1f5f9 | #1e293b | Hover states |

---

## State Transitions

### Theme State Machine

```
┌──────────┐   toggle   ┌──────────┐
│   LIGHT  │ ─────────> │   DARK   │
└──────────┘            └──────────┘
     ^                       |
     |         toggle         |
     └────────────────────────┘
```

**States**: LIGHT, DARK
**Transition**: Toggle switches between states
**Initial State**: Determined by system preference or stored preference

---

## Persistence Strategy

### Anonymous Users
```javascript
// localStorage
localStorage.getItem('plausible_theme') // Returns: "light" | "dark" | null
localStorage.setItem('plausible_theme', 'dark')
```

### Authenticated Users
- Table: `user_preferences`
- Column: `theme` (varchar)
- Synced on login via API call
- Updates stored in real-time on toggle

---

## No External Contracts

This is a frontend-only feature with no external API contracts.
- No new backend endpoints required
- No database migrations required (unless storing for authenticated users)
- No third-party integrations
