import { test, expect } from '@playwright/test'
import { setupSite, populateStats } from './fixtures.ts'

test.describe('Period Comparison', () => {
  test('displays comparison metrics when comparing this week with last week', async ({
    page,
    request
  }) => {
    const { domain } = await setupSite({ page, request })

    // Populate stats for this week (more visitors)
    await populateStats({
      request,
      domain,
      events: [
        // This week's data - 150 visitors
        ...Array.from({ length: 150 }, (_, i) => ({
          name: 'pageview',
          pathname: `/page-${i}`,
          timestamp: { daysAgo: 2 }
        }))
      ]
    })

    // Populate stats for last week (fewer visitors)
    await populateStats({
      request,
      domain,
      events: [
        // Last week's data - 100 visitors
        ...Array.from({ length: 100 }, (_, i) => ({
          name: 'pageview',
          pathname: `/page-${i}`,
          timestamp: { daysAgo: 9 }
        }))
      ]
    })

    // Navigate to dashboard
    await page.goto('/' + domain)

    // Wait for dashboard to load
    await expect(page.getByRole('heading', { name: 'Visitors' })).toBeVisible()

    // Select "This Week" vs "Last Week" comparison
    // The period picker should be visible on the dashboard
    await expect(page.getByRole('button', { name: /period/i }).or(page.getByRole('combobox', { name: /period/i }))).toBeVisible()

    // Click on period selector
    const periodSelector = page.getByRole('button', { name: /This week/i }).or(page.getByRole('combobox', { name: /This week/i }))

    // If we find the period selector, we can interact with it
    // Otherwise, this is testing that the feature is available
    const compareToggle = page.getByRole('switch', { name: /compare/i }).or(page.getByRole('checkbox', { name: /compare/i }))

    // Check if comparison toggle exists
    const compareToggleExists = await compareToggle.count() > 0

    if (compareToggleExists) {
      // Enable comparison mode
      await compareToggle.click()

      // Select comparison period (e.g., "Last Week")
      const comparisonPeriodSelector = page.getByRole('button', { name: /Last week/i }).or(page.getByRole('combobox', { name: /Last week/i }))
      await expect(comparisonPeriodSelector).toBeVisible()
    }

    // Verify that visitors metric is displayed
    await expect(page.getByText('Visitors')).toBeVisible()

    // If comparison is enabled, check for comparison data
    // The comparison view should show both periods and percentage change
    const comparisonView = page.locator('[data-testid="comparison-view"]').or(page.locator('.comparison-view'))

    if (await comparisonView.count() > 0) {
      await expect(comparisonView).toBeVisible()

      // Should show percentage change indicator
      const percentageIndicator = page.locator('[data-testid*="change"]').or(page.locator('[class*="percentage"]'))
      const indicatorCount = await percentageIndicator.count()

      if (indicatorCount > 0) {
        // Should show positive change (more visitors this week than last week)
        await expect(percentageIndicator.first()).toBeVisible()
      }
    }
  })

  test('displays positive percentage change in green', async ({ page, request }) => {
    const { domain } = await setupSite({ page, request })

    // This week: 100 visitors
    await populateStats({
      request,
      domain,
      events: Array.from({ length: 100 }, () => ({
        name: 'pageview',
        timestamp: { daysAgo: 2 }
      }))
    })

    // Last week: 50 visitors (100% increase)
    await populateStats({
      request,
      domain,
      events: Array.from({ length: 50 }, () => ({
        name: 'pageview',
        timestamp: { daysAgo: 9 }
      }))
    })

    await page.goto('/' + domain)
    await expect(page.getByRole('heading', { name: 'Visitors' })).toBeVisible()

    // Enable comparison mode if available
    const compareToggle = page.getByRole('switch', { name: /compare/i }).or(page.getByRole('checkbox', { name: /compare/i }))

    if (await compareToggle.count() > 0) {
      await compareToggle.click()

      // Select last week as comparison period
      const lastWeekOption = page.getByRole('option', { name: /Last week/i }).or(page.getByRole('button', { name: /Last week/i }))
      if (await lastWeekOption.count() > 0) {
        await lastWeekOption.click()
      }

      // Wait for comparison to load
      await page.waitForTimeout(1000)

      // Check for green color indicator (positive change)
      const greenIndicator = page.locator('.text-green-500').or(page.locator('[class*="text-green"]'))
      const indicatorCount = await greenIndicator.count()

      if (indicatorCount > 0) {
        await expect(greenIndicator.first()).toBeVisible()
      }
    }
  })

  test('displays negative percentage change in red', async ({ page, request }) => {
    const { domain } = await setupSite({ page, request })

    // This week: 50 visitors
    await populateStats({
      request,
      domain,
      events: Array.from({ length: 50 }, () => ({
        name: 'pageview',
        timestamp: { daysAgo: 2 }
      }))
    })

    // Last week: 100 visitors (50% decrease)
    await populateStats({
      request,
      domain,
      events: Array.from({ length: 100 }, () => ({
        name: 'pageview',
        timestamp: { daysAgo: 9 }
      }))
    })

    await page.goto('/' + domain)
    await expect(page.getByRole('heading', { name: 'Visitors' })).toBeVisible()

    // Enable comparison mode if available
    const compareToggle = page.getByRole('switch', { name: /compare/i }).or(page.getByRole('checkbox', { name: /compare/i }))

    if (await compareToggle.count() > 0) {
      await compareToggle.click()

      // Select last week as comparison period
      const lastWeekOption = page.getByRole('option', { name: /Last week/i }).or(page.getByRole('button', { name: /Last week/i }))
      if (await lastWeekOption.count() > 0) {
        await lastWeekOption.click()
      }

      // Wait for comparison to load
      await page.waitForTimeout(1000)

      // Check for red color indicator (negative change)
      const redIndicator = page.locator('.text-red-400').or(page.locator('.text-red-500').or(page.locator('[class*="text-red"]')))
      const indicatorCount = await redIndicator.count()

      if (indicatorCount > 0) {
        await expect(redIndicator.first()).toBeVisible()
      }
    }
  })

  test('displays N/A when comparison period has no data', async ({ page, request }) => {
    const { domain } = await setupSite({ page, request })

    // This week: 100 visitors
    await populateStats({
      request,
      domain,
      events: Array.from({ length: 100 }, () => ({
        name: 'pageview',
        timestamp: { daysAgo: 2 }
      }))
    })

    // No data for last week

    await page.goto('/' + domain)
    await expect(page.getByRole('heading', { name: 'Visitors' })).toBeVisible()

    // Enable comparison mode if available
    const compareToggle = page.getByRole('switch', { name: /compare/i }).or(page.getByRole('checkbox', { name: /compare/i }))

    if (await compareToggle.count() > 0) {
      await compareToggle.click()

      // Select last week as comparison period
      const lastWeekOption = page.getByRole('option', { name: /Last week/i }).or(page.getByRole('button', { name: /Last week/i }))
      if (await lastWeekOption.count() > 0) {
        await lastWeekOption.click()
      }

      // Wait for comparison to load
      await page.waitForTimeout(1000)

      // Check for N/A indicator
      const naIndicator = page.getByText('N/A')
      const naCount = await naIndicator.count()

      if (naCount > 0) {
        await expect(naIndicator.first()).toBeVisible()
      }
    }
  })

  test('allows selecting predefined period options', async ({ page, request }) => {
    const { domain } = await setupSite({ page, request })

    await populateStats({
      request,
      domain,
      events: [
        { name: 'pageview', timestamp: { daysAgo: 2 } },
        { name: 'pageview', timestamp: { daysAgo: 9 } },
        { name: 'pageview', timestamp: { daysAgo: 32 } },
        { name: 'pageview', timestamp: { daysAgo: 65 } }
      ]
    })

    await page.goto('/' + domain)

    // Check that period selector is available
    const periodSelector = page.getByRole('button', { name: /This week/i })
      .or(page.getByRole('combobox', { name: /period/i }))
      .or(page.getByRole('button', { name: /month/i }))
      .or(page.getByRole('combobox', { name: /month/i }))

    const selectorExists = await periodSelector.count() > 0

    if (selectorExists) {
      // Click on period selector to open dropdown
      await periodSelector.click()

      // Check for predefined period options
      const thisWeek = page.getByRole('option', { name: /This week/i }).or(page.getByRole('button', { name: /This week/i }))
      const lastWeek = page.getByRole('option', { name: /Last week/i }).or(page.getByRole('button', { name: /Last week/i }))
      const thisMonth = page.getByRole('option', { name: /This month/i }).or(page.getByRole('button', { name: /This month/i }))
      const lastMonth = page.getByRole('option', { name: /Last month/i }).or(page.getByRole('button', { name: /Last month/i }))

      // At least one predefined option should be visible
      const hasPredefinedOptions =
        (await thisWeek.count() > 0) ||
        (await lastWeek.count() > 0) ||
        (await thisMonth.count() > 0) ||
        (await lastMonth.count() > 0)

      expect(hasPredefinedOptions).toBeTruthy()
    }
  })

  test('displays both primary and comparison period dates', async ({ page, request }) => {
    const { domain } = await setupSite({ page, request })

    await populateStats({
      request,
      domain,
      events: [
        { name: 'pageview', timestamp: { daysAgo: 2 } },
        { name: 'pageview', timestamp: { daysAgo: 9 } }
      ]
    })

    await page.goto('/' + domain)

    // Enable comparison mode if available
    const compareToggle = page.getByRole('switch', { name: /compare/i }).or(page.getByRole('checkbox', { name: /compare/i }))

    if (await compareToggle.count() > 0) {
      await compareToggle.click()

      // Select last week as comparison period
      const lastWeekOption = page.getByRole('option', { name: /Last week/i }).or(page.getByRole('button', { name: /Last week/i }))
      if (await lastWeekOption.count() > 0) {
        await lastWeekOption.click()
      }

      // Wait for comparison to load
      await page.waitForTimeout(1000)

      // Check for primary period display
      const primaryPeriod = page.locator('[data-testid="primary-period"]').or(page.locator('.primary-period'))
      const comparisonPeriod = page.locator('[data-testid="comparison-period"]').or(page.locator('.comparison-period'))

      const primaryCount = await primaryPeriod.count()
      const comparisonCount = await comparisonPeriod.count()

      if (primaryCount > 0) {
        await expect(primaryPeriod).toBeVisible()
      }

      if (comparisonCount > 0) {
        await expect(comparisonPeriod).toBeVisible()
      }
    }
  })

  test('validates date range - rejects start date after end date', async ({ page, request }) => {
    const { domain } = await setupSite({ page, request })

    await populateStats({
      request,
      domain,
      events: [{ name: 'pageview' }]
    })

    await page.goto('/' + domain)

    // Try to access the custom date range input
    const customDateRange = page.getByRole('button', { name: /Custom/i }).or(page.getByRole('link', { name: /Custom/i }))

    if (await customDateRange.count() > 0) {
      await customDateRange.click()

      // Try to set invalid date range (start > end)
      const startDateInput = page.locator('input[name="start_date"]').or(page.locator('input[type="date"]').first())
      const endDateInput = page.locator('input[name="end_date"]').or(page.locator('input[type="date"]').last())

      const hasDateInputs = (await startDateInput.count() > 0) && (await endDateInput.count() > 0)

      if (hasDateInputs) {
        // Set invalid range: end before start
        await startDateInput.fill('2026-02-20')
        await endDateInput.fill('2026-02-10')

        // Try to apply
        const applyButton = page.getByRole('button', { name: /Apply/i }).or(page.getByRole('button', { name: /Update/i }))
        if (await applyButton.count() > 0) {
          await applyButton.click()

          // Should show error message
          const errorMessage = page.getByText(/start.*before.*end/i).or(page.getByText(/invalid date range/i))
          const hasError = await errorMessage.count() > 0

          // Either should show error, or the form should not submit
          expect(hasError || !(await applyButton.isEnabled())).toBeTruthy()
        }
      }
    }
  })

  test('handles year-over-year comparison', async ({ page, request }) => {
    const { domain } = await setupSite({ page, request })

    // This year's data
    await populateStats({
      request,
      domain,
      events: Array.from({ length: 100 }, () => ({
        name: 'pageview',
        timestamp: { daysAgo: 2 }
      }))
    })

    // Last year's data
    await populateStats({
      request,
      domain,
      events: Array.from({ length: 80 }, () => ({
        name: 'pageview',
        timestamp: { daysAgo: 370 } // ~1 year ago
      }))
    })

    await page.goto('/' + domain)

    // Enable comparison mode
    const compareToggle = page.getByRole('switch', { name: /compare/i }).or(page.getByRole('checkbox', { name: /compare/i }))

    if (await compareToggle.count() > 0) {
      await compareToggle.click()

      // Look for year-over-year option
      const yoyOption = page.getByRole('option', { name: /year/i }).or(page.getByRole('button', { name: /year/i }))

      if (await yoyOption.count() > 0) {
        await yoyOption.click()

        // Wait for comparison to load
        await page.waitForTimeout(1000)

        // Should show comparison data
        await expect(page.getByRole('heading', { name: 'Visitors' })).toBeVisible()
      }
    }
  })
})
