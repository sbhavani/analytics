/**
 * PropertySelect Dropdown Component
 * Reusable dropdown for selecting visitor properties in the Filter Builder
 */

import React from 'react'
import { VISITOR_PROPERTIES, getPropertyByKey } from './properties'
import { VisitorProperty } from './types'

interface PropertySelectProps {
  value: string
  onChange: (propertyKey: string) => void
  disabled?: boolean
  className?: string
  placeholder?: string
}

export function PropertySelect({
  value,
  onChange,
  disabled = false,
  className = '',
  placeholder = 'Select property...'
}: PropertySelectProps) {
  const handleChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    onChange(e.target.value)
  }

  // Group properties by category for better UX
  const groupedProperties = React.useMemo(() => {
    const visitProps: VisitorProperty[] = []
    const eventProps: VisitorProperty[] = []

    VISITOR_PROPERTIES.forEach(prop => {
      if (prop.key.startsWith('visit:')) {
        visitProps.push(prop)
      } else if (prop.key.startsWith('event:')) {
        eventProps.push(prop)
      }
    })

    return { visit: visitProps, event: eventProps }
  }, [])

  return (
    <select
      value={value}
      onChange={handleChange}
      disabled={disabled}
      className={`px-3 py-1.5 text-sm border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-indigo-500 disabled:bg-gray-100 disabled:cursor-not-allowed ${className}`}
    >
      <option value="" disabled={!value}>
        {placeholder}
      </option>

      {groupedProperties.visit.length > 0 && (
        <optgroup label="Visit Properties">
          {groupedProperties.visit.map(prop => (
            <option key={prop.key} value={prop.key}>
              {prop.name}
            </option>
          ))}
        </optgroup>
      )}

      {groupedProperties.event.length > 0 && (
        <optgroup label="Event Properties">
          {groupedProperties.event.map(prop => (
            <option key={prop.key} value={prop.key}>
              {prop.name}
            </option>
          ))}
        </optgroup>
      )}
    </select>
  )
}

/**
 * Get the display name for a property key
 */
export function getPropertyDisplayName(propertyKey: string): string {
  const property = getPropertyByKey(propertyKey)
  return property?.name ?? propertyKey
}

export default PropertySelect
