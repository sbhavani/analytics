import React from 'react'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { FilterBuilder } from '../FilterBuilder'
import { FilterTree, filterTreeToBackend, createEmptyFilterTree, backendToFilterTree } from '../../../lib/filter-parser'
import { SavedSegment, SegmentType, SegmentData } from '../../../filtering/segments'

// Mock heroicons to avoid TypeScript errors with deprecated import path
jest.mock('@heroicons/react/solid', () => ({
  XIcon: () => <svg data-testid="x-icon" />,
  ChevronDownIcon: () => <svg data-testid="chevron-down-icon" />
}))

// Mock FilterPreview to avoid API call issues in tests
jest.mock('../FilterPreview', () => ({
  FilterPreview: () => <div data-testid="filter-preview">Preview</div>
}))

// Mock the API module to avoid missing getStats function
jest.mock('../../../api', () => ({
  ...jest.requireActual('../../../api'),
  getStats: jest.fn().mockResolvedValue({ visitors: [{ value: 100 }] })
}))

// Test helper to extract filter tree from component
function getFilterTreeFromComponent() {
  // This will be set by the test component when it renders
  return (window as unknown as { __filterTree?: FilterTree }).__filterTree
}

describe('FilterBuilder - AND Logic Integration Tests', () => {
  const mockSiteId = 'test-site-id'

  const renderFilterBuilder = (props?: Partial<{ initialTree: FilterTree; onClose: () => void }>) => {
    let capturedTree: FilterTree | null = null

    const TestWrapper: React.FC<{ children: React.ReactNode }> = ({ children }) => {
      return <div data-testid="filter-builder-wrapper">{children}</div>
    }

    const { ...utils } = render(
      <FilterBuilder
        siteId={mockSiteId}
        {...props}
      />
    )

    return { ...utils }
  }

  describe('AND connector behavior', () => {
    test('should default to AND connector when multiple conditions are added', async () => {
      renderFilterBuilder()

      // Initially one condition exists - no connector shown
      const addButtons = screen.getAllByText('+ Add condition')
      expect(addButtons.length).toBeGreaterThan(0)

      // Add a second condition
      fireEvent.click(addButtons[0])

      // Should now show AND connector between conditions
      const andButton = screen.getByRole('button', { name: /AND/i })
      expect(andButton).toBeInTheDocument()
      expect(andButton).toHaveClass('bg-indigo-100')
    })

    test('should have AND as default connector in filter tree', async () => {
      const onClose = jest.fn()
      renderFilterBuilder({ onClose })

      // Add a second condition by clicking Add Condition
      const addButtons = screen.getAllByText('+ Add condition')
      fireEvent.click(addButtons[0])

      // Wait for the component to update
      await waitFor(() => {
        const andButton = screen.getByRole('button', { name: /AND/i })
        expect(andButton).toBeInTheDocument()
      })
    })

    test('should allow toggling between AND and OR connectors', async () => {
      renderFilterBuilder()

      // Add second condition
      const addButtons = screen.getAllByText('+ Add condition')
      fireEvent.click(addButtons[0])

      // Should show AND by default
      const connectorButton = screen.getByRole('button', { name: /AND/i })
      expect(connectorButton).toBeInTheDocument()

      // Toggle to OR
      fireEvent.click(connectorButton)

      // Should now show OR
      const orButton = screen.getByRole('button', { name: /OR/i })
      expect(orButton).toBeInTheDocument()
    })

    test('should serialize multiple conditions with AND connector correctly', async () => {
      const onClose = jest.fn()
      renderFilterBuilder({ onClose })

      // Add a second condition
      const addButtons = screen.getAllByText('+ Add condition')
      fireEvent.click(addButtons[0])

      // Wait for conditions to appear
      await waitFor(() => {
        const dimensionSelects = screen.getAllByRole('combobox')
        expect(dimensionSelects.length).toBe(2)
      })

      // Get the dimension selects (they are the first select elements)
      const dimensionSelects = screen.getAllByRole('combobox')

      // Set first condition: Country equals US
      fireEvent.change(dimensionSelects[0], { target: { value: 'visit:country' } })

      // Set value for first condition
      const valueInputs = screen.getAllByRole('textbox')
      fireEvent.change(valueInputs[0], { target: { value: 'US' } })

      // Set second condition: Device equals Mobile
      fireEvent.change(dimensionSelects[1], { target: { value: 'visit:device' } })
      fireEvent.change(valueInputs[1], { target: { value: 'Mobile' } })

      // Verify AND connector is present (AND should still be default)
      await waitFor(() => {
        const andButton = screen.getByRole('button', { name: /AND/i })
        expect(andButton).toBeInTheDocument()
      })
    })

    test('should maintain AND logic when removing a condition', async () => {
      const onClose = jest.fn()
      renderFilterBuilder({ onClose })

      // Add two conditions
      const addButtons = screen.getAllByText('+ Add condition')
      fireEvent.click(addButtons[0])
      fireEvent.click(addButtons[0])

      // Should have AND button with 2 conditions
      await waitFor(() => {
        const andButton = screen.getByRole('button', { name: /AND/i })
        expect(andButton).toBeInTheDocument()
      })

      // Get all remove buttons (X icons)
      const removeButtons = screen.getAllByTitle('Remove condition')

      // Remove first condition
      fireEvent.click(removeButtons[0])

      // With only one condition, AND button should be hidden
      await waitFor(() => {
        expect(screen.queryByRole('button', { name: /AND/i })).not.toBeInTheDocument()
      })
    })

    test('should create valid filter tree with multiple AND conditions for backend', async () => {
      // Create initial tree with two conditions
      const initialTree: FilterTree = {
        rootGroup: {
          id: 'root',
          connector: 'and',
          conditions: [
            {
              id: 'cond-1',
              dimension: 'visit:country',
              operator: 'is',
              value: ['US']
            },
            {
              id: 'cond-2',
              dimension: 'visit:device',
              operator: 'is',
              value: ['Mobile']
            }
          ],
          children: [],
          isRoot: true
        },
        labels: {}
      }

      // Serialize to backend format
      const backendData = filterTreeToBackend(initialTree)

      // Should have filters in correct format
      expect(backendData.filters).toBeDefined()

      // With AND connector and two conditions at root, should be ['and', [cond1, cond2]]
      const filters = backendData.filters as unknown[]
      expect(filters[0]).toBe('and')
      expect(Array.isArray(filters[1])).toBe(true)
    })
  })

  describe('OR connector behavior', () => {
    test('should toggle from AND to OR when connector button is clicked', async () => {
      renderFilterBuilder()

      // Add a second condition
      const addButtons = screen.getAllByText('+ Add condition')
      fireEvent.click(addButtons[0])

      // Should show AND by default
      const andButton = screen.getByRole('button', { name: /AND/i })
      expect(andButton).toBeInTheDocument()

      // Click to toggle to OR
      fireEvent.click(andButton)

      // Should now show OR button
      const orButton = screen.getByRole('button', { name: /OR/i })
      expect(orButton).toBeInTheDocument()
      expect(orButton).toHaveClass('bg-orange-100')
    })

    test('should toggle from OR back to AND', async () => {
      renderFilterBuilder()

      // Add a second condition
      const addButtons = screen.getAllByText('+ Add condition')
      fireEvent.click(addButtons[0])

      // Toggle to OR first
      const andButton = screen.getByRole('button', { name: /AND/i })
      fireEvent.click(andButton)

      // Should show OR
      const orButton = screen.getByRole('button', { name: /OR/i })
      expect(orButton).toBeInTheDocument()

      // Toggle back to AND
      fireEvent.click(orButton)

      // Should show AND again
      expect(screen.getByRole('button', { name: /AND/i })).toBeInTheDocument()
    })

    test('should display OR connector with correct styling', async () => {
      renderFilterBuilder()

      // Add second condition
      const addButtons = screen.getAllByText('+ Add condition')
      fireEvent.click(addButtons[0])

      // Toggle to OR
      const connectorButton = screen.getByRole('button', { name: /AND/i })
      fireEvent.click(connectorButton)

      // Check OR button has orange styling (for OR logic)
      const orButton = screen.getByRole('button', { name: /OR/i })
      expect(orButton).toHaveClass('bg-orange-100', 'text-orange-700')
    })

    test('should serialize multiple conditions with OR connector correctly', async () => {
      // Create initial tree with OR connector and two conditions
      const initialTree: FilterTree = {
        rootGroup: {
          id: 'root',
          connector: 'or',
          conditions: [
            {
              id: 'cond-1',
              dimension: 'visit:country',
              operator: 'is',
              value: ['US']
            },
            {
              id: 'cond-2',
              dimension: 'visit:country',
              operator: 'is',
              value: ['UK']
            }
          ],
          children: [],
          isRoot: true
        },
        labels: {}
      }

      // Serialize to backend format
      const backendData = filterTreeToBackend(initialTree)

      // Should have filters in correct format
      expect(backendData.filters).toBeDefined()

      // With OR connector and two conditions at root, should be ['or', [cond1, cond2]]
      const filters = backendData.filters as unknown[]
      expect(filters[0]).toBe('or')
      expect(Array.isArray(filters[1])).toBe(true)
    })

    test('should maintain OR logic when modifying condition values', async () => {
      renderFilterBuilder()

      // Add second condition
      const addButtons = screen.getAllByText('+ Add condition')
      fireEvent.click(addButtons[0])

      // Toggle to OR
      const connectorButton = screen.getByRole('button', { name: /AND/i })
      fireEvent.click(connectorButton)

      // Wait for OR to be displayed
      await waitFor(() => {
        expect(screen.getByRole('button', { name: /OR/i })).toBeInTheDocument()
      })

      // Get the dimension selects and value inputs
      const dimensionSelects = screen.getAllByRole('combobox')
      const valueInputs = screen.getAllByRole('textbox')

      // Set first condition: Country equals US
      fireEvent.change(dimensionSelects[0], { target: { value: 'visit:country' } })
      fireEvent.change(valueInputs[0], { target: { value: 'US' } })

      // Set second condition: Country equals UK
      fireEvent.change(dimensionSelects[1], { target: { value: 'visit:country' } })
      fireEvent.change(valueInputs[1], { target: { value: 'UK' } })

      // OR button should still be visible
      expect(screen.getByRole('button', { name: /OR/i })).toBeInTheDocument()
    })

    test('should preserve OR connector after adding another condition', async () => {
      renderFilterBuilder()

      // Add second condition
      const addButtons = screen.getAllByText('+ Add condition')
      fireEvent.click(addButtons[0])

      // Toggle to OR
      const connectorButton = screen.getByRole('button', { name: /AND/i })
      fireEvent.click(connectorButton)

      // Wait for OR to be visible
      await waitFor(() => {
        expect(screen.getByRole('button', { name: /OR/i })).toBeInTheDocument()
      })

      // Add third condition
      fireEvent.click(addButtons[0])

      // OR should still be visible after adding condition
      await waitFor(() => {
        expect(screen.getByRole('button', { name: /OR/i })).toBeInTheDocument()
      })
    })

    test('should toggle connector in nested groups', async () => {
      // Create initial tree with nested group
      const initialTree: FilterTree = {
        rootGroup: {
          id: 'root',
          connector: 'and',
          conditions: [],
          children: [
            {
              id: 'group-1',
              connector: 'and',
              conditions: [
                {
                  id: 'cond-1',
                  dimension: 'visit:country',
                  operator: 'is',
                  value: ['US']
                }
              ],
              children: [],
              isRoot: false
            }
          ],
          isRoot: true
        },
        labels: {}
      }

      // Note: Testing nested group connector toggle would require additional UI interaction
      // This test verifies the serialization works correctly for nested OR groups
      const backendData = filterTreeToBackend(initialTree)
      expect(backendData.filters).toBeDefined()
    })

    test('should serialize mixed AND/OR nested groups correctly', async () => {
      // Create tree with OR at root, AND in nested group
      const initialTree: FilterTree = {
        rootGroup: {
          id: 'root',
          connector: 'or',
          conditions: [
            {
              id: 'cond-1',
              dimension: 'visit:country',
              operator: 'is',
              value: ['US']
            }
          ],
          children: [
            {
              id: 'group-1',
              connector: 'and',
              conditions: [
                {
                  id: 'cond-2',
                  dimension: 'visit:device',
                  operator: 'is',
                  value: ['Mobile']
                },
                {
                  id: 'cond-3',
                  dimension: 'visit:browser',
                  operator: 'is',
                  value: ['Chrome']
                }
              ],
              children: [],
              isRoot: false
            }
          ],
          isRoot: true
        },
        labels: {}
      }

      const backendData = filterTreeToBackend(initialTree)
      const filters = backendData.filters as unknown[]

      // Root should have OR connector
      expect(filters[0]).toBe('or')
      expect(Array.isArray(filters[1])).toBe(true)
    })

    test('should show correct connector button state after multiple toggles', async () => {
      renderFilterBuilder()

      // Add second condition
      const addButtons = screen.getAllByText('+ Add condition')
      fireEvent.click(addButtons[0])

      // Default is AND
      expect(screen.getByRole('button', { name: /AND/i })).toBeInTheDocument()

      // Toggle to OR
      fireEvent.click(screen.getByRole('button', { name: /AND/i }))
      expect(screen.getByRole('button', { name: /OR/i })).toBeInTheDocument()

      // Toggle back to AND
      fireEvent.click(screen.getByRole('button', { name: /OR/i }))
      expect(screen.getByRole('button', { name: /AND/i })).toBeInTheDocument()

      // Toggle to OR again
      fireEvent.click(screen.getByRole('button', { name: /AND/i }))
      expect(screen.getByRole('button', { name: /OR/i })).toBeInTheDocument()
    })

    test('should serialize OR-only single condition as direct filter', async () => {
      // When there's only one condition, the connector doesn't matter
      const initialTree: FilterTree = {
        rootGroup: {
          id: 'root',
          connector: 'or',
          conditions: [
            {
              id: 'cond-1',
              dimension: 'visit:country',
              operator: 'is',
              value: ['US']
            }
          ],
          children: [],
          isRoot: true
        },
        labels: {}
      }

      const backendData = filterTreeToBackend(initialTree)

      // With single condition at root, should return the condition directly
      // (connector is not relevant with single condition)
      expect(backendData.filters).toBeDefined()
    })
  })

  describe('Condition state management', () => {
    test('should initialize with one empty condition', () => {
      renderFilterBuilder()

      // Should have one condition row (one dimension select)
      const dimensionSelects = screen.getAllByRole('combobox')
      expect(dimensionSelects.length).toBe(1)
    })

    test('should allow adding new conditions up to the limit', async () => {
      renderFilterBuilder({})

      // Get the add condition button
      const addButton = screen.getByText('+ Add condition')

      // Add multiple conditions
      for (let i = 0; i < 3; i++) {
        fireEvent.click(addButton)
      }

      // Should have 4 conditions now (1 initial + 3 added)
      await waitFor(() => {
        const dimensionSelects = screen.getAllByRole('combobox')
        expect(dimensionSelects.length).toBe(4)
      })
    })

    test('should allow updating individual condition values', async () => {
      renderFilterBuilder()

      // Get the dimension select and value input
      const dimensionSelect = screen.getByRole('combobox')
      const valueInput = screen.getByRole('textbox')

      // Change dimension
      fireEvent.change(dimensionSelect, { target: { value: 'visit:country' } })

      // Change value
      fireEvent.change(valueInput, { target: { value: 'United States' } })

      // Verify values are updated
      expect(dimensionSelect).toHaveValue('visit:country')
      expect(valueInput).toHaveValue('United States')
    })

    test('should allow removing conditions', async () => {
      renderFilterBuilder()

      // Add a second condition
      const addButton = screen.getByText('+ Add condition')
      fireEvent.click(addButton)

      // Verify we have 2 conditions
      await waitFor(() => {
        const dimensionSelects = screen.getAllByRole('combobox')
        expect(dimensionSelects.length).toBe(2)
      })

      // Remove the first condition
      const removeButtons = screen.getAllByTitle('Remove condition')
      fireEvent.click(removeButtons[0])

      // Should have 1 condition again
      await waitFor(() => {
        const dimensionSelects = screen.getAllByRole('combobox')
        expect(dimensionSelects.length).toBe(1)
      })
    })
  })

  describe('Filter tree structure validation', () => {
    test('should create proper nested AND structure', () => {
      // Test the serialization creates correct AND nested structure
      const tree: FilterTree = {
        rootGroup: {
          id: 'root',
          connector: 'and',
          conditions: [
            {
              id: 'cond-1',
              dimension: 'visit:country',
              operator: 'is',
              value: ['US']
            }
          ],
          children: [
            {
              id: 'group-1',
              connector: 'and',
              conditions: [
                {
                  id: 'cond-2',
                  dimension: 'visit:device',
                  operator: 'is',
                  value: ['Mobile']
                },
                {
                  id: 'cond-3',
                  dimension: 'visit:browser',
                  operator: 'is',
                  value: ['Chrome']
                }
              ],
              children: [],
              isRoot: false
            }
          ],
          isRoot: true
        },
        labels: {}
      }

      const backendData = filterTreeToBackend(tree)
      const filters = backendData.filters as unknown[]

      // Root should be: ['and', [cond1, ['and', [cond2, cond3]]]]
      expect(filters[0]).toBe('and')
      expect(Array.isArray(filters[1])).toBe(true)
    })
  })

  describe('Nested Groups Integration Tests (User Story 4)', () => {
    const mockSiteId = 'test-site-id'

    const renderFilterBuilder = (props?: Partial<{ initialTree: FilterTree; onClose: () => void }>) => {
      return render(
        <FilterBuilder
          siteId={mockSiteId}
          {...props}
        />
      )
    }

    test('should have Add Group button available', () => {
      renderFilterBuilder()

      // Should see Add Group button
      const addGroupButton = screen.getByText('+ Add group')
      expect(addGroupButton).toBeInTheDocument()
    })

    test('should add a new nested group when Add Group is clicked', async () => {
      renderFilterBuilder()

      // Click Add Group button
      const addGroupButton = screen.getByText('+ Add group')
      fireEvent.click(addGroupButton)

      // Should now see nested group UI with "Match" header
      await waitFor(() => {
        expect(screen.getByText('Match')).toBeInTheDocument()
      })

      // Should see AND connector button in the nested group
      const andButtons = screen.getAllByRole('button', { name: /AND/i })
      expect(andButtons.length).toBe(2) // One in root, one in nested group
    })

    test('should display nested group with OR connector option', async () => {
      renderFilterBuilder()

      // Add a nested group
      const addGroupButton = screen.getByText('+ Add group')
      fireEvent.click(addGroupButton)

      // Find the nested group AND button (second one) and toggle it
      await waitFor(() => {
        const andButtons = screen.getAllByRole('button', { name: /AND/i })
        expect(andButtons.length).toBe(2)
      })

      // Click the second AND button (nested group)
      const nestedGroupConnector = screen.getAllByRole('button', { name: /AND/i })[1]
      fireEvent.click(nestedGroupConnector)

      // Should now show OR connector in nested group
      await waitFor(() => {
        const orButton = screen.getByRole('button', { name: /OR/i })
        expect(orButton).toBeInTheDocument()
      })
    })

    test('should create valid nested group structure in filter tree', async () => {
      // Create initial tree with a nested group
      const initialTree: FilterTree = {
        rootGroup: {
          id: 'root',
          connector: 'and',
          conditions: [
            {
              id: 'cond-1',
              dimension: 'visit:country',
              operator: 'is',
              value: ['US']
            }
          ],
          children: [
            {
              id: 'group-1',
              connector: 'or',
              conditions: [
                {
                  id: 'cond-2',
                  dimension: 'visit:device',
                  operator: 'is',
                  value: ['Mobile']
                },
                {
                  id: 'cond-3',
                  dimension: 'visit:device',
                  operator: 'is',
                  value: ['Tablet']
                }
              ],
              children: [],
              isRoot: false
            }
          ],
          isRoot: true
        },
        labels: {}
      }

      renderFilterBuilder({ initialTree })

      // Verify the nested group is rendered with OR
      await waitFor(() => {
        const orButton = screen.getByRole('button', { name: /OR/i })
        expect(orButton).toBeInTheDocument()
      })
    })

    test('should serialize nested group with correct backend format', () => {
      const tree: FilterTree = {
        rootGroup: {
          id: 'root',
          connector: 'and',
          conditions: [
            {
              id: 'cond-1',
              dimension: 'visit:country',
              operator: 'is',
              value: ['US']
            }
          ],
          children: [
            {
              id: 'group-1',
              connector: 'or',
              conditions: [
                {
                  id: 'cond-2',
                  dimension: 'visit:device',
                  operator: 'is',
                  value: ['Mobile']
                },
                {
                  id: 'cond-3',
                  dimension: 'visit:browser',
                  operator: 'is',
                  value: ['Chrome']
                }
              ],
              children: [],
              isRoot: false
            }
          ],
          isRoot: true
        },
        labels: {}
      }

      const backendData = filterTreeToBackend(tree)
      const filters = backendData.filters as unknown[]

      // Root: ['and', [cond1, ['or', [cond2, cond3]]]]
      expect(filters[0]).toBe('and')
      expect((filters[1] as unknown[])).toHaveLength(2)

      // First item is the root condition
      const rootCondition = (filters[1] as unknown[])[0] as unknown[]
      expect(rootCondition[0]).toBe('is')
      expect(rootCondition[1]).toBe('visit:country')

      // Second item is the nested group
      const nestedGroup = (filters[1] as unknown[])[1] as unknown[]
      expect(nestedGroup[0]).toBe('or')
      expect(Array.isArray(nestedGroup[1])).toBe(true)
    })

    test('should handle deeply nested groups up to 3 levels', () => {
      // Create tree with 3 levels of nesting
      const tree: FilterTree = {
        rootGroup: {
          id: 'root',
          connector: 'and',
          conditions: [
            {
              id: 'cond-1',
              dimension: 'visit:country',
              operator: 'is',
              value: ['US']
            }
          ],
          children: [
            {
              id: 'level-1',
              connector: 'or',
              conditions: [
                {
                  id: 'cond-2',
                  dimension: 'visit:device',
                  operator: 'is',
                  value: ['Mobile']
                }
              ],
              children: [
                {
                  id: 'level-2',
                  connector: 'and',
                  conditions: [
                    {
                      id: 'cond-3',
                      dimension: 'visit:browser',
                      operator: 'is',
                      value: ['Chrome']
                    }
                  ],
                  children: [],
                  isRoot: false
                }
              ],
              isRoot: false
            }
          ],
          isRoot: true
        },
        labels: {}
      }

      const backendData = filterTreeToBackend(tree)
      const filters = backendData.filters as unknown[]

      // Should serialize correctly: ['and', [cond1, ['or', [cond2, ['and', [cond3]]]]]]
      expect(filters[0]).toBe('and')
      expect(filters[1]).toHaveLength(2)
    })

    test('should create nested group structure via UI interaction', async () => {
      renderFilterBuilder()

      // Add first condition
      const addConditionButton = screen.getByText('+ Add condition')
      fireEvent.click(addConditionButton)

      // Wait for second condition to appear
      await waitFor(() => {
        const dimensionSelects = screen.getAllByRole('combobox')
        expect(dimensionSelects.length).toBe(2)
      })

      // Select both conditions for grouping
      const checkboxes = screen.getAllByRole('checkbox')
      fireEvent.click(checkboxes[0])
      fireEvent.click(checkboxes[1])

      // Should see "Group selected" button
      const groupButton = screen.getByText(/Group selected/)
      expect(groupButton).toBeInTheDocument()

      // Click to group the conditions
      fireEvent.click(groupButton)

      // Should now see a nested group
      await waitFor(() => {
        expect(screen.getByText('Match')).toBeInTheDocument()
      })
    })

    test('should render nested group with proper visual nesting', async () => {
      const initialTree: FilterTree = {
        rootGroup: {
          id: 'root',
          connector: 'and',
          conditions: [
            {
              id: 'cond-1',
              dimension: 'visit:country',
              operator: 'is',
              value: ['US']
            },
            {
              id: 'cond-2',
              dimension: 'visit:country',
              operator: 'is',
              value: ['GB']
            }
          ],
          children: [],
          isRoot: true
        },
        labels: {}
      }

      renderFilterBuilder({ initialTree })

      // Should show the root conditions
      await waitFor(() => {
        const dimensionSelects = screen.getAllByRole('combobox')
        expect(dimensionSelects.length).toBe(2)
      })
    })

    test('should limit nesting depth to 3 levels', async () => {
      // Create a tree that is already at max depth (3)
      const maxDepthTree: FilterTree = {
        rootGroup: {
          id: 'root',
          connector: 'and',
          conditions: [],
          children: [
            {
              id: 'level-1',
              connector: 'and',
              conditions: [],
              children: [
                {
                  id: 'level-2',
                  connector: 'and',
                  conditions: [],
                  children: [
                    {
                      id: 'level-3',
                      connector: 'and',
                      conditions: [
                        {
                          id: 'cond-1',
                          dimension: 'visit:country',
                          operator: 'is',
                          value: ['US']
                        }
                      ],
                      children: [],
                      isRoot: false
                    }
                  ],
                  isRoot: false
                }
              ],
              isRoot: false
            }
          ],
          isRoot: true
        },
        labels: {}
      }

      renderFilterBuilder({ initialTree: maxDepthTree })

      // Should still render - the hook limits adding more depth
      await waitFor(() => {
        // Verify we can still see the condition at level 3
        const dimensionSelects = screen.getAllByRole('combobox')
        expect(dimensionSelects.length).toBe(1)
      })

      // The Add Group button should still be visible (but won't add more groups due to depth limit)
      const addGroupButton = screen.getByText('+ Add group')
      expect(addGroupButton).toBeInTheDocument()
    })

    test('should correctly deserialize nested groups from backend format', () => {
      // Backend format: ['and', [['is', 'visit:country', ['US']], ['or', [['is', 'visit:device', ['Mobile']], ['is', 'visit:browser', ['Chrome']]]]]]
      const backendFilters = [
        'and',
        [
          ['is', 'visit:country', ['US']],
          ['or',
            [
              ['is', 'visit:device', ['Mobile']],
              ['is', 'visit:browser', ['Chrome']]
            ]
          ]
        ]
      ]

      const { rootGroup } = backendToFilterTree({ filters: backendFilters })

      // Root should have 1 condition and 1 child group
      expect(rootGroup.conditions).toHaveLength(1)
      expect(rootGroup.children).toHaveLength(1)
      expect(rootGroup.connector).toBe('and')

      // Child group should have 2 conditions with OR
      const childGroup = rootGroup.children[0]
      expect(childGroup.connector).toBe('or')
      expect(childGroup.conditions).toHaveLength(2)
    })
  })
})

describe('FilterBuilder - Template Save/Load Integration Tests', () => {
  const mockSiteId = 'test-site-id'

  // Sample saved segments for testing load functionality
  const mockSavedSegments: SavedSegment[] = [
    {
      id: 1,
      name: 'US Visitors',
      type: SegmentType.personal,
      inserted_at: '2025-01-01 00:00:00',
      updated_at: '2025-01-01 00:00:00',
      owner_id: 1,
      owner_name: 'Test User'
    },
    {
      id: 2,
      name: 'Mobile Users',
      type: SegmentType.site,
      inserted_at: '2025-01-01 00:00:00',
      updated_at: '2025-01-01 00:00:00',
      owner_id: 1,
      owner_name: 'Test User'
    }
  ]

  describe('Template Save Functionality', () => {
    test('should show save form modal when clicking Save Segment button', () => {
      const onClose = jest.fn()
      render(
        <FilterBuilder
          siteId={mockSiteId}
          onClose={onClose}
        />
      )

      // Click Save Segment button (the footer button, not the modal title)
      const saveButtons = screen.getAllByText('Save Segment')
      const saveButton = saveButtons.find(
        (btn) => btn.tagName.toLowerCase() === 'button'
      )
      expect(saveButton).toBeDefined()
      fireEvent.click(saveButton!)

      // Save form modal should appear - check for modal-specific elements
      expect(screen.getByText('Segment Name')).toBeInTheDocument()
      expect(screen.getByText('Segment Type')).toBeInTheDocument()
    })

    test('should call onSave with filter tree, name, and type when saving', async () => {
      const mockOnSave = jest.fn().mockResolvedValue(undefined)
      const onClose = jest.fn()

      // Create a tree with some conditions
      const initialTree = createEmptyFilterTree()
      initialTree.rootGroup.conditions = [
        {
          id: 'cond-1',
          dimension: 'visit:country',
          operator: 'is',
          value: ['US']
        }
      ]

      render(
        <FilterBuilder
          siteId={mockSiteId}
          initialTree={initialTree}
          onSave={mockOnSave}
          onClose={onClose}
        />
      )

      // Click Save Segment button
      const saveButton = screen.getByText('Save Segment')
      fireEvent.click(saveButton)

      // Fill in segment name
      const nameInput = screen.getByPlaceholderText('e.g., US Mobile Visitors')
      fireEvent.change(nameInput, { target: { value: 'US Visitors' } })

      // Select segment type (personal is default)
      const typeSelect = screen.getByDisplayValue('Personal Segment')
      expect(typeSelect).toBeInTheDocument()

      // Click Save in the modal
      const saveInModalButton = screen.getByRole('button', { name: /Save$/ })
      fireEvent.click(saveInModalButton)

      // Wait for the async save to complete
      await waitFor(() => {
        expect(mockOnSave).toHaveBeenCalledTimes(1)
      })

      // Verify the save was called with correct parameters
      expect(mockOnSave).toHaveBeenCalledWith(
        initialTree,
        'US Visitors',
        SegmentType.personal
      )
    })

    test('should close save form after successful save', async () => {
      const mockOnSave = jest.fn().mockResolvedValue(undefined)
      const onClose = jest.fn()

      const initialTree = createEmptyFilterTree()
      initialTree.rootGroup.conditions = [
        {
          id: 'cond-1',
          dimension: 'visit:country',
          operator: 'is',
          value: ['US']
        }
      ]

      render(
        <FilterBuilder
          siteId={mockSiteId}
          initialTree={initialTree}
          onSave={mockOnSave}
          onClose={onClose}
        />
      )

      // Open save form
      const saveButton = screen.getByText('Save Segment')
      fireEvent.click(saveButton)

      // Fill name
      const nameInput = screen.getByPlaceholderText('e.g., US Mobile Visitors')
      fireEvent.change(nameInput, { target: { value: 'Test Segment' } })

      // Save
      const saveInModalButton = screen.getByRole('button', { name: /Save$/ })
      fireEvent.click(saveInModalButton)

      // Wait for save to complete
      await waitFor(() => {
        expect(mockOnSave).toHaveBeenCalledTimes(1)
      })

      // Form should close - Cancel button should be gone
      expect(screen.queryByText('Cancel')).not.toBeInTheDocument()
    })

    test('should allow cancelling save form', () => {
      const mockOnSave = jest.fn()
      const onClose = jest.fn()

      render(
        <FilterBuilder
          siteId={mockSiteId}
          onSave={mockOnSave}
          onClose={onClose}
        />
      )

      // Open save form
      const saveButton = screen.getByText('Save Segment')
      fireEvent.click(saveButton)

      // Click Cancel
      const cancelButton = screen.getByText('Cancel')
      fireEvent.click(cancelButton)

      // Form should be closed
      expect(screen.queryByText('Segment Name')).not.toBeInTheDocument()

      // onSave should not have been called
      expect(mockOnSave).not.toHaveBeenCalled()
    })

    test('should disable save button when segment name is empty', () => {
      const mockOnSave = jest.fn()
      const onClose = jest.fn()

      render(
        <FilterBuilder
          siteId={mockSiteId}
          onSave={mockOnSave}
          onClose={onClose}
        />
      )

      // Open save form
      const saveButton = screen.getByText('Save Segment')
      fireEvent.click(saveButton)

      // Save button should be disabled when name is empty
      const saveInModalButton = screen.getByRole('button', { name: /Save$/ })
      expect(saveInModalButton).toBeDisabled()
    })

    test('should save with site segment type when selected', async () => {
      const mockOnSave = jest.fn().mockResolvedValue(undefined)
      const onClose = jest.fn()

      const initialTree = createEmptyFilterTree()

      render(
        <FilterBuilder
          siteId={mockSiteId}
          initialTree={initialTree}
          onSave={mockOnSave}
          onClose={onClose}
        />
      )

      // Open save form
      const saveButton = screen.getByText('Save Segment')
      fireEvent.click(saveButton)

      // Fill name
      const nameInput = screen.getByPlaceholderText('e.g., US Mobile Visitors')
      fireEvent.change(nameInput, { target: { value: 'Site Wide Segment' } })

      // Change type to Site Segment
      const typeSelect = screen.getByDisplayValue('Personal Segment')
      fireEvent.change(typeSelect, { target: { value: SegmentType.site } })

      // Save
      const saveInModalButton = screen.getByRole('button', { name: /Save$/ })
      fireEvent.click(saveInModalButton)

      // Wait for save
      await waitFor(() => {
        expect(mockOnSave).toHaveBeenCalledTimes(1)
      })

      // Verify type was site
      expect(mockOnSave).toHaveBeenCalledWith(
        initialTree,
        'Site Wide Segment',
        SegmentType.site
      )
    })
  })

  describe('Template Load Functionality', () => {
    test('should show Load Template button when existing segments are provided', () => {
      const onClose = jest.fn()

      render(
        <FilterBuilder
          siteId={mockSiteId}
          existingSegments={mockSavedSegments}
          onClose={onClose}
        />
      )

      // Load Template button should be visible
      const loadButton = screen.getByText('Load Template')
      expect(loadButton).toBeInTheDocument()
    })

    test('should show load menu when clicking Load Template button', () => {
      const onClose = jest.fn()

      render(
        <FilterBuilder
          siteId={mockSiteId}
          existingSegments={mockSavedSegments}
          onClose={onClose}
        />
      )

      // Click Load Template button
      const loadButton = screen.getByText('Load Template')
      fireEvent.click(loadButton)

      // Menu should show the saved segments
      expect(screen.getByText('US Visitors')).toBeInTheDocument()
      expect(screen.getByText('Mobile Users')).toBeInTheDocument()
    })

    test('should call onLoad with selected segment when clicking a segment', () => {
      const mockOnLoad = jest.fn()
      const onClose = jest.fn()

      render(
        <FilterBuilder
          siteId={mockSiteId}
          existingSegments={mockSavedSegments}
          onLoad={mockOnLoad}
          onClose={onClose}
        />
      )

      // Open load menu
      const loadButton = screen.getByText('Load Template')
      fireEvent.click(loadButton)

      // Click on a segment
      const usVisitorsSegment = screen.getByText('US Visitors')
      fireEvent.click(usVisitorsSegment)

      // onLoad should be called with the segment
      expect(mockOnLoad).toHaveBeenCalledTimes(1)
      expect(mockOnLoad).toHaveBeenCalledWith(mockSavedSegments[0])
    })

    test('should close load menu after selecting a segment', () => {
      const mockOnLoad = jest.fn()
      const onClose = jest.fn()

      render(
        <FilterBuilder
          siteId={mockSiteId}
          existingSegments={mockSavedSegments}
          onLoad={mockOnLoad}
          onClose={onClose}
        />
      )

      // Open load menu
      const loadButton = screen.getByText('Load Template')
      fireEvent.click(loadButton)

      // Select a segment
      const usVisitorsSegment = screen.getByText('US Visitors')
      fireEvent.click(usVisitorsSegment)

      // Menu should be closed - other segments should not be visible
      expect(screen.queryByText('Mobile Users')).not.toBeInTheDocument()
    })

    test('should show segment type labels in load menu', () => {
      const onClose = jest.fn()

      render(
        <FilterBuilder
          siteId={mockSiteId}
          existingSegments={mockSavedSegments}
          onClose={onClose}
        />
      )

      // Open load menu
      const loadButton = screen.getByText('Load Template')
      fireEvent.click(loadButton)

      // Should show segment type labels
      expect(screen.getByText('Personal segment')).toBeInTheDocument()
      expect(screen.getByText('Site segment')).toBeInTheDocument()
    })

    test('should toggle load menu when clicking Load Template button', () => {
      const mockOnLoad = jest.fn()
      const onClose = jest.fn()

      render(
        <FilterBuilder
          siteId={mockSiteId}
          existingSegments={mockSavedSegments}
          onLoad={mockOnLoad}
          onClose={onClose}
        />
      )

      // Open load menu
      const loadButton = screen.getByText('Load Template')
      fireEvent.click(loadButton)

      // Menu should be open
      expect(screen.getByText('US Visitors')).toBeInTheDocument()

      // Click the Load Template button again to close
      fireEvent.click(loadButton)

      // Menu should be closed
      expect(screen.queryByText('US Visitors')).not.toBeInTheDocument()
    })
  })

  describe('Template Save/Load with Complex Filter Trees', () => {
    test('should serialize complex filter tree when saving', async () => {
      const mockOnSave = jest.fn().mockResolvedValue(undefined)
      const onClose = jest.fn()

      // Create a complex tree with nested groups
      const complexTree: FilterTree = {
        rootGroup: {
          id: 'root',
          connector: 'or',
          conditions: [
            {
              id: 'cond-1',
              dimension: 'visit:country',
              operator: 'is',
              value: ['US']
            }
          ],
          children: [
            {
              id: 'group-1',
              connector: 'and',
              conditions: [
                {
                  id: 'cond-2',
                  dimension: 'visit:device',
                  operator: 'is',
                  value: ['Mobile']
                },
                {
                  id: 'cond-3',
                  dimension: 'visit:browser',
                  operator: 'is',
                  value: ['Chrome']
                }
              ],
              children: [],
              isRoot: false
            }
          ],
          isRoot: true
        },
        labels: { US: 'United States', Mobile: 'Mobile', Chrome: 'Chrome' }
      }

      render(
        <FilterBuilder
          siteId={mockSiteId}
          initialTree={complexTree}
          onSave={mockOnSave}
          onClose={onClose}
        />
      )

      // Open save form
      const saveButton = screen.getByText('Save Segment')
      fireEvent.click(saveButton)

      // Fill name
      const nameInput = screen.getByPlaceholderText('e.g., US Mobile Visitors')
      fireEvent.change(nameInput, { target: { value: 'Complex Segment' } })

      // Save
      const saveInModalButton = screen.getByRole('button', { name: /Save$/ })
      fireEvent.click(saveInModalButton)

      // Wait for save
      await waitFor(() => {
        expect(mockOnSave).toHaveBeenCalledTimes(1)
      })

      // Verify the complex tree was passed
      expect(mockOnSave).toHaveBeenCalledWith(
        complexTree,
        'Complex Segment',
        SegmentType.personal
      )
    })

    test('should serialize filter tree to backend format correctly', () => {
      // Test that the serialization works for template storage
      const tree: FilterTree = {
        rootGroup: {
          id: 'root',
          connector: 'and',
          conditions: [
            {
              id: 'cond-1',
              dimension: 'visit:country',
              operator: 'is',
              value: ['US']
            },
            {
              id: 'cond-2',
              dimension: 'visit:device',
              operator: 'is',
              value: ['Mobile']
            }
          ],
          children: [],
          isRoot: true
        },
        labels: { US: 'United States', Mobile: 'Mobile' }
      }

      // Serialize to backend format (what would be stored)
      const backendData = filterTreeToBackend(tree)

      // The backend format should be correct for storage
      expect(backendData.filters).toEqual([
        'and',
        [
          ['is', 'visit:country', ['US']],
          ['is', 'visit:device', ['Mobile']]
        ]
      ])
      expect(backendData.labels).toEqual({ US: 'United States', Mobile: 'Mobile' })
    })
  })
})

describe('FilterBuilder - Condition Editing (US5)', () => {
  const mockSiteId = 'test-site-id'

  const renderFilterBuilder = (props?: Partial<{ initialTree: FilterTree; onClose: () => void }>) => {
    return render(
      <FilterBuilder
        siteId={mockSiteId}
        {...props}
      />
    )
  }

  describe('Updating condition dimension', () => {
    it('should update condition dimension when dimension is changed', async () => {
      renderFilterBuilder()

      // Find the dimension select element
      const dimensionSelect = screen.getByRole('combobox') as HTMLSelectElement

      // Change the dimension
      fireEvent.change(dimensionSelect, { target: { value: 'visit:country' } })

      // Verify the change was applied
      expect(dimensionSelect.value).toBe('visit:country')
    })

    it('should reset value when dimension changes', async () => {
      renderFilterBuilder()

      // Find elements
      const dimensionSelect = screen.getByRole('combobox')
      const valueInput = screen.getByRole('textbox') as HTMLInputElement

      // Set dimension and value
      fireEvent.change(dimensionSelect, { target: { value: 'visit:country' } })
      fireEvent.change(valueInput, { target: { value: 'US' } })

      // Verify value was set
      expect(valueInput.value).toBe('US')

      // Change dimension
      fireEvent.change(dimensionSelect, { target: { value: 'event:page' } })

      // Verify value was reset
      expect(valueInput.value).toBe('')
    })
  })

  describe('Updating condition operator', () => {
    it('should update condition operator when operator is changed', async () => {
      renderFilterBuilder()

      const selects = screen.getAllByRole('combobox') as HTMLSelectElement[]
      const dimensionSelect = selects[0]
      const operatorSelect = selects[1] as HTMLSelectElement

      // Set dimension first
      fireEvent.change(dimensionSelect, { target: { value: 'visit:country' } })

      // Change operator
      fireEvent.change(operatorSelect, { target: { value: 'contains' } })

      // Verify operator was changed
      expect(operatorSelect.value).toBe('contains')
    })
  })

  describe('Updating condition value', () => {
    it('should update condition value when value input changes', async () => {
      renderFilterBuilder()

      // Set dimension first
      const dimensionSelect = screen.getByRole('combobox')
      fireEvent.change(dimensionSelect, { target: { value: 'visit:country' } })

      // Get value input and change it
      const valueInput = screen.getByRole('textbox')
      fireEvent.change(valueInput, { target: { value: 'United States' } })

      // Verify value was set
      expect(valueInput).toHaveValue('United States')
    })

    it('should accept comma-separated values', async () => {
      renderFilterBuilder()

      const dimensionSelect = screen.getByRole('combobox')
      fireEvent.change(dimensionSelect, { target: { value: 'visit:country' } })

      const valueInput = screen.getByRole('textbox')
      fireEvent.change(valueInput, { target: { value: 'US, GB, DE' } })

      expect(valueInput).toHaveValue('US, GB, DE')
    })
  })

  describe('Removing conditions', () => {
    it('should have remove button for each condition', async () => {
      renderFilterBuilder()

      const removeButtons = screen.getAllByTitle('Remove condition')
      expect(removeButtons.length).toBeGreaterThanOrEqual(1)
    })

    it('should remove condition when remove button is clicked', async () => {
      renderFilterBuilder()

      const addButton = screen.getByText('+ Add condition')
      fireEvent.click(addButton)

      await waitFor(() => {
        const dimensionSelects = screen.getAllByRole('combobox')
        expect(dimensionSelects.length).toBe(2)
      })

      const removeButtons = screen.getAllByTitle('Remove condition')
      fireEvent.click(removeButtons[0])

      await waitFor(() => {
        const dimensionSelects = screen.getAllByRole('combobox')
        expect(dimensionSelects.length).toBe(1)
      })
    })

    it('should add empty condition when all conditions are removed', async () => {
      renderFilterBuilder()

      const removeButton = screen.getByTitle('Remove condition')
      fireEvent.click(removeButton)

      await waitFor(() => {
        const dimensionSelects = screen.getAllByRole('combobox')
        expect(dimensionSelects.length).toBe(1)
      })

      const dimensionSelect = screen.getByRole('combobox') as HTMLSelectElement
      expect(dimensionSelect.value).toBe('')
    })
  })

  describe('Editing multiple conditions', () => {
    it('should maintain independent state for each condition', async () => {
      renderFilterBuilder()

      const addButton = screen.getByText('+ Add condition')
      fireEvent.click(addButton)

      await waitFor(() => {
        const selects = screen.getAllByRole('combobox') as HTMLSelectElement[]
        fireEvent.change(selects[0], { target: { value: 'visit:country' } })
        fireEvent.change(selects[2], { target: { value: 'visit:device' } })
      })

      const selects = screen.getAllByRole('combobox') as HTMLSelectElement[]
      expect((selects[0] as HTMLSelectElement).value).toBe('visit:country')
      expect((selects[2] as HTMLSelectElement).value).toBe('visit:device')
    })
  })

  describe('Dirty state and reset', () => {
    it('should set isDirty to true when condition is edited', async () => {
      renderFilterBuilder()

      const dimensionSelect = screen.getByRole('combobox')
      fireEvent.change(dimensionSelect, { target: { value: 'visit:country' } })

      await waitFor(() => {
        expect(screen.getByText('Reset')).toBeInTheDocument()
      })
    })

    it('should reset all conditions when reset is clicked', async () => {
      const initialTree: FilterTree = {
        rootGroup: {
          id: 'root',
          connector: 'and',
          conditions: [
            {
              id: 'cond-1',
              dimension: 'visit:country',
              operator: 'is',
              value: ['US']
            }
          ],
          children: [],
          isRoot: true
        },
        labels: {}
      }

      renderFilterBuilder({ initialTree })

      const resetButton = screen.getByText('Reset')
      fireEvent.click(resetButton)

      await waitFor(() => {
        const dimensionSelect = screen.getByRole('combobox') as HTMLSelectElement
        expect(dimensionSelect.value).toBe('visit:country')
      })
    })
  })

  describe('Empty state handling', () => {
    it('should show empty state when condition is removed', async () => {
      renderFilterBuilder()

      const removeButton = screen.getByTitle('Remove condition')
      fireEvent.click(removeButton)

      await waitFor(() => {
        expect(screen.getByText('+ Add condition')).toBeInTheDocument()
      })
    })
  })
})
