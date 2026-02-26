/**
 * Filter Condition Editing Tests
 *
 * Tests for condition editing functionality in the Advanced Filter Builder
 */

import React from 'react'
import { render, screen, fireEvent } from '@testing-library/react'
import { FilterConditionRow } from './filter-condition'
import { FilterCondition } from './types'

// Default props for FilterConditionRow
const defaultProps = {
  condition: {
    id: 'test-condition-1',
    field: 'country',
    operator: 'equals' as const,
    value: 'US'
  },
  groupId: 'group-1',
  onUpdate: jest.fn(),
  onRemove: jest.fn()
}

describe('FilterConditionRow - Condition Editing', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  test('renders filter condition component', () => {
    render(<FilterConditionRow {...defaultProps} />)

    // The component should render a container
    const container = document.querySelector('.filter-condition')
    expect(container).toBeInTheDocument()
  })

  test('renders field select with correct initial value', () => {
    render(<FilterConditionRow {...defaultProps} />)

    const fieldSelect = document.querySelector('.filter-condition__field') as HTMLSelectElement
    expect(fieldSelect).toBeInTheDocument()
    expect(fieldSelect.value).toBe('country')
  })

  test('renders value input with correct initial value', () => {
    render(<FilterConditionRow {...defaultProps} />)

    const valueInput = document.querySelector('.filter-condition__value') as HTMLInputElement
    expect(valueInput).toBeInTheDocument()
    expect(valueInput.value).toBe('US')
  })

  test('calls onUpdate when field is changed', () => {
    const onUpdate = jest.fn()
    render(<FilterConditionRow {...defaultProps} onUpdate={onUpdate} />)

    const fieldSelect = document.querySelector('.filter-condition__field') as HTMLSelectElement
    fireEvent.change(fieldSelect, { target: { value: 'browser' } })

    expect(onUpdate).toHaveBeenCalledWith({
      field: 'browser',
      operator: 'equals',
      value: null
    })
  })

  test('calls onUpdate when value is changed', () => {
    const onUpdate = jest.fn()
    render(<FilterConditionRow {...defaultProps} onUpdate={onUpdate} />)

    const valueInput = document.querySelector('.filter-condition__value') as HTMLInputElement
    fireEvent.change(valueInput, { target: { value: 'DE' } })

    expect(onUpdate).toHaveBeenCalledWith({ value: 'DE' })
  })

  test('hides value input for is_set operator', () => {
    const condition: FilterCondition = {
      id: 'test-condition-1',
      field: 'country',
      operator: 'is_set',
      value: null
    }
    render(<FilterConditionRow {...defaultProps} condition={condition} />)

    // Value input should not be present
    const valueInput = document.querySelector('.filter-condition__value')
    expect(valueInput).not.toBeInTheDocument()
  })

  test('hides value input for is_not_set operator', () => {
    const condition: FilterCondition = {
      id: 'test-condition-1',
      field: 'country',
      operator: 'is_not_set',
      value: null
    }
    render(<FilterConditionRow {...defaultProps} condition={condition} />)

    // Value input should not be present
    const valueInput = document.querySelector('.filter-condition__value')
    expect(valueInput).not.toBeInTheDocument()
  })

  test('resets operator and value when field changes', () => {
    const onUpdate = jest.fn()
    render(<FilterConditionRow {...defaultProps} onUpdate={onUpdate} />)

    const fieldSelect = document.querySelector('.filter-condition__field') as HTMLSelectElement
    fireEvent.change(fieldSelect, { target: { value: 'browser' } })

    expect(onUpdate).toHaveBeenCalledWith({
      field: 'browser',
      operator: 'equals',
      value: null
    })
  })
})

describe('FilterConditionRow - Condition Removal', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  test('remove button calls onRemove callback', () => {
    const onRemove = jest.fn()
    render(<FilterConditionRow {...defaultProps} onRemove={onRemove} />)

    const removeButton = screen.getByRole('button', { name: /remove condition/i })
    fireEvent.click(removeButton)

    expect(onRemove).toHaveBeenCalledTimes(1)
  })

  test('remove button is disabled when disabled prop is true', () => {
    const onRemove = jest.fn()
    render(<FilterConditionRow {...defaultProps} onRemove={onRemove} disabled={true} />)

    const removeButton = screen.getByRole('button', { name: /remove condition/i })
    expect(removeButton).toBeDisabled()
    expect(onRemove).not.toHaveBeenCalled()
  })
})

describe('FilterConditionRow - Multiple Conditions', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  test('each condition maintains its own state', () => {
    const onUpdate1 = jest.fn()
    const onUpdate2 = jest.fn()

    const condition1: FilterCondition = {
      id: 'test-condition-1',
      field: 'country',
      operator: 'equals',
      value: 'US'
    }

    const condition2: FilterCondition = {
      id: 'test-condition-2',
      field: 'browser',
      operator: 'equals',
      value: 'Firefox'
    }

    const { rerender } = render(
      <FilterConditionRow
        condition={condition1}
        groupId="group-1"
        onUpdate={onUpdate1}
        onRemove={jest.fn()}
      />
    )

    // Verify first condition values
    const fieldSelect1 = document.querySelector('.filter-condition__field') as HTMLSelectElement
    expect(fieldSelect1.value).toBe('country')

    const valueInput1 = document.querySelector('.filter-condition__value') as HTMLInputElement
    expect(valueInput1.value).toBe('US')

    // Edit the first condition's value
    fireEvent.change(valueInput1, { target: { value: 'DE' } })
    expect(onUpdate1).toHaveBeenCalledWith({ value: 'DE' })

    // Render second condition
    rerender(
      <FilterConditionRow
        condition={condition2}
        groupId="group-1"
        onUpdate={onUpdate2}
        onRemove={jest.fn()}
      />
    )

    // Second condition should have its own values
    const fieldSelect2 = document.querySelector('.filter-condition__field') as HTMLSelectElement
    expect(fieldSelect2.value).toBe('browser')

    const valueInput2 = document.querySelector('.filter-condition__value') as HTMLInputElement
    expect(valueInput2.value).toBe('Firefox')
  })
})
