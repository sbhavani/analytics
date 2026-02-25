# Quickstart Guide: Time Period Comparison

## Overview

This feature enables users to compare analytics metrics between two date ranges with percentage change display.

## Getting Started

### Prerequisites

- Plausible Analytics application running
- Access to an analytics site with data
- User account with site access

### Quick Comparison (Predefined Periods)

1. Navigate to your site dashboard
2. Click on the period selector dropdown
3. Select a predefined comparison pair:
   - This Week vs Last Week
   - This Month vs Last Month
   - This Quarter vs Last Quarter
   - This Year vs Last Year
4. View the comparison results showing:
   - Current period value
   - Comparison period value
   - Percentage change (positive/negative)
   - Visual indicator (color-coded)

### Custom Comparison

1. Select "Custom" from the period selector
2. Choose start and end dates for current period
3. Choose start and end dates for comparison period
4. View side-by-side comparison

## Testing Scenarios

### Basic Period Comparison

1. Select "This Week vs Last Week"
2. Verify both values display correctly
3. Verify percentage change matches manual calculation
4. Verify color coding (green for positive, red for negative)

### No Data Handling

1. Select a date range with no analytics data
2. Verify appropriate "No data" message displays
3. Verify no errors occur

### Zero Comparison Value

1. Select comparison period where metric = 0
2. Verify "N/A" or "No data to compare" displays
3. Verify no division by zero errors

### Persistence

1. Select a comparison period
2. Navigate away from dashboard
3. Return to dashboard
4. Verify previous selection persists

## Expected Results

| Scenario | Current Value | Previous Value | % Change | Display |
|----------|---------------|----------------|----------|---------|
| Growth | 1250 | 1000 | +25% | Green, +25% |
| Decline | 800 | 1000 | -20% | Red, -20% |
| No Change | 1000 | 1000 | 0% | Gray, 0% |
| Previous = 0 | 100 | 0 | N/A | "N/A" |
| Both = 0 | 0 | 0 | 0% | "No change" |
