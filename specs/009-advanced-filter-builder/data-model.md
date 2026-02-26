# Data Model: Advanced Filter Builder

**Feature**: Advanced Filter Builder for visitor segments
**Date**: 2026-02-26

## Overview

The Advanced Filter Builder extends the existing Segment functionality with AND/OR logic and nested filter groups.

## Existing Schema

### Segment (lib/plausible/segments/segment.ex)

The existing Segment schema is already defined:

```elixir
schema "segments" do
  field :name, :string
  field :type, Ecto.Enum, values: [:personal, :site]
  field :segment_data, :map  # JSON - contains "filters" and "labels"

  belongs_to :owner, Plausible.Auth.User
  belongs_to :site, Plausible.Site

  timestamps()
end
```

The `segment_data` field contains:
- `filters`: Array of filter objects
- `labels`: Optional display labels for filters

## New Filter Data Structure

### Filter Condition

```typescript
interface FilterCondition {
  id: string;                    // Unique identifier for UI tracking
  attribute: string;              // e.g., "visit:country", "visit:device"
  operator: string;               // e.g., "equals", "contains", "matches_regexp"
  value: string | string[];      // Single value or array for "member" operator
}
```

### Filter Group

```typescript
interface FilterGroup {
  id: string;                     // Unique identifier for UI tracking
  logic: "AND" | "OR";            // How conditions within this group are combined
  conditions: (FilterCondition | FilterGroup)[];  // Can contain nested groups
}
```

### Example Structure

```json
{
  "filters": [
    {
      "id": "group-1",
      "logic": "AND",
      "conditions": [
        {
          "id": "cond-1",
          "attribute": "visit:country",
          "operator": "equals",
          "value": "US"
        },
        {
          "id": "cond-2",
          "attribute": "visit:device",
          "operator": "equals",
          "value": "Mobile"
        }
      ]
    },
    {
      "id": "group-2",
      "logic": "OR",
      "conditions": [
        {
          "id": "cond-3",
          "attribute": "visit:source",
          "operator": "equals",
          "value": "google"
        },
        {
          "id": "cond-4",
          "attribute": "visit:utm_campaign",
          "operator": "contains",
          "value": "summer"
        }
      ]
    }
  ]
}
```

## Visitor Attributes (Filter Dimensions)

### Predefined Attributes

| Attribute | Display Name | Type | Operators |
|-----------|--------------|------|-----------|
| visit:country | Country | country code | equals, member |
| visit:country_name | Country | country name | equals, member |
| visit:region | Region | region code | equals, member |
| visit:region_name | Region | region name | equals, member |
| visit:city | City | city code | equals, member |
| visit:city_name | City | city name | equals, member |
| visit:device | Device | device type | equals, member |
| visit:browser | Browser | browser name | equals, member, contains |
| visit:browser_version | Browser Version | version string | equals, member, contains |
| visit:os | Operating System | OS name | equals, member, contains |
| visit:os_version | OS Version | version string | equals, member, contains |
| visit:source | Traffic Source | source name | equals, member, contains |
| visit:channel | Channel | channel type | equals, member |
| visit:referrer | Referrer | referrer URL | equals, contains, matches_regexp |
| visit:utm_medium | UTM Medium | medium name | equals, member, contains |
| visit:utm_source | UTM Source | source name | equals, member, contains |
| visit:utm_campaign | UTM Campaign | campaign name | equals, member, contains |
| visit:utm_content | UTM Content | content name | equals, member, contains |
| visit:utm_term | UTM Term | term name | equals, member, contains |
| visit:screen | Screen Size | screen size | equals, member |
| visit:entry_page | Entry Page | page path | equals, contains, matches_regexp |
| visit:exit_page | Exit Page | page path | equals, contains, matches_regexp |
| visit:entry_page_hostname | Entry Hostname | hostname | equals, contains |
| visit:exit_page_hostname | Exit Hostname | hostname | equals, contains |

### Custom Properties

Sites can define custom properties that appear as additional filterable attributes (e.g., `property:custom_property_name`).

## State Transitions

### Filter Builder States

```
[Empty] --add condition--> [Single Condition]
[Single Condition] --add condition--> [Multiple Conditions (AND/OR)]
[Multiple Conditions] --add nested group--> [Nested Groups]
[Multiple Conditions] --remove all--> [Empty]
[With Conditions] --save--> [Saved Segment]
[Saved Segment] --load--> [With Conditions]
[Saved Segment] --delete--> [Empty]
```

## Validation Rules

1. **Minimum Conditions**: At least one filter condition required to save
2. **Attribute Required**: Each condition must have a valid attribute
3. **Value Required**: Each condition must have a non-empty value (except "is_not" and "not_member" operators)
4. **Operator Valid**: Operator must be valid for the attribute type
5. **Max Nesting Depth**: Maximum 3 levels of nested groups (per SC-004)
6. **Max Conditions**: Maximum 20 conditions per filter (per SC-005)
7. **Max Segment Data Size**: 5KB (existing constraint)

## API Integration

The filter structure maps to the existing query API:

- `FilterCondition` → Maps to existing filter format: `[operator, dimension, clauses]`
- `FilterGroup` → Maps to array of filters combined with the specified logic
- The existing `ApiQueryParser.parse_filters/1` validates the generated filter structure
