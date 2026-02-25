import React from 'react'
import { Listbox, Transition } from '@headlessui/react'
import { ChevronUpDownIcon, CheckIcon } from '@heroicons/react/20/solid'
import classNames from 'classnames'

// Available visitor attributes for filtering
const VISITOR_ATTRIBUTES = [
  { key: 'country', label: 'Country', type: 'enum' },
  { key: 'region', label: 'Region', type: 'enum' },
  { key: 'city', label: 'City', type: 'enum' },
  { key: 'browser', label: 'Browser', type: 'enum' },
  { key: 'browser_version', label: 'Browser Version', type: 'enum' },
  { key: 'os', label: 'Operating System', type: 'enum' },
  { key: 'os_version', label: 'OS Version', type: 'enum' },
  { key: 'device', label: 'Device', type: 'enum' },
  { key: 'screen', label: 'Screen Size', type: 'enum' },
  { key: 'source', label: 'Source', type: 'string' },
  { key: 'referrer', label: 'Referrer', type: 'string' },
  { key: 'utm_medium', label: 'UTM Medium', type: 'string' },
  { key: 'utm_source', label: 'UTM Source', type: 'string' },
  { key: 'utm_campaign', label: 'UTM Campaign', type: 'string' },
  { key: 'utm_term', label: 'UTM Term', type: 'string' },
  { key: 'utm_content', label: 'UTM Content', type: 'string' },
  { key: 'page', label: 'Page', type: 'string' },
  { key: 'entry_page', label: 'Entry Page', type: 'string' },
  { key: 'exit_page', label: 'Exit Page', type: 'string' },
  { key: 'hostname', label: 'Hostname', type: 'string' },
  { key: 'goal', label: 'Goal', type: 'enum' },
  { key: 'props', label: 'Custom Property', type: 'string' }
]

interface FieldSelectorProps {
  value: string
  onChange: (field: string) => void
}

export default function FieldSelector({ value, onChange }: FieldSelectorProps) {
  const selectedAttribute = VISITOR_ATTRIBUTES.find(attr => attr.key === value)

  return (
    <Listbox value={value} onChange={onChange}>
      <div className="relative">
        <Listbox.Button
          className={classNames(
            'relative w-full cursor-pointer rounded-md border border-gray-300 bg-white py-2 pl-3 pr-10 text-left shadow-sm',
            'focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm'
          )}
        >
          <span className={classNames('block truncate', { 'text-gray-500': !selectedAttribute })}>
            {selectedAttribute?.label || 'Select field'}
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
            {VISITOR_ATTRIBUTES.map((attribute) => (
              <Listbox.Option
                key={attribute.key}
                className={({ active }) =>
                  classNames(
                    'relative cursor-pointer select-none py-2 pl-10 pr-4',
                    {
                      'bg-indigo-100 text-indigo-900': active,
                      'text-gray-900': !active
                    }
                  )
                }
                value={attribute.key}
              >
                {({ selected }) => (
                  <>
                    <span className={classNames('block truncate', { 'font-medium': selected, 'font-normal': !selected })}>
                      {attribute.label}
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

export { VISITOR_ATTRIBUTES }
