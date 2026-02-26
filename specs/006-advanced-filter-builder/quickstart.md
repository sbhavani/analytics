# Quickstart: Advanced Filter Builder

## Overview

The Advanced Filter Builder enables marketing analysts to create custom visitor segments using AND/OR logic and nested condition groups.

## Prerequisites

- Plausible Analytics instance running
- User account with analyst or admin role
- Access to visitor data

## Getting Started

### 1. Access the Filter Builder

Navigate to the Segments section in your dashboard:
```
/sites/:site_id/segments
```

### 2. Create Your First Segment

1. Click "New Segment" button
2. Click "Add Condition" to add your first filter
3. Select a field (e.g., "Country")
4. Select an operator (e.g., "equals")
5. Enter a value (e.g., "US")
6. Click "Preview" to see matching visitors

### 3. Add Multiple Conditions

1. Click "Add Condition" again
2. Configure the second condition
3. The conditions are automatically combined with AND
4. Click the AND toggle to switch to OR logic

### 4. Create Nested Groups

1. Add at least 2 conditions
2. Select multiple conditions by checking them
3. Click "Group Selected"
4. Choose AND or OR for the group
5. The group can be further nested (up to 3 levels)

### 5. Save Your Segment

1. Configure your filter conditions
2. Click "Save Segment"
3. Enter a descriptive name
4. Click "Save" to persist the segment

### 6. Manage Saved Segments

- **Load**: Select a segment from the list to load its configuration
- **Edit**: Modify conditions and save again
- **Delete**: Remove unwanted segments

## Common Use Cases

### High-Value US Customers
```
Country = "US" AND Pages Visited > 5 AND Total Spent > 100
```

### Recent Purchasers or Cart Abandoners
```
(Purchase Date > 30 days ago) OR
(Cart Items > 0 AND No Purchase in 7 days)
```

### Mobile Visitors from Social
```
Device Type = "Mobile" AND Referrer Source contains "social"
```

## Troubleshooting

### Preview Times Out
- Reduce the number of conditions
- Use more specific filter values
- Wait for data to be indexed

### Segment Returns No Visitors
- Check that filter values match your data
- Verify date ranges if using time-based fields
- Ensure conditions are not contradictory

### Cannot Save Segment
- Segment must have at least one condition
- Name must be unique within your site
- Check you have permission to save

## Validation Test Scenarios

### Test 1: Create Simple AND Segment
1. Navigate to /sites/:site_id/segments
2. Click "New Segment"
3. Click "Add Condition"
4. Set: Country = "United States"
5. Click "Add Condition" again
6. Set: Pages Visited > 5
7. Click "Preview Segment"
8. **Expected**: Visitor count displayed within 5 seconds
9. Click "Save Segment"
10. Enter name: "High Value US Users"
11. Click "Save"
12. **Expected**: Segment appears in list

### Test 2: Create OR Segment
1. Create new segment
2. Add condition: Country = "United States"
3. Add condition: Country = "United Kingdom"
4. Click AND toggle to switch to OR
5. **Expected**: Connector shows "OR" between conditions
6. Click "Preview"
7. **Expected**: Visitors from either US OR UK

### Test 3: Nested Groups
1. Create new segment
2. Add 2 conditions
3. Click "Add Group"
4. **Expected**: Nested group appears with indent
5. Add conditions to nested group
6. Toggle nested group operator
7. Click "Preview"
8. **Expected**: Complex logic evaluated correctly

### Test 4: Segment Management
1. Click on existing segment
2. **Expected**: Filter configuration loads
3. Modify conditions
4. Click "Save"
5. **Expected**: Segment updated
6. Click "Delete" on another segment
7. Confirm deletion
8. **Expected**: Segment removed from list

### Test 5: Accessibility
1. Navigate using Tab key through all controls
2. **Expected**: All interactive elements are focusable
3. Use screen reader
4. **Expected**: All elements have proper ARIA labels
5. Use keyboard only (no mouse)
6. **Expected**: Can complete all operations
