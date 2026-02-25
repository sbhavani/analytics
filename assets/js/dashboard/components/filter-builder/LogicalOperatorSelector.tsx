import React from 'react'
import { Listbox, Transition } from '@headlessui/react'
import { ChevronUpDownIcon, CheckIcon } from '@heroicons/react/20/solid'
import classNames from 'classnames'
import { LogicalOperator } from './types'

interface LogicalOperatorSelectorProps {
  value: LogicalOperator
  onChange: (operator: LogicalOperator) => void
}

const OPERATORS: { value: LogicalOperator; label: string; description: string }[] = [
  { value: 'AND', label: 'AND', description: 'Match all conditions' },
  { value: 'OR', label: 'OR', description: 'Match any condition' }
]

export default function LogicalOperatorSelector({ value, onChange }: LogicalOperatorSelectorProps) {
  const selectedOperator = OPERATORS.find(op => op.value === value)

  return (
    <Listbox value={value} onChange={onChange}>
      <div className="relative">
        <Listbox.Button
          className={classNames(
            'relative w-full cursor-pointer rounded-md border py-2 pl-3 pr-10 text-left shadow-sm transition-colors',
            'focus:outline-none focus:ring-2 focus:ring-offset-1',
            value === 'AND'
              ? 'border-blue-300 bg-blue-50 text-blue-700 focus:ring-blue-500'
              : 'border-purple-300 bg-purple-50 text-purple-700 focus:ring-purple-500'
          )}
        >
          <span className="block truncate font-medium">
            {selectedOperator?.label}
          </span>
          <span className="pointer-events-none absolute inset-y-0 right-0 flex items-center pr-2">
            <ChevronUpDownIcon className="h-5 w-5" aria-hidden="true" />
          </span>
        </Listbox.Button>

        <Transition
          as={React.Fragment}
          leave="transition ease-in duration-100"
          leaveFrom="opacity-100"
          leaveTo="opacity-0"
        >
          <Listbox.Options className="absolute z-20 mt-1 w-full overflow-auto rounded-md bg-white py-1 text-base shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none sm:text-sm">
            {OPERATORS.map((operator) => (
              <Listbox.Option
                key={operator.value}
                className={({ active }) =>
                  classNames(
                    'relative cursor-pointer select-none py-2 pl-10 pr-4',
                    {
                      'bg-indigo-100 text-indigo-900': active,
                      'text-gray-900': !active
                    }
                  )
                }
                value={operator.value}
              >
                {({ selected }) => (
                  <>
                    <div className="flex flex-col">
                      <span className={classNames('block truncate', { 'font-medium': selected, 'font-normal': !selected })}>
                        {operator.label}
                      </span>
                      <span className={classNames('text-xs', { 'text-indigo-700': selected, 'text-gray-500': !selected })}>
                        {operator.description}
                      </span>
                    </div>
                    {selected && (
                      <span className="absolute inset-y-0 left-0 flex items-center pl-3 text-indigo-600">
                        <CheckIcon className="h-5 w-5" aria-hidden="true" />
                      </span>
                    )}
                  </>
                )}
              </Listbox.Option>
            ))}
          </Listbox.Options>
        </Transition>
      </div>
    </Listbox>
  )
}
