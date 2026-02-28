import React from 'react'
import { Listbox, Transition } from '@headlessui/react'
import { ChevronUpDownIcon, CheckIcon, FolderOpenIcon } from '@heroicons/react/20/solid'
import { useFilterBuilder } from './FilterBuilderContext'
import { SavedSegment } from './types'

interface LoadTemplateDropdownProps {
  disabled?: boolean
}

export function LoadTemplateDropdown({ disabled = false }: LoadTemplateDropdownProps) {
  const { state, loadSegment } = useFilterBuilder()
  const { savedSegments, isLoadingSegments } = state

  const handleLoadSegment = (segment: SavedSegment) => {
    loadSegment(segment)
  }

  return (
    <div className="relative w-full">
      <Listbox
        value={null}
        onChange={handleLoadSegment}
        disabled={disabled}
      >
        <div className="relative">
          <Listbox.Button
            className={`
              relative w-full cursor-pointer rounded-md border bg-white py-2 pl-3 pr-10 text-left
              shadow-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm
              ${disabled ? 'bg-gray-100 cursor-not-allowed' : ''}
            `}
          >
            <span className="flex items-center text-gray-700">
              <FolderOpenIcon className="h-5 w-5 mr-2 text-gray-400" />
              {isLoadingSegments ? 'Loading...' : savedSegments.length === 0 ? 'No saved segments' : 'Load saved segment'}
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
              {savedSegments.length === 0 ? (
                <div className="relative cursor-default select-none py-2 pl-10 pr-4 text-gray-500">
                  No saved segments available
                </div>
              ) : (
                <>
                  {/* Personal segments */}
                  {savedSegments.filter(s => s.type === 'personal').length > 0 && (
                    <div className="px-3 py-1 text-xs font-semibold text-gray-500 uppercase tracking-wider">
                      My Segments
                    </div>
                  )}
                  {savedSegments
                    .filter(s => s.type === 'personal')
                    .map((segment) => (
                      <Listbox.Option
                        key={segment.id}
                        className={({ active }) =>
                          `relative cursor-pointer select-none py-2 pl-10 pr-4 ${
                            active ? 'bg-indigo-100 text-indigo-900' : 'text-gray-900'
                          }`
                        }
                        value={segment}
                      >
                        {({ selected }) => (
                          <>
                            <span className={`block truncate ${selected ? 'font-medium' : 'font-normal'}`}>
                              {segment.name}
                            </span>
                            {selected && (
                              <span className="absolute inset-y-0 left-0 flex items-center pl-3 text-indigo-600">
                                <CheckIcon className="h-5 w-5" aria-hidden="true" />
                              </span>
                            )}
                          </>
                        )}
                      </Listbox.Option>
                    ))
                  }

                  {/* Site segments */}
                  {savedSegments.filter(s => s.type === 'site').length > 0 && (
                    <>
                      <div className="px-3 py-1 text-xs font-semibold text-gray-500 uppercase tracking-wider">
                        Site Segments
                      </div>
                      {savedSegments
                        .filter(s => s.type === 'site')
                        .map((segment) => (
                          <Listbox.Option
                            key={segment.id}
                            className={({ active }) =>
                              `relative cursor-pointer select-none py-2 pl-10 pr-4 ${
                                active ? 'bg-indigo-100 text-indigo-900' : 'text-gray-900'
                              }`
                            }
                            value={segment}
                          >
                            {({ selected }) => (
                              <>
                                <span className={`block truncate ${selected ? 'font-medium' : 'font-normal'}`}>
                                  {segment.name}
                                </span>
                                {selected && (
                                  <span className="absolute inset-y-0 left-0 flex items-center pl-3 text-indigo-600">
                                    <CheckIcon className="h-5 w-5" aria-hidden="true" />
                                  </span>
                                )}
                              </>
                            )}
                          </Listbox.Option>
                        ))
                      }
                    </>
                  )}
                </>
              )}
            </Listbox.Options>
          </Transition>
        </div>
      </Listbox>
    </div>
  )
}

export default LoadTemplateDropdown
