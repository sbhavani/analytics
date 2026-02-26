# Quickstart: Time Period Comparison

## Overview

The time period comparison feature allows you to compare analytics metrics between two different date ranges. This is useful for understanding how your site's performance has changed over time.

## Using Period Comparison

### From the Dashboard

1. Open your site's analytics dashboard
2. Look for the comparison period selector (typically next to the date range selector)
3. Choose a comparison mode:
   - **Previous Period** - compares with the equivalent period immediately before
   - **Year over Year** - compares with the same period in the previous year
   - **Custom** - select specific dates to compare

### Using URL Parameters

You can also navigate directly to comparisons using URL parameters:

```
/<site-domain>?period=month&comparison=previous_period
```

With custom dates:
```
/<site-domain>?period=custom&date=2024-01-01,2024-01-31&comparison=custom&compare_from=2023-01-01&compare_to=2023-01-31
```

### Match Day of Week

For more accurate comparisons, enable "Match day of week" to compare the same days of the week:
- Example: If your current period starts on Monday, the comparison will also start on Monday

## Interpreting Results

- **Green arrow up** - Metric increased compared to the comparison period
- **Red arrow down** - Metric decreased compared to the comparison period
- **No icon (0%)** - No change between periods

## Example Scenarios

### Weekly Comparison
- Current: This week (Mon-Sun)
- Comparison: Last week (Mon-Sun)
- Shows: Percentage change from last week to this week

### Month over Month
- Current: January 2024
- Comparison: December 2023
- Shows: How January compares to December

### Year over Year
- Current: January 2024
- Comparison: January 2023
- Shows: Year-over-year growth/decline
