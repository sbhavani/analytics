import React, { useRef, useMemo } from 'react'
import { Transition, Popover } from '@headlessui/react'
import { ChevronDownIcon } from '@heroicons/react/20/solid'
import classNames from 'classnames'
import {
  AVAILABLE_DIMENSIONS,
  getDimensionGroups,
  getDimensionsByGroup,
  DimensionOption
} from './types'
import { popover, BlurMenuButtonOnEscape } from '../components/popover'

interface DimensionSelectorProps {
  selectedDimension: string | null
  onSelect: (dimension: string) => void
  isDisabled?: boolean
}

export default function DimensionSelector({
  selectedDimension,
  onSelect,
  isDisabled = false
}: DimensionSelectorProps) {
  const buttonRef = useRef<HTMLButtonElement>(null)

  const selectedOption = useMemo(() => {
    if (!selectedDimension) return null
    return AVAILABLE_DIMENSIONS.find((d) => d.value === selectedDimension)
  }, [selectedDimension])

  const groups = useMemo(() => getDimensionGroups(), [])

  return (
    <div
      className={classNames('w-full', {
        'opacity-50 cursor-not-allowed pointer-events-none': isDisabled
      })}
    >
      <Popover className="relative w-full">
        {({ close: closeDropdown }) => (
          <>
            <BlurMenuButtonOnEscape targetRef={buttonRef} />
            <Popover.Button
              ref={buttonRef}
              className={classNames(
                'relative flex justify-between items-center w-full rounded-md border border-gray-300 dark:border-gray-750 px-4 py-2 bg-white dark:bg-gray-750 text-sm text-gray-700 dark:text-gray-200 dark:hover:bg-gray-700 focus:outline-hidden focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-100 dark:focus:ring-offset-gray-900 focus:ring-indigo-500 text-left',
                {
                  'border-red-500 focus:ring-red-500': !selectedDimension
                }
              )}
            >
              <span className={classNames({ 'text-gray-400': !selectedDimension })}>
                {selectedOption?.label || 'Select dimension'}
              </span>
              <ChevronDownIcon
                className="-mr-2 ml-2 h-4 w-4 text-gray-500 dark:text-gray-400"
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
                  'font-normal max-h-80 overflow-y-auto'
                )}
              >
                {groups.map((group) => (
                  <div key={group}>
                    <div className="px-4 py-1.5 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                      {group}
                    </div>
                    {getDimensionsByGroup(group).map((dimension) => (
                      <button
                        key={dimension.value}
                        data-selected={dimension.value === selectedDimension}
                        onClick={(e) => {
                          e.preventDefault()
                          e.stopPropagation()
                          onSelect(dimension.value)
                          closeDropdown()
                        }}
                        className={classNames(
                          'w-full text-left',
                          popover.items.classNames.navigationLink,
                          popover.items.classNames.selectedOption,
                          popover.items.classNames.hoverLink
                        )}
                      >
                        {dimension.label}
                      </button>
                    ))}
                  </div>
                ))}
              </Popover.Panel>
            </Transition>
          </>
        )}
      </Popover>
    </div>
  )
}

/**
 * Get the display label for a dimension value.
 */
export function getDimensionLabel(dimensionValue: string): string {
  const option = AVAILABLE_DIMENSIONS.find((d) => d.value === dimensionValue)
  return option?.label || dimensionValue
}
