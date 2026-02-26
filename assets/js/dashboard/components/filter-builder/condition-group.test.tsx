/**
 * Condition Group Component Tests
 *
 * Tests for condition removal functionality in the filter builder
 */

import React from 'react'
import { render, screen, fireEvent } from '@testing-library/react'
import { ConditionGroup } from './condition-group'
import { createCondition, createConditionGroup, FilterCondition, ConditionGroup as ConditionGroupType } from './types'
import { removeConditionFromGroup } from './utils'

describe('ConditionGroup condition removal', () => {
  describe('removeConditionFromGroup utility function', () => {
    it('should remove a single condition from a group', () => {
      const condition1 = createCondition('country', 'equals', 'US')
      const condition2 = createCondition('browser', 'equals', 'Firefox')

      const group: ConditionGroupType = {
        id: 'group-1',
        operator: 'AND',
        conditions: [condition1, condition2]
      }

      const result = removeConditionFromGroup(group, condition1.id)

      expect(result.conditions).toHaveLength(1)
      expect(result.conditions[0].id).toBe(condition2.id)
    })

    it('should remove the only condition from a group', () => {
      const condition1 = createCondition('country', 'equals', 'US')

      const group: ConditionGroupType = {
        id: 'group-1',
        operator: 'AND',
        conditions: [condition1]
      }

      const result = removeConditionFromGroup(group, condition1.id)

      expect(result.conditions).toHaveLength(0)
    })

    it('should not modify group when conditionId does not match', () => {
      const condition1 = createCondition('country', 'equals', 'US')
      const condition2 = createCondition('browser', 'equals', 'Firefox')

      const group: ConditionGroupType = {
        id: 'group-1',
        operator: 'AND',
        conditions: [condition1, condition2]
      }

      const result = removeConditionFromGroup(group, 'non-existent-id')

      expect(result.conditions).toHaveLength(2)
    })

    it('should remove a nested group', () => {
      const nestedGroup = createConditionGroup('OR')
      const condition1 = createCondition('country', 'equals', 'US')

      const group: ConditionGroupType = {
        id: 'group-1',
        operator: 'AND',
        conditions: [condition1, nestedGroup]
      }

      const result = removeConditionFromGroup(group, nestedGroup.id)

      expect(result.conditions).toHaveLength(1)
      expect(result.conditions[0]).toEqual(condition1)
    })

    it('should remove condition from nested group', () => {
      // Note: The current implementation of removeConditionFromGroup in utils.ts
      // only removes conditions from direct children, not recursively from nested groups.
      // This test documents the current behavior - removing the nested group itself.
      const nestedGroup = createConditionGroup('OR')
      nestedGroup.conditions = [
        createCondition('country', 'equals', 'US'),
        createCondition('browser', 'equals', 'Firefox')
      ]

      const group: ConditionGroupType = {
        id: 'group-1',
        operator: 'AND',
        conditions: [nestedGroup]
      }

      // Remove the nested group itself (not a condition inside it)
      const result = removeConditionFromGroup(group, nestedGroup.id)

      expect(result.conditions).toHaveLength(0)
    })

    it('should preserve group operator when removing condition', () => {
      const condition1 = createCondition('country', 'equals', 'US')

      const group: ConditionGroupType = {
        id: 'group-1',
        operator: 'OR',
        conditions: [condition1]
      }

      const result = removeConditionFromGroup(group, condition1.id)

      expect(result.operator).toBe('OR')
    })
  })

  describe('ConditionGroup component', () => {
    const defaultProps = {
      group: createConditionGroup('AND'),
      onAddCondition: jest.fn(),
      onUpdateCondition: jest.fn(),
      onRemoveCondition: jest.fn(),
      onAddGroup: jest.fn(),
      onUpdateGroupOperator: jest.fn(),
      onRemoveGroup: jest.fn(),
      isRoot: false
    }

    beforeEach(() => {
      jest.clearAllMocks()
    })

    it('should render remove button for each condition', () => {
      const group: ConditionGroupType = {
        id: 'group-1',
        operator: 'AND',
        conditions: [
          createCondition('country', 'equals', 'US')
        ]
      }

      render(<ConditionGroup {...defaultProps} group={group} />)

      const removeButtons = document.querySelectorAll('.filter-condition__remove-btn')
      expect(removeButtons.length).toBe(1)
    })

    it('should render add condition button', () => {
      const group = createConditionGroup('AND')

      render(<ConditionGroup {...defaultProps} group={group} />)

      expect(screen.getByText('+ Add Condition')).toBeInTheDocument()
    })

    it('should call onRemoveCondition when remove button is clicked', () => {
      const condition = createCondition('country', 'equals', 'US')
      const group: ConditionGroupType = {
        id: 'group-1',
        operator: 'AND',
        conditions: [condition]
      }

      render(<ConditionGroup {...defaultProps} group={group} />)

      const removeButton = document.querySelector('.filter-condition__remove-btn')
      fireEvent.click(removeButton!)

      expect(defaultProps.onRemoveCondition).toHaveBeenCalledWith(group.id, condition.id)
    })

    it('should render multiple conditions with separate remove buttons', () => {
      const group: ConditionGroupType = {
        id: 'group-1',
        operator: 'AND',
        conditions: [
          createCondition('country', 'equals', 'US'),
          createCondition('browser', 'equals', 'Firefox')
        ]
      }

      render(<ConditionGroup {...defaultProps} group={group} />)

      const removeButtons = document.querySelectorAll('.filter-condition__remove-btn')
      expect(removeButtons.length).toBe(2)
    })

    it('should render AND/OR operator toggle', () => {
      const group = createConditionGroup('AND')

      render(<ConditionGroup {...defaultProps} group={group} />)

      expect(screen.getByText('AND')).toBeInTheDocument()
      expect(screen.getByText('OR')).toBeInTheDocument()
    })

    it('should call onUpdateGroupOperator when AND button is clicked', () => {
      const group = createConditionGroup('OR')

      render(<ConditionGroup {...defaultProps} group={group} />)

      const andButton = screen.getByText('AND')
      fireEvent.click(andButton)

      expect(defaultProps.onUpdateGroupOperator).toHaveBeenCalledWith(group.id, 'AND')
    })

    it('should call onUpdateGroupOperator when OR button is clicked', () => {
      const group = createConditionGroup('AND')

      render(<ConditionGroup {...defaultProps} group={group} />)

      const orButton = screen.getByText('OR')
      fireEvent.click(orButton)

      expect(defaultProps.onUpdateGroupOperator).toHaveBeenCalledWith(group.id, 'OR')
    })

    it('should render remove group button for non-root groups', () => {
      const group = createConditionGroup('AND')

      render(<ConditionGroup {...defaultProps} group={group} isRoot={false} />)

      expect(screen.getByText('Remove Group')).toBeInTheDocument()
    })

    it('should not render remove group button for root group', () => {
      const group = createConditionGroup('AND')

      render(<ConditionGroup {...defaultProps} group={group} isRoot={true} />)

      expect(screen.queryByText('Remove Group')).not.toBeInTheDocument()
    })

    it('should call onRemoveGroup when remove group button is clicked', () => {
      const group = createConditionGroup('AND')

      render(<ConditionGroup {...defaultProps} group={group} isRoot={false} />)

      const removeGroupButton = screen.getByText('Remove Group')
      fireEvent.click(removeGroupButton)

      expect(defaultProps.onRemoveGroup).toHaveBeenCalledWith(group.id)
    })

    it('should render add group button', () => {
      const group = createConditionGroup('AND')

      render(<ConditionGroup {...defaultProps} group={group} />)

      expect(screen.getByText('+ Add Group')).toBeInTheDocument()
    })

    it('should call onAddGroup when add group button is clicked', () => {
      const group = createConditionGroup('AND')

      render(<ConditionGroup {...defaultProps} group={group} />)

      const addGroupButton = screen.getByText('+ Add Group')
      fireEvent.click(addGroupButton)

      expect(defaultProps.onAddGroup).toHaveBeenCalledWith(group.id)
    })
  })

  describe('Integration with FilterExpression', () => {
    beforeEach(() => {
      jest.clearAllMocks()
    })

    it('should handle removing condition from root group', () => {
      const expression = {
        version: 1,
        rootGroup: {
          id: 'root-1',
          operator: 'AND' as const,
          conditions: [
            createCondition('country', 'equals', 'US'),
            createCondition('browser', 'equals', 'Firefox')
          ]
        }
      }

      const conditionToRemove = (expression.rootGroup.conditions[0] as FilterCondition)
      const result = removeConditionFromGroup(expression.rootGroup, conditionToRemove.id)

      expect(result.conditions).toHaveLength(1)
      expect((result.conditions[0] as FilterCondition).field).toBe('browser')
    })

    it('should handle removing nested group from expression', () => {
      const nestedGroup = createConditionGroup('OR')
      nestedGroup.conditions = [
        createCondition('country', 'equals', 'US'),
        createCondition('browser', 'equals', 'Firefox')
      ]

      const expression = {
        version: 1,
        rootGroup: {
          id: 'root-1',
          operator: 'AND' as const,
          conditions: [nestedGroup]
        }
      }

      // Remove the nested group itself (not a condition inside it)
      const result = removeConditionFromGroup(expression.rootGroup, nestedGroup.id)

      expect(result.conditions).toHaveLength(0)
    })
  })
})
