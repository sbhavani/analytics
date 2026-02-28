import React from 'react'
import { Listbox, Transition } from '@headlessui/react'
import { ChevronUpDownIcon, CheckIcon } from '@heroicons/react/20/solid'
import { FilterAttribute, FILTER_ATTRIBUTES } from './types'

interface DimensionSelectorProps {
  value: FilterAttribute | ''
  onChange: (value: FilterAttribute) => void
  disabled?: boolean
}

export function DimensionSelector({
  value,
  onChange,
  disabled = false
}: DimensionSelectorProps) {
  const selectedDimension = FILTER_ATTRIBUTES.find(d => d.key === value)

  return (
    <div className="relative w-full">
      <Listbox
        value={value}
        onChange={onChange}
        disabled={disabled}
      >
        <div className="relative">
          <Listbox.Button
            className={`
              relative w-full cursor-pointer rounded-md border bg-white py-2 pl-3 pr-10 text-left
              shadow-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm
              ${disabled ? 'bg-gray-100 cursor-not-allowed' : ''}
              ${!value ? 'text-gray-500' : 'text-gray-900'}
            `}
          >
            <span className="block truncate">
              {selectedDimension?.label || 'Select dimension'}
            </span>
            <span className="pointer-events-none absolute inset-y-0 right-0 flex items-center pr-2">
              <ChevronUpDownIcon
                className="h-5 w-5 text-gray-400"
                aria-hidden="true"
              />
            </span>
          </Listbox.Button>

          <Transition
            as={React.Fragment}
            leave="transition ease-in duration-100"
            leaveFrom="opacity-100"
            leaveTo="opacity-0"
          >
            <Listbox.Options className="absolute z-10 mt-1 max-h-60 w-full overflow-auto rounded-md bg-white py-1 text-base shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none sm:text-sm">
              {FILTER_ATTRIBUTES.map((dimension) => (
                <Listbox.Option
                  key={dimension.key}
                  className={({ active }) =>
                    `relative cursor-pointer select-none py-2 pl-10 pr-4 ${
                      active ? 'bg-indigo-100 text-indigo-900' : 'text-gray-900'
                    }`
                  }
                  value={dimension.key}
                >
                  {({ selected }) => (
                    <>
                      <span
                        className={`block truncate ${
                          selected ? 'font-medium' : 'font-normal'
                        }`}
                      >
                        {dimension.label}
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
    </div>
  )
}

export default DimensionSelector
