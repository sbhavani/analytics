import React from 'react'
import { render, screen, fireEvent } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { FilterCondition, FilterConditionData, FilterField } from '../../js/components/FilterCondition'

const mockCondition: FilterConditionData = {
  id: 'condition-1',
  field: 'country',
  operator: 'equals',
  value: 'US'
}

const mockAvailableFields: FilterField[] = [
  {
    name: 'country',
    displayName: 'Country',
    dataType: 'string',
    operators: ['equals', 'not_equals', 'is_empty', 'is_not_empty'],
    options: ['US', 'DE', 'FR', 'GB']
  },
  {
    name: 'pageviews',
    displayName: 'Pageviews',
    dataType: 'number',
    operators: ['greater_than', 'less_than', 'equals']
  },
  {
    name: 'entry_page',
    displayName: 'Entry Page',
    dataType: 'string',
    operators: ['equals', 'contains', 'is_empty', 'is_not_empty']
  }
]

describe('FilterCondition', () => {
  const mockOnUpdate = jest.fn()
  const mockOnRemove = jest.fn()

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders with initial condition data', () => {
    render(
      <FilterCondition
        condition={mockCondition}
        availableFields={mockAvailableFields}
        onUpdate={mockOnUpdate}
        onRemove={mockOnRemove}
      />
    )

    expect(screen.getByLabelText('Filter field')).toHaveValue('country')
    expect(screen.getByLabelText('Operator')).toHaveValue('equals')
    expect(screen.getByLabelText('Value')).toHaveValue('US')
  })

  it('displays all available fields in the field selector', () => {
    render(
      <FilterCondition
        condition={mockCondition}
        availableFields={mockAvailableFields}
        onUpdate={mockOnUpdate}
        onRemove={mockOnRemove}
      />
    )

    const fieldSelect = screen.getByLabelText('Filter field')
    const options = fieldSelect.querySelectorAll('option')

    expect(options).toHaveLength(4) // Default empty option + 3 fields
    expect(screen.getByText('Country')).toBeInTheDocument()
    expect(screen.getByText('Pageviews')).toBeInTheDocument()
    expect(screen.getByText('Entry Page')).toBeInTheDocument()
  })

  it('displays operators for selected field', () => {
    render(
      <FilterCondition
        condition={mockCondition}
        availableFields={mockAvailableFields}
        onUpdate={mockOnUpdate}
        onRemove={mockOnRemove}
      />
    )

    const operatorSelect = screen.getByLabelText('Operator')
    const options = operatorSelect.querySelectorAll('option')

    expect(options).toHaveLength(4) // equals, not_equals, is_empty, is_not_empty
  })

  it('calls onUpdate when field is changed', async () => {
    const user = userEvent.setup()
    render(
      <FilterCondition
        condition={mockCondition}
        availableFields={mockAvailableFields}
        onUpdate={mockOnUpdate}
        onRemove={mockOnRemove}
      />
    )

    const fieldSelect = screen.getByLabelText('Filter field')
    await user.selectOptions(fieldSelect, 'pageviews')

    expect(mockOnUpdate).toHaveBeenCalledWith({
      field: 'pageviews',
      operator: 'greater_than',
      value: ''
    })
  })

  it('calls onUpdate when operator is changed', async () => {
    const user = userEvent.setup()
    render(
      <FilterCondition
        condition={mockCondition}
        availableFields={mockAvailableFields}
        onUpdate={mockOnUpdate}
        onRemove={mockOnRemove}
      />
    )

    const operatorSelect = screen.getByLabelText('Operator')
    await user.selectOptions(operatorSelect, 'not_equals')

    expect(mockOnUpdate).toHaveBeenCalledWith({ operator: 'not_equals' })
  })

  it('calls onUpdate when value is changed', async () => {
    // Use entry_page field which has no predefined options (text input)
    const textInputCondition: FilterConditionData = {
      id: 'condition-1',
      field: 'entry_page',
      operator: 'contains',
      value: ''
    }

    render(
      <FilterCondition
        condition={textInputCondition}
        availableFields={mockAvailableFields}
        onUpdate={mockOnUpdate}
        onRemove={mockOnRemove}
      />
    )

    const valueInput = screen.getByLabelText('Value')
    fireEvent.change(valueInput, { target: { value: '/blog' } })

    expect(mockOnUpdate).toHaveBeenCalledWith({ value: '/blog' })
  })

  it('calls onRemove when remove button is clicked', () => {
    render(
      <FilterCondition
        condition={mockCondition}
        availableFields={mockAvailableFields}
        onUpdate={mockOnUpdate}
        onRemove={mockOnRemove}
      />
    )

    const removeButton = screen.getByLabelText('Remove condition')
    fireEvent.click(removeButton)

    expect(mockOnRemove).toHaveBeenCalled()
  })

  it('hides value input for is_empty operator', () => {
    const emptyCondition: FilterConditionData = {
      id: 'condition-1',
      field: 'country',
      operator: 'is_empty',
      value: ''
    }

    render(
      <FilterCondition
        condition={emptyCondition}
        availableFields={mockAvailableFields}
        onUpdate={mockOnUpdate}
        onRemove={mockOnRemove}
      />
    )

    expect(screen.queryByLabelText('Value')).not.toBeInTheDocument()
  })

  it('hides value input for is_not_empty operator', () => {
    const notEmptyCondition: FilterConditionData = {
      id: 'condition-1',
      field: 'country',
      operator: 'is_not_empty',
      value: ''
    }

    render(
      <FilterCondition
        condition={notEmptyCondition}
        availableFields={mockAvailableFields}
        onUpdate={mockOnUpdate}
        onRemove={mockOnRemove}
      />
    )

    expect(screen.queryByLabelText('Value')).not.toBeInTheDocument()
  })

  it('shows select dropdown for field with predefined options', () => {
    render(
      <FilterCondition
        condition={mockCondition}
        availableFields={mockAvailableFields}
        onUpdate={mockOnUpdate}
        onRemove={mockOnRemove}
      />
    )

    expect(screen.getByRole('combobox', { name: 'Value' })).toBeInTheDocument()
  })

  it('shows text input for field without predefined options', () => {
    const customCondition: FilterConditionData = {
      id: 'condition-1',
      field: 'entry_page',
      operator: 'contains',
      value: '/blog'
    }

    render(
      <FilterCondition
        condition={customCondition}
        availableFields={mockAvailableFields}
        onUpdate={mockOnUpdate}
        onRemove={mockOnRemove}
      />
    )

    expect(screen.getByLabelText('Value')).toHaveAttribute('type', 'text')
  })

  it('shows number input for number-type fields', () => {
    const numberCondition: FilterConditionData = {
      id: 'condition-1',
      field: 'pageviews',
      operator: 'greater_than',
      value: '10'
    }

    render(
      <FilterCondition
        condition={numberCondition}
        availableFields={mockAvailableFields}
        onUpdate={mockOnUpdate}
        onRemove={mockOnRemove}
      />
    )

    expect(screen.getByLabelText('Value')).toHaveAttribute('type', 'number')
  })

  it('disables operator select when no field is selected', () => {
    const noFieldCondition: FilterConditionData = {
      id: 'condition-1',
      field: '',
      operator: '',
      value: ''
    }

    render(
      <FilterCondition
        condition={noFieldCondition}
        availableFields={mockAvailableFields}
        onUpdate={mockOnUpdate}
        onRemove={mockOnRemove}
      />
    )

    expect(screen.getByLabelText('Operator')).toBeDisabled()
  })

  it('resets operator and value when field changes', async () => {
    const user = userEvent.setup()
    const conditionWithValue: FilterConditionData = {
      id: 'condition-1',
      field: 'country',
      operator: 'equals',
      value: 'US'
    }

    render(
      <FilterCondition
        condition={conditionWithValue}
        availableFields={mockAvailableFields}
        onUpdate={mockOnUpdate}
        onRemove={mockOnRemove}
      />
    )

    // Change field to pageviews
    const fieldSelect = screen.getByLabelText('Filter field')
    await user.selectOptions(fieldSelect, 'pageviews')

    // Should reset operator to first available operator for pageviews
    expect(mockOnUpdate).toHaveBeenCalledWith({
      field: 'pageviews',
      operator: 'greater_than',
      value: ''
    })
  })

  it('has proper accessibility attributes', () => {
    render(
      <FilterCondition
        condition={mockCondition}
        availableFields={mockAvailableFields}
        onUpdate={mockOnUpdate}
        onRemove={mockOnRemove}
      />
    )

    expect(screen.getByRole('group', { name: 'Filter condition' })).toBeInTheDocument()
    expect(screen.getByRole('combobox', { name: 'Filter field' })).toBeInTheDocument()
    expect(screen.getByRole('combobox', { name: 'Operator' })).toBeInTheDocument()
  })
})
