import React from 'react'
import { Listbox, Transition } from '@headlessui/react'
import { ChevronUpDownIcon, CheckIcon } from '@heroicons/react/20/solid'
import classNames from 'classnames'
import { FilterOperator } from './types'

// Available operators
export const OPERATORS = [
  { value: 'is', label: 'is', supportedFields: ['all'] },
  { value: 'is_not', label: 'is not', supportedFields: ['all'] },
  { value: 'contains', label: 'contains', supportedFields: ['string', 'enum'] },
  { value: 'contains_not', label: 'does not contain', supportedFields: ['string', 'enum'] },
  { value: 'greater_than', label: 'greater than', supportedFields: ['number'] },
  { value: 'less_than', label: 'less than', supportedFields: ['number'] },
  { value: 'is_set', label: 'is set', supportedFields: ['all'] },
  { value: 'is_not_set', label: 'is not set', supportedFields: ['all'] }
]

interface OperatorSelectorProps {
  value: FilterOperator
  onChange: (operator: FilterOperator) => void
  field?: string
}

export default function OperatorSelector({ value, onChange, field }: OperatorSelectorProps) {
  // Get field type
  const fieldType = getFieldType(field)

  // Filter operators based on field type
  const availableOperators = OPERATORS.filter(op =>
    op.supportedFields.includes('all') || op.supportedFields.includes(fieldType)
  )

  const selectedOperator = OPERATORS.find(op => op.value === value)

  return (
    <Listbox value={value} onChange={onChange}>
      <div className="relative">
        <Listbox.Button
          className={classNames(
            'relative w-full cursor-pointer rounded-md border border-gray-300 bg-white py-2 pl-3 pr-10 text-left shadow-sm',
            'focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm'
          )}
        >
          <span className={classNames('block truncate', { 'text-gray-500': !selectedOperator })}>
            {selectedOperator?.label || 'Select operator'}
          </span>
          <span className="pointer-events-none absolute inset-y-0 right-0 flex items-center pr-2">
            <ChevronUpDownIcon className="h-5 w-5 text-gray-400" aria-hidden="true" />
          </span>
        </Listbox.Button>

        <Transition
          as={React.Fragment}
          leave="transition ease-in duration-100"
          leaveFrom="opacity-100"
          leaveTo="opacity-0"
        >
          <Listbox.Options className="absolute z-10 mt-1 max-h-60 w-full overflow-auto rounded-md bg-white py-1 text-base shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none sm:text-sm">
            {availableOperators.map((operator) => (
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
                    <span className={classNames('block truncate', { 'font-medium': selected, 'font-normal': !selected })}>
                      {operator.label}
                    </span>
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

function getFieldType(field: string | undefined): string {
  if (!field) return 'string'

  // Map fields to types
  const fieldTypes: Record<string, string> = {
    country: 'enum',
    region: 'enum',
    city: 'enum',
    browser: 'enum',
    browser_version: 'enum',
    os: 'enum',
    os_version: 'enum',
    device: 'enum',
    screen: 'enum',
    source: 'string',
    referrer: 'string',
    utm_medium: 'string',
    utm_source: 'string',
    utm_campaign: 'string',
    utm_term: 'string',
    utm_content: 'string',
    page: 'string',
    entry_page: 'string',
    exit_page: 'string',
    hostname: 'string',
    goal: 'enum',
    props: 'string'
  }

  return fieldTypes[field] || 'string'
}
