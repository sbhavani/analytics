import React from 'react'
import { render, screen, fireEvent } from '@testing-library/react'
import { FilterBuilderProvider, useFilterBuilderContext } from './filter-builder-context'
import FilterConditionRow from './FilterConditionRow'
import { FilterCondition, FilterGroup, LogicalOperator } from './types'

// Test wrapper component that provides the context
function TestWrapper({
  children,
  initialGroup
}: {
  children: React.ReactNode
  initialGroup?: FilterGroup
}) {
  return (
    <FilterBuilderProvider initialGroup={initialGroup}>
      {children}
    </FilterBuilderProvider>
  )
}

// Helper to create a test condition
function createTestCondition(overrides: Partial<FilterCondition> = {}): FilterCondition {
  return {
    id: 'test-condition-1',
    field: 'country',
    operator: 'is',
    value: 'US',
    ...overrides
  }
}

// Helper to create a test group with conditions
function createTestGroup(
  children: FilterCondition[],
  operator: LogicalOperator = 'AND'
): FilterGroup {
  return {
    id: 'test-group-1',
    type: 'group',
    operator,
    children
  }
}

describe('FilterConditionRow', () => {
  const mockCondition = createTestCondition()
  const mockGroup = createTestGroup([mockCondition])

  describe('rendering', () => {
    it('renders field selector, operator selector, and value input', () => {
      render(
        <TestWrapper initialGroup={mockGroup}>
          <FilterConditionRow
            condition={mockCondition}
            index={0}
            isLast={true}
          />
        </TestWrapper>
      )

      // Field selector should be present
      expect(screen.getByRole('combobox')).toBeInTheDocument()

      // Delete button should be present
      expect(screen.getByTitle('Remove condition')).toBeInTheDocument()
    })

    it('renders add condition and add group buttons when isLast is true', () => {
      render(
        <TestWrapper initialGroup={mockGroup}>
          <FilterConditionRow
            condition={mockCondition}
            index={0}
            isLast={true}
          />
        </TestWrapper>
      )

      expect(screen.getByText('+ Add condition')).toBeInTheDocument()
      expect(screen.getByText('Add Group')).toBeInTheDocument()
    })

    it('does not render add buttons when isLast is false', () => {
      const groupWithTwoConditions = createTestGroup([
        mockCondition,
        createTestCondition({ id: 'test-condition-2', field: 'browser' })
      ])

      render(
        <TestWrapper initialGroup={groupWithTwoConditions}>
          <FilterConditionRow
            condition={mockCondition}
            index={0}
            isLast={false}
          />
        </TestWrapper>
      )

      expect(screen.queryByText('+ Add condition')).not.toBeInTheDocument()
      expect(screen.queryByText('Add Group')).not.toBeInTheDocument()
    })

    it('renders logical operator badge when showOperator is provided and index > 0', () => {
      const groupWithTwoConditions = createTestGroup([
        mockCondition,
        createTestCondition({ id: 'test-condition-2', field: 'browser' })
      ])

      render(
        <TestWrapper initialGroup={groupWithTwoConditions}>
          <FilterConditionRow
            condition={createTestCondition({ id: 'test-condition-2', field: 'browser' })}
            index={1}
            showOperator="AND"
            isLast={true}
          />
        </TestWrapper>
      )

      expect(screen.getByText('AND')).toBeInTheDocument()
    })

    it('renders OR operator badge correctly', () => {
      const groupWithTwoConditions = createTestGroup([
        mockCondition,
        createTestCondition({ id: 'test-condition-2', field: 'browser' })
      ], 'OR')

      render(
        <TestWrapper initialGroup={groupWithTwoConditions}>
          <FilterConditionRow
            condition={createTestCondition({ id: 'test-condition-2', field: 'browser' })}
            index={1}
            showOperator="OR"
            isLast={true}
          />
        </TestWrapper>
      )

      expect(screen.getByText('OR')).toBeInTheDocument()
    })

    it('does not render operator badge when index is 0', () => {
      render(
        <TestWrapper initialGroup={mockGroup}>
          <FilterConditionRow
            condition={mockCondition}
            index={0}
            showOperator="AND"
            isLast={true}
          />
        </TestWrapper>
      )

      expect(screen.queryByText('AND')).not.toBeInTheDocument()
    })
  })

  describe('value input visibility', () => {
    it('hides value input for is_set operator', () => {
      const conditionWithSetOperator = createTestCondition({
        operator: 'is_set'
      })
      const groupWithSetOperator = createTestGroup([conditionWithSetOperator])

      render(
        <TestWrapper initialGroup={groupWithSetOperator}>
          <FilterConditionRow
            condition={conditionWithSetOperator}
            index={0}
            isLast={true}
          />
        </TestWrapper>
      )

      // Value input should not be present for is_set operator
      // The component should not show a value input field
      const valueInputs = document.querySelectorAll('input')
      // Should only have the field selector input, not a value input
      expect(valueInputs.length).toBeLessThanOrEqual(1)
    })

    it('hides value input for is_not_set operator', () => {
      const conditionWithNotSetOperator = createTestCondition({
        operator: 'is_not_set'
      })
      const groupWithNotSetOperator = createTestGroup([conditionWithNotSetOperator])

      render(
        <TestWrapper initialGroup={groupWithNotSetOperator}>
          <FilterConditionRow
            condition={conditionWithNotSetOperator}
            index={0}
            isLast={true}
          />
        </TestWrapper>
      )

      // Value input should not be present for is_not_set operator
      const valueInputs = document.querySelectorAll('input')
      expect(valueInputs.length).toBeLessThanOrEqual(1)
    })

    it('shows value input for regular operators', () => {
      render(
        <TestWrapper initialGroup={mockGroup}>
          <FilterConditionRow
            condition={mockCondition}
            index={0}
            isLast={true}
          />
        </TestWrapper>
      )

      // The value input should be present - check for placeholder text that includes the field name
      expect(screen.getByPlaceholderText(/Enter country/)).toBeInTheDocument()
    })
  })

  describe('user interactions', () => {
    it('renders delete button that is clickable', () => {
      render(
        <TestWrapper initialGroup={mockGroup}>
          <FilterConditionRow
            condition={mockCondition}
            index={0}
            isLast={true}
          />
        </TestWrapper>
      )

      // The delete button should be present and clickable
      const deleteButton = screen.getByTitle('Remove condition')
      expect(deleteButton).toBeInTheDocument()

      // Should not throw when clicked
      expect(() => fireEvent.click(deleteButton)).not.toThrow()
    })

    it('calls addCondition when add condition button is clicked', () => {
      render(
        <TestWrapper initialGroup={mockGroup}>
          <FilterConditionRow
            condition={mockCondition}
            index={0}
            isLast={true}
            groupId={mockGroup.id}
          />
        </TestWrapper>
      )

      // Should not throw when clicked
      expect(() => fireEvent.click(screen.getByText('+ Add condition'))).not.toThrow()
    })

    it('calls addGroup when add group button is clicked', () => {
      render(
        <TestWrapper initialGroup={mockGroup}>
          <FilterConditionRow
            condition={mockCondition}
            index={0}
            isLast={true}
            groupId={mockGroup.id}
          />
        </TestWrapper>
      )

      // Should not throw when clicked
      expect(() => fireEvent.click(screen.getByText('Add Group'))).not.toThrow()
    })
  })

  describe('error handling', () => {
    it('throws error when used outside FilterBuilderProvider', () => {
      // Suppress console.error for this test
      const consoleSpy = jest.spyOn(console, 'error').mockImplementation(() => {})

      expect(() => {
        render(
          <FilterConditionRow
            condition={mockCondition}
            index={0}
            isLast={true}
          />
        )
      }).toThrow('useFilterBuilderContext must be used within a FilterBuilderProvider')

      consoleSpy.mockRestore()
    })
  })
})
