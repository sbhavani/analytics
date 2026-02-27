# Data Model: Dark Mode

## Entities

### User

| Field | Type | Values | Description |
|-------|------|--------|-------------|
| theme | Ecto.Enum | `:system`, `:light`, `:dark` | User's theme preference |

**Validation**: Must be one of the defined enum values.

**Default**: `nil` (falls back to "system" behavior)

### Relationships

```
User (1) ──► Theme (embedded)
```

The theme is a single field on the User entity, not a separate table.

## State Transitions

The theme field has no complex state transitions - it's a simple enum value:

```
nil (default) → :system
nil (default) → :light
nil (default) → :dark

:system → :light
:system → :dark

:light → :system
:light → :dark

:dark → :system
:dark → :light
```

## Runtime State

### HTML Element State

| State | Class on `<html>` | Description |
|-------|-------------------|-------------|
| Light | No `dark` class | Light theme active |
| Dark | `dark` class present | Dark theme active |

### React Context State

| State | UIMode enum | Description |
|-------|-------------|-------------|
| Light | `UIMode.light` | Light theme active |
| Dark | `UIMode.dark` | Dark theme active |

Note: React context does not have a "system" mode - it observes the actual computed state from the HTML class.
