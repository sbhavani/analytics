import React from 'react'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import '@testing-library/jest-dom'
import { FilterBuilder } from './filter-builder'
import {
  FilterExpression,
  createEmptyFilterExpression,
  createFilterCondition,
  createFilterGroup,
  FilterCondition
} from '../../types/filter-expression'
import { validateFilterExpression, countConditions, getNestingDepth } from '../../util/filter-expression'

// Mock the FilterBuilder component for testing
describe('FilterExpression', () => {
  describe('validateFilterExpression', () => {
    it('should validate an empty expression as invalid', () => {
      const expression = createEmptyFilterExpression()
      const result = validateFilterExpression(expression)
      expect(result.valid).toBe(false)
      expect(result.errors).toContain('Filter must have at least one condition')
    })

    it('should validate a single condition as valid', () => {
      const expression: FilterExpression = {
        version: 1,
        root: {
          id: '1',
          operator: 'AND',
          children: [createFilterCondition('country', 'is')]
        }
      }
      const result = validateFilterExpression(expression)
      expect(result.valid).toBe(true)
      expect(result.errors).toHaveLength(0)
    })

    it('should validate multiple conditions as valid', () => {
      const expression: FilterExpression = {
        version: 1,
        root: {
          id: '1',
          operator: 'AND',
          children: [
            createFilterCondition('country', 'is'),
            createFilterCondition('device', 'is')
          ]
        }
      }
      const result = validateFilterExpression(expression)
      expect(result.valid).toBe(true)
    })

    it('should reject more than 20 conditions', () => {
      const expression: FilterExpression = {
        version: 1,
        root: {
          id: '1',
          operator: 'AND',
          children: Array.from({ length: 21 }, (_, i) =>
            createFilterCondition('country', 'is')
          )
        }
      }
      const result = validateFilterExpression(expression)
      expect(result.valid).toBe(false)
      expect(result.errors).toContain('Filter cannot have more than 20 conditions')
    })

    it('should reject nesting deeper than 5 levels', () => {
      // Create a deeply nested expression
      let expression: FilterExpression = {
        version: 1,
        root: {
          id: '1',
          operator: 'AND',
          children: []
        }
      }

      // Nest 6 levels deep
      let currentGroup = expression.root
      for (let i = 0; i < 6; i++) {
        const newGroup = createFilterGroup('AND')
        newGroup.children.push(currentGroup)
        currentGroup = newGroup
      }
      expression.root = currentGroup

      const result = validateFilterExpression(expression)
      expect(result.valid).toBe(false)
      expect(result.errors).toContain('Filter cannot nest more than 5 levels')
    })
  })

  describe('countConditions', () => {
    it('should count conditions in a flat group', () => {
      const expression: FilterExpression = {
        version: 1,
        root: {
          id: '1',
          operator: 'AND',
          children: [
            createFilterCondition('country', 'is'),
            createFilterCondition('device', 'is'),
            createFilterCondition('browser', 'is')
          ]
        }
      }
      expect(countConditions(expression)).toBe(3)
    })

    it('should count conditions in nested groups', () => {
      const expression: FilterExpression = {
        version: 1,
        root: {
          id: '1',
          operator: 'OR',
          children: [
            createFilterCondition('country', 'is'),
            {
              id: '2',
              operator: 'AND',
              children: [
                createFilterCondition('device', 'is'),
                createFilterCondition('browser', 'is')
              ]
            }
          ]
        }
      }
      expect(countConditions(expression)).toBe(3)
    })
  })

  describe('getNestingDepth', () => {
    it('should return 1 for a flat group', () => {
      const expression: FilterExpression = {
        version: 1,
        root: {
          id: '1',
          operator: 'AND',
          children: [createFilterCondition('country', 'is')]
        }
      }
      expect(getNestingDepth(expression)).toBe(1)
    })

    it('should return correct depth for nested groups', () => {
      const expression: FilterExpression = {
        version: 1,
        root: {
          id: '1',
          operator: 'AND',
          children: [
            createFilterCondition('country', 'is'),
            {
              id: '2',
              operator: 'OR',
              children: [
                createFilterCondition('device', 'is'),
                {
                  id: '3',
                  operator: 'AND',
                  children: [createFilterCondition('browser', 'is')]
                }
              ]
            }
          ]
        }
      }
      expect(getNestingDepth(expression)).toBe(3)
    })
  })
})

describe('FilterBuilder UI', () => {
  const mockOnApply = jest.fn()
  const mockOnSaveSegment = jest.fn()

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders the filter builder with initial empty state', () => {
    render(
      <FilterBuilder
        siteId={1}
        onApply={mockOnApply}
        onSaveSegment={mockOnSaveSegment}
      />
    )

    expect(screen.getByText('Filter Builder')).toBeInTheDocument()
    expect(screen.getByText('No conditions yet')).toBeInTheDocument()
  })

  it('adds a new condition when clicking add condition button', () => {
    render(
      <FilterBuilder
        siteId={1}
        onApply={mockOnApply}
        onSaveSegment={mockOnSaveSegment}
      />
    )

    const addButton = screen.getByText('Add condition')
    fireEvent.click(addButton)

    expect(screen.getByText('Country')).toBeInTheDocument()
  })

  it('shows validation error when trying to apply empty filter', () => {
    render(
      <FilterBuilder
        siteId={1}
        onApply={mockOnApply}
        onSaveSegment={mockOnSaveSegment}
      />
    )

    const applyButton = screen.getByText('Apply Filter')
    expect(applyButton).toBeDisabled()
  })

  it('enables apply button when there is at least one condition', () => {
    render(
      <FilterBuilder
        siteId={1}
        onApply={mockOnApply}
        onSaveSegment={mockOnSaveSegment}
      />
    )

    // Add a condition
    const addButton = screen.getByText('Add condition')
    fireEvent.click(addButton)

    // The Apply Filter button should now be enabled
    const applyButton = screen.getByText('Apply Filter')
    expect(applyButton).not.toBeDisabled()
  })

  it('calls onApply when apply button is clicked', () => {
    render(
      <FilterBuilder
        siteId={1}
        onApply={mockOnApply}
        onSaveSegment={mockOnSaveSegment}
      />
    )

    // Add a condition
    const addButton = screen.getByText('Add condition')
    fireEvent.click(addButton)

    // Click apply
    const applyButton = screen.getByText('Apply Filter')
    fireEvent.click(applyButton)

    expect(mockOnApply).toHaveBeenCalled()
  })

  it('opens save segment dialog when save button is clicked', () => {
    render(
      <FilterBuilder
        siteId={1}
        onApply={mockOnApply}
        onSaveSegment={mockOnSaveSegment}
      />
    )

    // Add a condition first to enable the button
    const addButton = screen.getByText('Add condition')
    fireEvent.click(addButton)

    // Click save
    const saveButton = screen.getByText('Save as Segment')
    fireEvent.click(saveButton)

    expect(screen.getByText('Save Segment')).toBeInTheDocument()
  })

  it('shows validation errors for missing values', () => {
    const expression: FilterExpression = {
      version: 1,
      root: {
        id: '1',
        operator: 'AND',
        children: [
          {
            id: '1',
            dimension: 'country',
            operator: 'is',
            value: null as any // Invalid - no value
          }
        ]
      }
    }

    render(
      <FilterBuilder
        siteId={1}
        initialExpression={expression}
        onApply={mockOnApply}
        onSaveSegment={mockOnSaveSegment}
      />
    )

    expect(screen.getByText(/has no value/)).toBeInTheDocument()
  })
})
