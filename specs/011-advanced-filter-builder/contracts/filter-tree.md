# Filter Tree Data Structure

## Overview

This document defines the data structure for the visual filter builder component. This is the internal contract between React components.

## Filter Tree Schema

```typescript
interface FilterTree {
  version: 1; // Schema version for future compatibility
  root: FilterGroupNode;
}

interface FilterGroupNode {
  id: string;           // Unique ID for this node
  type: "group";
  operator: "and" | "or";
  children: FilterNode[];
}

interface FilterConditionNode {
  id: string;           // Unique ID for this node
  type: "condition";
  attribute: string;    // e.g., "visit:country", "event:page"
  operator: FilterOperator;
  value: string;
  negated: boolean;     // If true, applies NOT to this condition
}

type FilterNode = FilterGroupNode | FilterConditionNode;
```

## Filter Operators

| Operator | Value Type | Description | Example |
|----------|------------|-------------|---------|
| is | string | Exact match | visit:country = "US" |
| is_not | string | Not equal | visit:device ≠ "Mobile" |
| contains | string | Substring | event:page contains "/blog" |
| contains_not | string | No substring | event:page does not contain "/admin" |
| matches | string | Regex | referrer matches "^https://google" |
| matches_not | string | No regex | - |
| matches_wildcard | string | Glob pattern | event:name matches_wildcard "purchase*" |
| matches_wildcard_not | string | No glob | - |
| has_done | none | Goal completed | goal has_done "Sign up" |
| has_not_done | none | Goal not completed | - |

## UI State Structure

```typescript
interface FilterBuilderState {
  tree: FilterTree;
  isDirty: boolean;        // Has unsaved changes
  lastSaved: Date | null;  // Last save timestamp
  previewStatus: "idle" | "loading" | "success" | "error";
  validationErrors: ValidationError[];
}

interface ValidationError {
  nodeId: string;
  field: "attribute" | "operator" | "value";
  message: string;
}
```

## Example: Simple AND Filter

Input: Country = US AND Device = Mobile

```json
{
  "version": 1,
  "root": {
    "id": "root-1",
    "type": "group",
    "operator": "and",
    "children": [
      {
        "id": "cond-1",
        "type": "condition",
        "attribute": "visit:country",
        "operator": "is",
        "value": "US",
        "negated": false
      },
      {
        "id": "cond-2",
        "type": "condition",
        "attribute": "visit:device",
        "operator": "is",
        "value": "Mobile",
        "negated": false
      }
    ]
  }
}
```

## Example: Nested OR/AND Filter

Input: (Country = US AND Page Views > 5) OR (Country = UK)

```json
{
  "version": 1,
  "root": {
    "id": "root-1",
    "type": "group",
    "operator": "or",
    "children": [
      {
        "id": "group-1",
        "type": "group",
        "operator": "and",
        "children": [
          {
            "id": "cond-1",
            "type": "condition",
            "attribute": "visit:country",
            "operator": "is",
            "value": "US",
            "negated": false
          },
          {
            "id": "cond-2",
            "type": "condition",
            "attribute": "event:pageviews",
            "operator": "gt",
            "value": "5",
            "negated": false
          }
        ]
      },
      {
        "id": "cond-3",
        "type": "condition",
        "attribute": "visit:country",
        "operator": "is",
        "value": "UK",
        "negated": false
      }
    ]
  }
}
```

## Component Props

### FilterBuilder Component

```typescript
interface FilterBuilderProps {
  siteId: string;
  initialTree?: FilterTree;
  savedSegments?: SavedSegment[];
  onSave: (name: string, tree: FilterTree) => Promise<void>;
  onPreview: (tree: FilterTree) => Promise<PreviewResult>;
  onCancel?: () => void;
}
```

### ConditionEditor Component

```typescript
interface ConditionEditorProps {
  condition: FilterConditionNode;
  availableAttributes: FilterAttribute[];
  onChange: (updated: FilterConditionNode) => void;
  onRemove: () => void;
  suggestions?: (attr: string, query: string) => Promise<string[]>;
}
```

### GroupEditor Component

```typescript
interface GroupEditorProps {
  group: FilterGroupNode;
  onChange: (updated: FilterGroupNode) => void;
  onAddCondition: () => void;
  onAddGroup: () => void;
  canAddGroup: boolean;  // false if at max nesting depth
  maxConditions: number;
}
```
