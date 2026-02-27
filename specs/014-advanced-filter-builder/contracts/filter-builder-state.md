# Contract: Filter Builder State Serialization

## Overview

This document defines the contract for serializing and deserializing the filter builder state for storage and URL sharing.

## JSON Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "FilterBuilderState",
  "type": "object",
  "required": ["filters"],
  "properties": {
    "filters": {
      "type": "array",
      "description": "Array of filter conditions in nested group format",
      "items": {
        "$ref": "#/definitions/FilterNode"
      },
      "minItems": 1
    },
    "labels": {
      "type": "object",
      "description": "Human-readable labels for filter conditions",
      "additionalProperties": {
        "type": "string"
      }
    }
  },
  "definitions": {
    "FilterNode": {
      "oneOf": [
        { "$ref": "#/definitions/FilterCondition" },
        { "$ref": "#/definitions/FilterGroup" }
      ]
    },
    "FilterCondition": {
      "type": "array",
      "minItems": 3,
      "maxItems": 4,
      "items": [
        { "type": "string", "enum": ["is", "is_not", "contains", "matches", "matches_wildcard", "has_done", "has_not_done"] },
        { "type": "string", "pattern": "^(event|visit|segment):" },
        { "type": "array", "items": { "type": ["string", "number"] }, "minItems": 1 }
      ],
      "additionalItems": {
        "type": "object",
        "properties": {
          "case_sensitive": { "type": "boolean" }
        }
      }
    },
    "FilterGroup": {
      "type": "array",
      "minItems": 2,
      "items": [
        { "type": "string", "enum": ["and", "or"] },
        { "type": "array", "items": { "$ref": "#/definitions/FilterNode" } }
      ]
    }
  }
}
```

## Examples

### Simple Filter (Single Condition)
```json
{
  "filters": [
    ["is", "visit:country", ["US"]]
  ]
}
```

### AND Logic
```json
{
  "filters": [
    ["and", [
      ["is", "visit:country", ["US"]],
      ["is", "visit:device", ["Mobile"]]
    ]]
  ]
}
```

### OR Logic
```json
{
  "filters": [
    ["or", [
      ["is", "visit:country", ["US"]],
      ["is", "visit:country", ["GB"]]
    ]]
  ]
}
```

### Nested Groups
```json
{
  "filters": [
    ["or", [
      ["and", [
        ["is", "visit:country", ["US"]],
        ["is", "visit:device", ["Mobile"]]
      ]],
      ["is", "visit:country", ["GB"]]
    ]]
  ],
  "labels": {
    "0": "US Mobile",
    "1": "UK Visitors"
  }
}
```

## Validation

- Maximum nesting depth: 3 levels
- Maximum total conditions: 20
- Valid operators depend on dimension type
- Values must match expected format for dimension

## Error Responses

| Error Code | Message | Cause |
|------------|---------|-------|
| invalid_filters | "Invalid filter syntax" | Malformed filter array |
| invalid_dimension | "Unknown dimension: {dimension}" | Invalid filter dimension |
| invalid_operator | "Operator {operator} not valid for {dimension}" | Operator/dimension mismatch |
| max_depth_exceeded | "Maximum nesting depth exceeded" | More than 3 levels |
| max_conditions_exceeded | "Maximum {n} conditions allowed" | More than 20 conditions |
