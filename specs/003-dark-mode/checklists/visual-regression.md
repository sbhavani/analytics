# Visual Regression Test Checklist: Theme Consistency

**Feature**: Dark Mode Theme
**User Story**: US3 - Consistent Styling Across All Dashboard Components
**Task**: T016

## Purpose

This checklist ensures all dashboard components render correctly in both light and dark themes. Use this for manual visual regression testing or to guide automated screenshot testing.

---

## Test Setup

- [ ] Enable dark mode in browser DevTools: `prefers-color-scheme: dark`
- [ ] Clear localStorage to test fresh theme detection
- [ ] Test on viewport widths: 320px (mobile), 768px (tablet), 1280px (desktop)
- [ ] Use browser's accessibility inspector to verify color contrast ratios

---

## 1. Layout & Navigation

### Header
- [ ] Header background color changes correctly (light: white/gray, dark: dark gray/black)
- [ ] Header text is readable in both themes
- [ ] Logo/Site name visibility in both themes
- [ ] Theme toggle button is visible and functional

### Sidebar / Navigation Menu
- [ ] Navigation items have proper contrast in light mode
- [ ] Navigation items have proper contrast in dark mode
- [ ] Active/selected state is visible in both themes
- [ ] Hover states work correctly in both themes
- [ ] Icons are visible and appropriately colored in both themes

### Main Content Area
- [ ] Page background switches correctly
- [ ] Content containers have appropriate borders in both themes
- [ ] No white flashes during theme transition

---

## 2. Data Display Components

### Tables (assets/js/dashboard/components/table.tsx)
- [ ] Table header background adapts to theme
- [ ] Table header text is readable
- [ ] Table rows have alternating backgrounds (zebra striping) in both themes
- [ ] Table borders are visible in both themes
- [ ] Cell text contrast is sufficient in both themes

### Metrics / KPI Cards
- [ ] Card background color changes correctly
- [ ] Metric values are readable in both themes
- [ ] Change indicators (arrows, percentages) are visible in both themes
- [ ] Sparkline charts render correctly in both themes

### Charts (assets/js/dashboard/stats/graph/)
- [ ] Chart background adapts to theme
- [ ] Grid lines are visible in both themes
- [ ] Axis labels are readable in both themes
- [ ] Tooltips have proper styling in both themes
- [ ] Chart colors have sufficient contrast against dark background

### Lists (assets/js/dashboard/stats/reports/list.tsx)
- [ ] List item backgrounds adapt correctly
- [ ] List item text is readable
- [ ] List item borders are visible
- [ ] Expand/collapse icons work correctly

---

## 3. Form Components

### Inputs & Text Fields
- [ ] Input background color changes with theme
- [ ] Input text color is readable
- [ ] Placeholder text is visible in both themes
- [ ] Input borders are visible in both themes
- [ ] Focus states are visible in both themes

### Buttons
- [ ] Primary button styling works in both themes
- [ ] Secondary button styling works in both themes
- [ ] Disabled button styling works in both themes
- [ ] Hover states are visible in both themes
- [ ] Loading states are visible in both themes

### Dropdowns / Selects
- [ ] Dropdown trigger styling adapts to theme
- [ ] Dropdown menu background is correct in both themes
- [ ] Menu items are readable in both themes
- [ ] Selected state is visible in both themes

### Date Pickers (assets/js/dashboard/nav-menu/query-periods/)
- [ ] Calendar grid renders correctly in both themes
- [ ] Selected date is visible in both themes
- [ ] Hover states work in both themes
- [ ] Navigation arrows are visible in both themes

---

## 4. Interactive Components

### Modals / Dialogs
- [ ] Modal overlay is visible in both themes
- [ ] Modal background adapts to theme
- [ ] Modal header is readable
- [ ] Modal body text is readable
- [ ] Modal close button is visible in both themes

### Popovers & Tooltips
- [ ] Popover background is correct in both themes
- [ ] Popover text is readable
- [ ] Arrow/pointer is visible in both themes

### Filter Pills / Tags
- [ ] Pill background color works in both themes
- [ ] Pill text is readable
- [ ] Remove button (x) is visible in both themes

### Tabs (assets/js/dashboard/components/tabs.tsx)
- [ ] Tab styling adapts to theme
- [ ] Active tab is visually distinct in both themes
- [ ] Tab content area has proper background

### Error States
- [ ] Error messages are visible in both themes
- [ ] Error backgrounds are appropriate in both themes
- [ ] Error icons are visible in both themes

---

## 5. Responsive Behavior

### Mobile (320px - 480px)
- [ ] Navigation collapses appropriately in both themes
- [ ] Touch targets are appropriately sized in both themes
- [ ] Text remains readable at small sizes in both themes

### Tablet (481px - 1024px)
- [ ] Layout adapts correctly in both themes
- [ ] Side navigation or hamburger menu works in both themes

### Desktop (1025px+)
- [ ] Full layout renders correctly in both themes
- [ ] All columns/panels visible in both themes

---

## 6. Accessibility

- [ ] Color contrast ratio meets WCAG AA (4.5:1 for normal text)
- [ ] Large text meets WCAG AA (3:1 for 18pt+ text)
- [ ] Focus indicators are visible in both themes
- [ ] No color-only information indicators

---

## 7. Cross-Browser Verification

- [ ] Chrome: All checks pass
- [ ] Firefox: All checks pass
- [ ] Safari: All checks pass
- [ ] Edge: All checks pass

---

## 8. Theme Transition

- [ ] No visible flash of unstyled content (FOUC) on page load
- [ ] Theme toggle is instant (< 100ms perceived)
- [ ] No layout shift during theme change
- [ ] Smooth transition animation (if enabled) works correctly

---

## 9. Persistence Verification

- [ ] Theme preference persists after page refresh
- [ ] Theme preference persists after browser restart
- [ ] Theme preference syncs across tabs (if applicable)

---

## Screenshots for Regression

Take screenshots of these pages in both themes:

1. **Dashboard Overview** - Main metrics and charts
2. **Sources Page** - Table with list data
3. **Goals Page** - Goal configuration forms
4. **Settings Page** - Form inputs and buttons
5. **Filter Modal** - Complex modal with multiple inputs
6. **Date Picker** - Calendar component
7. **Mobile View** - Responsive layout at 375px width

---

## Notes

- Use browser DevTools to force `prefers-color-scheme` media query
- Test with both system preference set to light AND dark
- Verify all custom CSS variables are properly defined in both themes
- Check for any hardcoded hex colors that may override theme variables

---

## Test Execution

| Component | Light Mode | Dark Mode | Notes |
|-----------|------------|-----------|-------|
| Header | [ ] | [ ] | |
| Navigation | [ ] | [ ] | |
| Tables | [ ] | [ ] | |
| Charts | [ ] | [ ] | |
| Forms | [ ] | [ ] | |
| Modals | [ ] | [ ] | |
| Mobile | [ ] | [ ] | |
| Accessibility | [ ] | [ ] | |

**Status**: Pending execution
**Last Updated**: 2026-02-26
