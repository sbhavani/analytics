import React from 'react'
import { render, screen, fireEvent } from '@testing-library/react'
import { FilterGroup, FilterGroupData } from './FilterGroup'
import { FilterField, FilterConditionData } from './FilterCondition'

const mockAvailableFields: FilterField[] = [
  { name: 'country', displayName: 'Country', dataType: 'string', operators: ['is', 'is_not'], options: ['US', 'GB', 'DE'] },
  { name: 'pages', displayName: 'Pages', dataType: 'number', operators: ['greater_than', 'less_than'] },
  { name: 'browser', displayName: 'Browser', dataType: 'string', operators: ['is', 'is_not'], options: ['Chrome', 'Firefox', 'Safari'] }
]

const createMockCondition = (id: string): FilterConditionData => ({
  id,
  field: 'country',
  operator: 'is',
  value: 'US'
})

const createMockGroup = (
  id: string,
  operator: 'AND' | 'OR' = 'AND',
  conditions: FilterConditionData[] = [],
  groups: FilterGroupData[] = []
): FilterGroupData => ({
  id,
  operator,
  conditions,
  groups
})

describe('FilterGroup', () => {
  const defaultProps = {
    group: createMockGroup('root-group', 'AND', [createMockCondition('cond-1')]),
    level: 0,
    availableFields: mockAvailableFields,
    onAddCondition: jest.fn(),
    onRemoveCondition: jest.fn(),
    onUpdateCondition: jest.fn(),
    onChangeOperator: jest.fn(),
    onAddGroup: jest.fn(),
    onRemoveGroup: jest.fn()
  }

  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('Basic rendering', () => {
    test('renders FilterGroup component at root level', () => {
      render(<FilterGroup {...defaultProps} />)
      expect(screen.getByRole('group', { name: 'Filter group level 1' })).toBeInTheDocument()
      expect(screen.getByText('Filter conditions')).toBeInTheDocument()
    })

    test('renders conditions within the group', () => {
      const group = createMockGroup('root-group', 'AND', [
        createMockCondition('cond-1'),
        createMockCondition('cond-2')
      ])
      render(<FilterGroup {...defaultProps} group={group} />)

      // Find filter conditions by their container role and aria-label
      const conditions = screen.getAllByRole('group', { name: 'Filter condition' })
      expect(conditions).toHaveLength(2)
    })

    test('displays AND/OR toggle when there are multiple conditions', () => {
      const group = createMockGroup('root-group', 'AND', [
        createMockCondition('cond-1'),
        createMockCondition('cond-2')
      ])
      render(<FilterGroup {...defaultProps} group={group} />)

      // Find buttons inside the operator toggle group
      const operatorButtons = screen.getByRole('group', { name: 'Operator toggle' })
      const buttons = operatorButtons.querySelectorAll('button')
      expect(buttons).toHaveLength(2)
      expect(buttons[0]).toHaveTextContent('AND')
      expect(buttons[1]).toHaveTextContent('OR')
    })

    test('calls onChangeOperator when clicking AND button', () => {
      const onChangeOperator = jest.fn()
      const group = createMockGroup('root-group', 'AND', [
        createMockCondition('cond-1'),
        createMockCondition('cond-2')
      ])
      render(<FilterGroup {...defaultProps} group={group} onChangeOperator={onChangeOperator} />)

      // Find the AND button within the operator toggle group
      const operatorButtons = screen.getByRole('group', { name: 'Operator toggle' })
      const buttons = operatorButtons.querySelectorAll('button')
      fireEvent.click(buttons[0])
      expect(onChangeOperator).toHaveBeenCalledWith('OR')
    })

    test('calls onChangeOperator when clicking OR button', () => {
      const onChangeOperator = jest.fn()
      const group = createMockGroup('root-group', 'OR', [
        createMockCondition('cond-1'),
        createMockCondition('cond-2')
      ])
      render(<FilterGroup {...defaultProps} group={group} onChangeOperator={onChangeOperator} />)

      // Find the OR button within the operator toggle group
      const operatorButtons = screen.getByRole('group', { name: 'Operator toggle' })
      const buttons = operatorButtons.querySelectorAll('button')
      fireEvent.click(buttons[1])
      expect(onChangeOperator).toHaveBeenCalledWith('AND')
    })
  })

  describe('Nested FilterGroup rendering', () => {
    test('renders nested FilterGroup at level 1', () => {
      const nestedGroup = createMockGroup('nested-1', 'OR', [createMockCondition('cond-nested-1')])
      const rootGroup = createMockGroup('root-group', 'AND', [createMockCondition('cond-1')], [nestedGroup])

      render(<FilterGroup {...defaultProps} group={rootGroup} level={0} />)

      expect(screen.getByText('Group 2')).toBeInTheDocument()
      // Check nested group rendered with conditions
      const nestedConditions = screen.getAllByRole('group', { name: 'Filter condition' })
      expect(nestedConditions.length).toBeGreaterThan(0)
    })

    test('renders nested FilterGroup at level 2 (three levels total)', () => {
      const deepNestedGroup = createMockGroup('deep-nested', 'AND', [createMockCondition('cond-deep')])
      const nestedGroup = createMockGroup('nested-1', 'OR', [createMockCondition('cond-nested-1')], [deepNestedGroup])
      const rootGroup = createMockGroup('root-group', 'AND', [createMockCondition('cond-1')], [nestedGroup])

      render(<FilterGroup {...defaultProps} group={rootGroup} level={0} />)

      expect(screen.getByText('Group 2')).toBeInTheDocument()
      expect(screen.getByText('Group 3')).toBeInTheDocument()
      // Check all filter conditions rendered
      const allConditions = screen.getAllByRole('group', { name: 'Filter condition' })
      expect(allConditions.length).toBe(3)
    })

    test('applies proper indentation for nested groups', () => {
      const nestedGroup = createMockGroup('nested-1', 'OR', [createMockCondition('cond-nested-1')])
      const rootGroup = createMockGroup('root-group', 'AND', [createMockCondition('cond-1')], [nestedGroup])

      render(<FilterGroup {...defaultProps} group={rootGroup} level={0} />)

      const nestedGroupElement = screen.getByRole('group', { name: 'Filter group level 2' })
      expect(nestedGroupElement).toHaveClass('ml-6', 'border-l-4')
    })

    test('shows expand/collapse button for nested groups', () => {
      const nestedGroup = createMockGroup('nested-1', 'OR', [createMockCondition('cond-nested-1')])
      const rootGroup = createMockGroup('root-group', 'AND', [createMockCondition('cond-1')], [nestedGroup])

      render(<FilterGroup {...defaultProps} group={rootGroup} level={0} />)

      const collapseButton = screen.getByLabelText('Collapse group')
      expect(collapseButton).toBeInTheDocument()
    })

    test('collapses nested group when collapse button is clicked', () => {
      const nestedGroup = createMockGroup('nested-1', 'OR', [createMockCondition('cond-nested-1')])
      const rootGroup = createMockGroup('root-group', 'AND', [createMockCondition('cond-1')], [nestedGroup])

      render(<FilterGroup {...defaultProps} group={rootGroup} level={0} />)

      // Verify nested group is visible
      const nestedConditionsBefore = screen.getAllByRole('group', { name: 'Filter condition' })
      expect(nestedConditionsBefore.length).toBe(2)

      const collapseButton = screen.getByLabelText('Collapse group')
      fireEvent.click(collapseButton)

      // After collapse, only root level conditions should be visible
      const nestedConditionsAfter = screen.getAllByRole('group', { name: 'Filter condition' })
      expect(nestedConditionsAfter.length).toBe(1)
    })

    test('expands nested group when expand button is clicked after collapse', () => {
      const nestedGroup = createMockGroup('nested-1', 'OR', [createMockCondition('cond-nested-1')])
      const rootGroup = createMockGroup('root-group', 'AND', [createMockCondition('cond-1')], [nestedGroup])

      render(<FilterGroup {...defaultProps} group={rootGroup} level={0} />)

      // First collapse
      const collapseButton = screen.getByLabelText('Collapse group')
      fireEvent.click(collapseButton)
      const nestedConditionsAfterCollapse = screen.getAllByRole('group', { name: 'Filter condition' })
      expect(nestedConditionsAfterCollapse.length).toBe(1)

      // Then expand
      const expandButton = screen.getByLabelText('Expand group')
      fireEvent.click(expandButton)
      const nestedConditionsAfterExpand = screen.getAllByRole('group', { name: 'Filter condition' })
      expect(nestedConditionsAfterExpand.length).toBe(2)
    })

    test('does not show add group button when at max nesting level (level 3)', () => {
      const nestedGroup = createMockGroup('nested-1', 'OR', [createMockCondition('cond-nested-1')])

      // Render the nested group at level 3 (which is the max level - cannot nest further)
      render(
        <FilterGroup
          {...defaultProps}
          group={nestedGroup}
          level={3}
        />
      )

      expect(screen.queryByRole('button', { name: 'Add nested group' })).not.toBeInTheDocument()
    })

    test('shows add group button when not at max nesting level', () => {
      const group = createMockGroup('root-group', 'AND', [createMockCondition('cond-1')])

      // Render at level 0 (root), should allow adding groups
      render(<FilterGroup {...defaultProps} group={group} level={0} />)

      // At level 0, there should be at least one Add group button
      const addGroupButtons = screen.getAllByRole('button', { name: 'Add nested group' })
      expect(addGroupButtons.length).toBeGreaterThanOrEqual(1)
    })

    test('shows remove group button for nested groups', () => {
      const nestedGroup = createMockGroup('nested-1', 'OR', [createMockCondition('cond-nested-1')])
      const rootGroup = createMockGroup('root-group', 'AND', [createMockCondition('cond-1')], [nestedGroup])

      render(<FilterGroup {...defaultProps} group={rootGroup} level={0} />)

      // The remove button should be in the nested group
      const removeButtons = screen.getAllByLabelText('Remove group')
      expect(removeButtons.length).toBeGreaterThan(0)
    })

    test('does not show remove group button at root level', () => {
      const group = createMockGroup('root-group', 'AND', [createMockCondition('cond-1')])

      render(<FilterGroup {...defaultProps} group={group} level={0} />)

      expect(screen.queryByLabelText('Remove group')).not.toBeInTheDocument()
    })

    test('renders multiple nested groups at same level', () => {
      const nestedGroup1 = createMockGroup('nested-1', 'OR', [createMockCondition('cond-nested-1')])
      const nestedGroup2 = createMockGroup('nested-2', 'AND', [createMockCondition('cond-nested-2')])
      const rootGroup = createMockGroup(
        'root-group',
        'AND',
        [createMockCondition('cond-1')],
        [nestedGroup1, nestedGroup2]
      )

      render(<FilterGroup {...defaultProps} group={rootGroup} level={0} />)

      // Check all conditions rendered (root + 2 nested)
      const allConditions = screen.getAllByRole('group', { name: 'Filter condition' })
      expect(allConditions.length).toBe(3)
    })

    test('renders mixed conditions and nested groups', () => {
      const nestedGroup = createMockGroup('nested-1', 'OR', [createMockCondition('cond-nested-1')])
      const rootGroup = createMockGroup(
        'root-group',
        'AND',
        [createMockCondition('cond-1'), createMockCondition('cond-2')],
        [nestedGroup]
      )

      render(<FilterGroup {...defaultProps} group={rootGroup} level={0} />)

      // Check all conditions rendered (2 root + 1 nested)
      const allConditions = screen.getAllByRole('group', { name: 'Filter condition' })
      expect(allConditions.length).toBe(3)
    })
  })

  describe('Accessibility', () => {
    test('FilterGroup has correct role and aria-label', () => {
      render(<FilterGroup {...defaultProps} />)

      expect(screen.getByRole('group', { name: 'Filter group level 1' })).toHaveAttribute('aria-label', 'Filter group level 1')
    })

    test('AND/OR toggle has proper aria-label', () => {
      const group = createMockGroup('root-group', 'AND', [
        createMockCondition('cond-1'),
        createMockCondition('cond-2')
      ])
      render(<FilterGroup {...defaultProps} group={group} />)

      expect(screen.getByLabelText('Operator toggle')).toBeInTheDocument()
    })

    test('expand/collapse button has correct aria-expanded state', () => {
      const nestedGroup = createMockGroup('nested-1', 'OR', [createMockCondition('cond-nested-1')])
      const rootGroup = createMockGroup('root-group', 'AND', [createMockCondition('cond-1')], [nestedGroup])

      render(<FilterGroup {...defaultProps} group={rootGroup} level={0} />)

      const collapseButton = screen.getByLabelText('Collapse group')
      expect(collapseButton).toHaveAttribute('aria-expanded', 'true')
    })
  })
})
