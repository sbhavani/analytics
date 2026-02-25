import React, { useRef } from 'react'
import { Popover, Transition } from '@headlessui/react'
import { ChevronDownIcon } from '@heroicons/react/20/solid'
import classNames from 'classnames'
import { FilterOperator } from './types'
import { getOperatorsForProperty, getOperatorDisplayName } from './properties'

interface OperatorSelectProps {
  propertyKey: string
  value: FilterOperator | ''
  onChange: (operator: FilterOperator) => void
  isDisabled?: boolean
}

export default function OperatorSelect({
  propertyKey,
  value,
  onChange,
  isDisabled = false
}: OperatorSelectProps) {
  const buttonRef = useRef<HTMLButtonElement>(null)

  const availableOperators = getOperatorsForProperty(propertyKey)
  const selectedLabel = value ? getOperatorDisplayName(value) : 'Select operator'

  return (
    <div
      className={classNames('w-full', {
        'opacity-50 cursor-not-allowed pointer-events-none': isDisabled
      })}
    >
      <Popover className="relative w-full">
        {({ close: closeDropdown }) => (
          <>
            <Popover.Button
              ref={buttonRef}
              disabled={isDisabled || availableOperators.length === 0}
              className="relative flex justify-between items-center w-full rounded-md border border-gray-300 dark:border-gray-750 px-3 py-2 bg-white dark:bg-gray-750 text-sm text-gray-700 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-gray-700 focus:outline-hidden focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-100 dark:focus:ring-offset-gray-900 focus:ring-indigo-500 text-left transition-colors"
            >
              <span className={classNames('truncate', { 'text-gray-400': !value })}>
                {selectedLabel}
              </span>
              <ChevronDownIcon
                className="-mr-1 ml-2 h-4 w-4 text-gray-500 dark:text-gray-400 flex-shrink-0"
                aria-hidden="true"
              />
            </Popover.Button>
            <Transition
              as="div"
              enter="transition ease-out duration-100"
              enterFrom="opacity-0 translate-y-1"
              enterTo="opacity-100 translate-y-0"
              leave="transition ease-in duration-75"
              leaveFrom="opacity-100 translate-y-0"
              leaveTo="opacity-0 translate-y-1"
              className="absolute z-10 mt-1 w-full"
            >
              <Popover.Panel className="rounded-md bg-white dark:bg-gray-800 shadow-lg ring-1 ring-black ring-opacity-5 dark:ring-gray-700 focus:outline-hidden max-h-60 overflow-auto">
                {availableOperators.length === 0 ? (
                  <div className="relative cursor-default select-none py-2 px-4 text-sm text-gray-500 dark:text-gray-400">
                    No operators available
                  </div>
                ) : (
                  <div className="py-1">
                    {availableOperators.map((operator) => (
                      <button
                        key={operator}
                        data-selected={operator === value}
                        onClick={(e) => {
                          e.preventDefault()
                          e.stopPropagation()
                          onChange(operator)
                          closeDropdown()
                        }}
                        className={classNames(
                          'w-full text-left px-4 py-2 text-sm transition-colors',
                          operator === value
                            ? 'bg-indigo-50 dark:bg-indigo-900/30 text-indigo-700 dark:text-indigo-300 font-medium'
                            : 'text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700'
                        )}
                      >
                        {getOperatorDisplayName(operator)}
                      </button>
                    ))}
                  </div>
                )}
              </Popover.Panel>
            </Transition>
          </>
        )}
      </Popover>
    </div>
  )
}
