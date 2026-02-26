# Quickstart: Advanced Filter Builder

## Overview

The Advanced Filter Builder allows marketing analysts to create complex visitor segments by combining multiple filter conditions with AND/OR logic and nested groups.

## Quick Start

### 1. Create a Single Condition

1. Open the filter builder from the analytics dashboard
2. Select a dimension (e.g., Country)
3. Choose an operator (e.g., equals)
4. Enter a value (e.g., United States)
5. Click "Apply Filter"

### 2. Combine Conditions with AND/OR

1. Add your first condition
2. Click "Add Condition"
3. Select the connector type (AND or OR)
4. Configure the second condition
5. The filter combines both conditions

### 3. Create Nested Groups

1. Create multiple conditions
2. Select two or more conditions
3. Click "Group Selected"
4. Choose the group's logical operator (AND/OR)
5. The conditions are nested within a group

### 4. Save as Template

1. Configure your filter conditions
2. Click "Save Segment"
3. Enter a descriptive name
4. The segment is saved for future use

## Filter Dimensions

| Category | Dimensions |
|----------|------------|
| Location | country, region, city |
| Traffic | source, channel, referrer |
| Pages | page, entry_page, exit_page |
| Technology | browser, browser_version, os, os_version, screen |
| Campaigns | utm_medium, utm_source, utm_campaign, utm_term, utm_content |
| Goals | goal, props |
| Other | hostname |

## Operators by Dimension Type

### Text Dimensions (source, country, etc.)
- equals
- does not equal
- contains
- does not contain

### Numeric Dimensions (page_views, visit_duration)
- equals
- does not equal
- greater than
- less than
- between

### Boolean Dimensions
- has done
- has not done

## Example Use Cases

### Use Case 1: US Visitors on Blog

```
(Country = US) AND (Page contains /blog)
```

### Use Case 2: High-Value Customers

```
(Page views > 10) AND (Total revenue > $100)
```

### Use Case 3: Multi-Region Targeting

```
(Country = US OR Country = CA OR Country = UK) AND (Source = Google)
```

## Integration Points

- **Frontend**: `assets/js/dashboard/filtering/new-filter-builder/`
- **Backend API**: `POST /api/stats/:site_id/segments`
- **Persistence**: Segments table in PostgreSQL
- **Query Execution**: ClickHouse via existing query builder
