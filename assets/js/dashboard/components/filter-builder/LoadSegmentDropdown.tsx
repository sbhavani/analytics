import React, { useState, useEffect } from 'react'
import { Listbox, Transition } from '@headlessui/react'
import { ChevronUpDownIcon, CheckIcon, ArrowPathIcon } from '@heroicons/react/20/solid'
import classNames from 'classnames'
import { useFilterBuilderContext } from './filter-builder-context'
import { useSiteContext } from '../../site-context'
import { legacyFiltersToFilterGroup } from './filter-serialization'
import { SavedSegment } from '../../filtering/segments'

export default function LoadSegmentDropdown() {
  const site = useSiteContext()
  const { loadSegment } = useFilterBuilderContext()
  const [segments, setSegments] = useState<SavedSegment[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [selectedSegment, setSelectedSegment] = useState<SavedSegment | null>(null)

  useEffect(() => {
    async function fetchSegments() {
      setIsLoading(true)
      try {
        const response = await fetch(`/api/stats/${site.domain}/segments`)

        if (!response.ok) {
          throw new Error('Failed to fetch segments')
        }

        const data = await response.json()
        setSegments(data || [])
      } catch (err) {
        console.error('Error loading segments:', err)
      } finally {
        setIsLoading(false)
      }
    }

    fetchSegments()
  }, [site.domain])

  const handleSelect = (segment: SavedSegment | null) => {
    setSelectedSegment(segment)

    if (segment && segment.segment_data?.filters) {
      // Convert legacy filters to filter group
      const filterGroup = legacyFiltersToFilterGroup(segment.segment_data.filters)
      loadSegment(filterGroup)
    }
  }

  if (isLoading) {
    return (
      <div className="flex items-center gap-2 text-sm text-gray-500">
        <ArrowPathIcon className="w-4 h-4 animate-spin" />
        Loading segments...
      </div>
    )
  }

  if (segments.length === 0) {
    return (
      <span className="text-sm text-gray-500">
        No saved segments
      </span>
    )
  }

  return (
    <Listbox value={selectedSegment} onChange={handleSelect}>
      <div className="relative">
        <Listbox.Button
          className={classNames(
            'relative w-48 cursor-pointer rounded-md border border-gray-300 bg-white py-1.5 pl-3 pr-10 text-left shadow-sm',
            'focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm'
          )}
        >
          <span className={classNames('block truncate', { 'text-gray-500': !selectedSegment })}>
            {selectedSegment?.name || 'Load segment...'}
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
            <Listbox.Option
              value={null}
              className={({ active }) =>
                classNames(
                  'relative cursor-pointer select-none py-2 pl-10 pr-4',
                  {
                    'bg-indigo-100 text-indigo-900': active,
                    'text-gray-900': !active
                  }
                )
              }
            >
              <span className="block truncate font-normal">Load segment...</span>
            </Listbox.Option>

            {segments.map((segment) => (
              <Listbox.Option
                key={segment.id}
                value={segment}
                className={({ active }) =>
                  classNames(
                    'relative cursor-pointer select-none py-2 pl-10 pr-4',
                    {
                      'bg-indigo-100 text-indigo-900': active,
                      'text-gray-900': !active
                    }
                  )
                }
              >
                {({ selected }) => (
                  <>
                    <div className="flex flex-col">
                      <span className={classNames('block truncate', { 'font-medium': selected, 'font-normal': !selected })}>
                        {segment.name}
                      </span>
                      <span className="text-xs text-gray-500">
                        {segment.type === 'personal' ? 'Personal' : 'Site'} • Updated {new Date(segment.updated_at).toLocaleDateString()}
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
