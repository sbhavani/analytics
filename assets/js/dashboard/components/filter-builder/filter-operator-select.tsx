/**
 * OperatorSelect Dropdown Component
 *
 * A dropdown component for selecting filter operators in the Advanced Filter Builder.
 * Supports different operators based on the field type.
 */

import React, { useRef } from 'react'
import { Transition, Popover } from '@headlessui/react'
import { ChevronDownIcon } from '@heroicons/react/20/solid'
import classNames from 'classnames'

import {
  FilterOperator,
  FilterField,
  OPERATORS_BY_FIELD_TYPE,
  OPERATOR_DISPLAY_NAMES
} from './types'
import { popover, BlurMenuButtonOnEscape } from '../popover'

interface OperatorSelectProps {
  /** Currently selected operator */
  value: FilterOperator
  /** Callback when operator is selected */
  onChange: (operator: FilterOperator) => void
  /** The type of field to determine available operators */
  fieldType?: FilterField['type']
  /** Whether the dropdown is disabled */
  isDisabled?: boolean
  /** Additional CSS classes */
  className?: string
}

/**
 * Get available operators for a given field type
 */
function getAvailableOperators(fieldType?: FilterField['type']): FilterOperator[] {
  if (!fieldType) {
    // Return all operators if no field type specified
    return [
      'equals',
      'not_equals',
      'contains',
      'not_contains',
      'greater_than',
      'less_than',
      'matches_regex',
      'is_set',
      'is_not_set'
    ]
  }
  return OPERATORS_BY_FIELD_TYPE[fieldType] || OPERATORS_BY_FIELD_TYPE.string
}

export function OperatorSelect({
  value,
  onChange,
  fieldType,
  isDisabled = false,
  className
}: OperatorSelectProps) {
  const buttonRef = useRef<HTMLButtonElement>(null)
  const availableOperators = getAvailableOperators(fieldType)

  // Filter the display names to only show available operators
  const displayOperators = availableOperators.map((operator) => ({
    value: operator,
    label: OPERATOR_DISPLAY_NAMES[operator]
  }))

  return (
    <div
      className={classNames('w-full', {
        'opacity-50 cursor-not-allowed': isDisabled
      }, className)}
    >
      <Popover className="relative w-full">
        {({ close: closeDropdown }) => (
          <>
            <BlurMenuButtonOnEscape targetRef={buttonRef} />
            <Popover.Button
              ref={buttonRef}
              disabled={isDisabled}
              className={classNames(
                'relative flex justify-between items-center w-full',
                'rounded-md border border-gray-300 dark:border-gray-750',
                'px-4 py-2 bg-white dark:bg-gray-750',
                'text-sm text-gray-700 dark:text-gray-200',
                'dark:hover:bg-gray-700',
                'focus:outline-none focus:ring-2 focus:ring-offset-2',
                'focus:ring-offset-gray-100 dark:focus:ring-offset-gray-900',
                'focus:ring-indigo-500',
                'text-left',
                'disabled:cursor-not-allowed disabled:opacity-50'
              )}
            >
              <span className="truncate">
                {OPERATOR_DISPLAY_NAMES[value] || 'Select operator...'}
              </span>
              <ChevronDownIcon
                className="-mr-2 ml-2 h-4 w-4 text-gray-500 dark:text-gray-400 flex-shrink-0"
                aria-hidden="true"
              />
            </Popover.Button>
            <Transition
              as="div"
              {...popover.transition.props}
              className={classNames(popover.transition.classNames.left, 'mt-2')}
            >
              <Popover.Panel
                className={classNames(
                  popover.panel.classNames.roundedSheet,
                  'font-normal max-h-60 overflow-y-auto'
                )}
              >
                {displayOperators.map((operator) => (
                  <button
                    key={operator.value}
                    data-selected={operator.value === value}
                    onClick={(e) => {
                      // Prevent the click from propagating and closing modal
                      e.preventDefault()
                      e.stopPropagation()
                      onChange(operator.value)
                      closeDropdown()
                    }}
                    className={classNames(
                      'w-full text-left',
                      popover.items.classNames.navigationLink,
                      popover.items.classNames.selectedOption,
                      popover.items.classNames.hoverLink
                    )}
                  >
                    {operator.label}
                  </button>
                ))}
              </Popover.Panel>
            </Transition>
          </>
        )}
      </Popover>
    </div>
  )
}

export default OperatorSelect
