import React, { useRef } from 'react'

import {
  FILTER_OPERATIONS,
  FILTER_OPERATIONS_DISPLAY_NAMES,
  supportsContains,
  supportsIsNot,
  supportsHasDoneNot
} from '../../util/filters'
import { Transition, Popover } from '@headlessui/react'
import { ChevronDownIcon } from '@heroicons/react/20/solid'
import classNames from 'classnames'
import { popover, BlurMenuButtonOnEscape } from '../components/popover'

interface OperatorSelectorProps {
  selectedOperator: string
  dimension: string
  onChange: (operator: string) => void
  disabled?: boolean
}

export default function OperatorSelector({
  selectedOperator,
  dimension,
  onChange,
  disabled = false
}: OperatorSelectorProps) {
  const buttonRef = useRef<HTMLButtonElement>(null)

  const availableOperators = [
    [FILTER_OPERATIONS.is, true],
    [FILTER_OPERATIONS.isNot, supportsIsNot(dimension)],
    [FILTER_OPERATIONS.has_not_done, supportsHasDoneNot(dimension)],
    [FILTER_OPERATIONS.contains, supportsContains(dimension)],
    [
      FILTER_OPERATIONS.contains_not,
      supportsContains(dimension) && supportsIsNot(dimension)
    ]
  ]
    .filter(([_operation, supported]) => supported)
    .map(([operation]) => operation as string)

  return (
    <div
      className={classNames('w-full', {
        'opacity-20 cursor-default pointer-events-none': disabled
      })}
    >
      <Popover className="relative w-full">
        {({ close: closeDropdown }) => (
          <>
            <BlurMenuButtonOnEscape targetRef={buttonRef} />
            <Popover.Button
              ref={buttonRef}
              className="relative flex justify-between items-center w-full rounded-md border border-gray-300 dark:border-gray-750 px-4 py-2 bg-white dark:bg-gray-750 text-sm text-gray-700 dark:text-gray-200 dark:hover:bg-gray-700 focus:outline-hidden focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-100 dark:focus:ring-offset-gray-900 focus:ring-indigo-500 text-left"
            >
              <span className="truncate">
                {FILTER_OPERATIONS_DISPLAY_NAMES[selectedOperator as keyof typeof FILTER_OPERATIONS_DISPLAY_NAMES] || selectedOperator}
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
                  'font-normal'
                )}
              >
                {availableOperators.map((operation) => (
                  <button
                    key={operation}
                    data-selected={operation === selectedOperator}
                    onClick={(e) => {
                      // Prevent the click propagating and closing modal
                      e.preventDefault()
                      e.stopPropagation()
                      onChange(operation)
                      closeDropdown()
                    }}
                    className={classNames(
                      'w-full text-left',
                      popover.items.classNames.navigationLink,
                      popover.items.classNames.selectedOption,
                      popover.items.classNames.hoverLink
                    )}
                  >
                    {FILTER_OPERATIONS_DISPLAY_NAMES[operation as keyof typeof FILTER_OPERATIONS_DISPLAY_NAMES]}
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
