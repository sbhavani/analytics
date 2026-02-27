// Component tests for FilterBuilder

import React from 'react'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import '@testing-library/jest-dom'
import { FilterBuilder, FilterBuilderProvider, useFilterBuilder } from './FilterBuilder'
import { addCondition, createFilterTree } from './filterTreeUtils'

// Test component that exposes internal state for testing
const TestConsumer = () => {
  const { state, addCondition, clearAll, getSerializedFilters } = useFilterBuilder()

  return (
    <div>
      <div data-testid="filter-count">{state.filterTree.rootGroup.children.length}</div>
      <div data-testid="is-valid">{String(state.isValid)}</div>
      <button data-testid="add-btn" onClick={() => addCondition({ dimension: 'country', values: ['US'] })}>
        Add
      </button>
      <button data-testid="clear-btn" onClick={clearAll}>
        Clear
      </button>
      <button data-testid="get-filters-btn" onClick={() => getSerializedFilters()}>
        Get Filters
      </button>
    </div>
  )
}

describe('FilterBuilder', () => {
  describe('FilterBuilderProvider', () => {
    it('should render children', () => {
      render(
        <FilterBuilderProvider>
          <div data-testid="child">Child Content</div>
        </FilterBuilderProvider>
      )

      expect(screen.getByTestId('child')).toHaveTextContent('Child Content')
    })

    it('should initialize with empty filter tree', () => {
      render(
        <FilterBuilderProvider>
          <TestConsumer />
        </FilterBuilderProvider>
      )

      expect(screen.getByTestId('filter-count')).toHaveTextContent('0')
    })

    it('should add condition when addCondition is called', () => {
      render(
        <FilterBuilderProvider>
          <TestConsumer />
        </FilterBuilderProvider>
      )

      fireEvent.click(screen.getByTestId('add-btn'))

      expect(screen.getByTestId('filter-count')).toHaveTextContent('1')
    })

    it('should clear all filters', () => {
      render(
        <FilterBuilderProvider>
          <TestConsumer />
        </FilterBuilderProvider>
      )

      fireEvent.click(screen.getByTestId('add-btn'))
      expect(screen.getByTestId('filter-count')).toHaveTextContent('1')

      fireEvent.click(screen.getByTestId('clear-btn'))
      expect(screen.getByTestId('filter-count')).toHaveTextContent('0')
    })

    it('should initialize with filters when provided', () => {
      const initialFilters = [['is', 'country', ['US']]]

      render(
        <FilterBuilderProvider initialFilters={initialFilters as any}>
          <TestConsumer />
        </FilterBuilderProvider>
      )

      expect(screen.getByTestId('filter-count')).toHaveTextContent('1')
    })
  })

  describe('FilterBuilder component', () => {
    it('should render filter builder UI', () => {
      render(<FilterBuilder />)

      expect(screen.getByTestId('filter-builder')).toBeInTheDocument()
    })

    it('should show clear button', () => {
      render(<FilterBuilder />)

      expect(screen.getByText('Clear all')).toBeInTheDocument()
    })

    it('should show add filter button', () => {
      render(<FilterBuilder />)

      expect(screen.getByText('+ Add filter')).toBeInTheDocument()
    })

    it('should show apply filters button', () => {
      render(<FilterBuilder />)

      expect(screen.getByText('Apply filters')).toBeInTheDocument()
    })

    it('should add filter when add button clicked', () => {
      render(<FilterBuilder />)

      fireEvent.click(screen.getByText('+ Add filter'))

      expect(screen.getByTestId('condition-row')).toBeInTheDocument()
    })

    it('should show validation errors when apply clicked with invalid state', () => {
      render(<FilterBuilder />)

      // Click apply without adding any filters
      fireEvent.click(screen.getByText('Apply filters'))

      expect(screen.getByTestId('validation-errors')).toBeInTheDocument()
    })

    it('should disable apply button when invalid', () => {
      render(<FilterBuilder />)

      const applyButton = screen.getByText('Apply filters')
      expect(applyButton).toBeDisabled()
    })

    it('should call onApply callback with serialized filters', () => {
      const onApply = jest.fn()
      render(<FilterBuilder onApply={onApply} />)

      // Add a valid filter first
      fireEvent.click(screen.getByText('+ Add filter'))

      // Set dimension
      const dimensionSelect = screen.getByTestId('dimension-select')
      fireEvent.change(dimensionSelect, { target: { value: 'country' } })

      // Set value
      const valueInput = screen.getByTestId('value-input')
      fireEvent.change(valueInput, { target: { value: 'US' } })

      // Click apply
      fireEvent.click(screen.getByText('Apply filters'))

      expect(onApply).toHaveBeenCalledWith([['is', 'country', ['US']]])
    })

    it('should call onSave callback', () => {
      const onSave = jest.fn()
      render(<FilterBuilder onSave={onSave} />)

      fireEvent.click(screen.getByText('Save as segment'))

      expect(onSave).toHaveBeenCalled()
    })
  })

  describe('useFilterBuilder hook', () => {
    it('should throw error when used outside provider', () => {
      // Suppress console.error for this test
      const consoleSpy = jest.spyOn(console, 'error').mockImplementation(() => {})

      expect(() => {
        render(<TestConsumer />)
      }).toThrow('useFilterBuilder must be used within a FilterBuilderProvider')

      consoleSpy.mockRestore()
    })
  })
})
