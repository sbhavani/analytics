import React, { useState, useEffect, forwardRef, useImperativeHandle, useRef } from 'react'
import { getAttributeType } from '../../util/filter-attributes'

// Common country codes for autocomplete
const COMMON_COUNTRIES = [
  { code: 'US', name: 'United States' },
  { code: 'GB', name: 'United Kingdom' },
  { code: 'DE', name: 'Germany' },
  { code: 'FR', name: 'France' },
  { code: 'CA', name: 'Canada' },
  { code: 'AU', name: 'Australia' },
  { code: 'JP', name: 'Japan' },
  { code: 'IN', name: 'India' },
  { code: 'BR', name: 'Brazil' },
  { code: 'ES', name: 'Spain' },
  { code: 'IT', name: 'Italy' },
  { code: 'NL', name: 'Netherlands' },
  { code: 'SE', name: 'Sweden' },
  { code: 'NO', name: 'Norway' },
  { code: 'DK', name: 'Denmark' },
  { code: 'FI', name: 'Finland' },
  { code: 'CH', name: 'Switzerland' },
  { code: 'AT', name: 'Austria' },
  { code: 'BE', name: 'Belgium' },
  { code: 'IE', name: 'Ireland' }
]

// Common device types
const DEVICE_TYPES = ['Desktop', 'Mobile', 'Tablet']

// Common browsers
const COMMON_BROWSERS = [
  'Chrome',
  'Firefox',
  'Safari',
  'Edge',
  'Opera',
  'Samsung Internet',
  'UC Browser',
  'Internet Explorer'
]

// Common operating systems
const COMMON_OS = [
  'Windows',
  'macOS',
  'Linux',
  'Android',
  'iOS',
  'Chrome OS',
  'FreeBSD'
]

// Common screen sizes
const SCREEN_SIZES = ['Desktop', 'Mobile', 'Tablet']

// Common channels
const CHANNELS = [
  'Organic Search',
  'Paid Search',
  'Social',
  'Referral',
  'Email',
  'Direct'
]

interface ValueInputProps {
  attribute: string
  value: string | string[]
  onChange: (value: string | string[]) => void
  onKeyDown?: (e: React.KeyboardEvent<HTMLInputElement | HTMLSelectElement>) => void
  disabled?: boolean
}

export const ValueInput = forwardRef<HTMLInputElement | HTMLSelectElement, ValueInputProps>(
  function ValueInput({ attribute, value, onChange, onKeyDown, disabled = false }, ref) {
    const [inputValue, setInputValue] = useState(
      Array.isArray(value) ? value.join(', ') : value
    )
    const innerRef = useRef<HTMLInputElement | HTMLSelectElement>(null)

    const attributeType = getAttributeType(attribute)

    // Expose the inner ref to the parent
    useImperativeHandle(ref, () => innerRef.current as HTMLInputElement | HTMLSelectElement, [])

    useEffect(() => {
      setInputValue(Array.isArray(value) ? value.join(', ') : value)
    }, [value])

    const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
      const newValue = e.target.value
      setInputValue(newValue)
      onChange(newValue)
    }

    // Render dropdown for country codes
    if (attributeType === 'country') {
      return (
        <select
          ref={innerRef}
          value={Array.isArray(value) ? value[0] || '' : value}
          onChange={(e) => onChange(e.target.value)}
          onKeyDown={onKeyDown}
          disabled={disabled}
          className="px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 min-w-[200px]"
          aria-label="Select country"
        >
          <option value="">Select country...</option>
          {COMMON_COUNTRIES.map((country) => (
            <option key={country.code} value={country.code}>
              {country.name} ({country.code})
            </option>
          ))}
        </select>
      )
    }

    // Render dropdown for device type
    if (attributeType === 'device') {
      return (
        <select
          ref={innerRef}
          value={Array.isArray(value) ? value[0] || '' : value}
          onChange={(e) => onChange(e.target.value)}
          onKeyDown={onKeyDown}
          disabled={disabled}
          className="px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 min-w-[150px]"
          aria-label="Select device"
        >
          <option value="">Select device...</option>
          {DEVICE_TYPES.map((device) => (
            <option key={device} value={device}>
              {device}
            </option>
          ))}
        </select>
      )
    }

    // Render dropdown for browser
    if (attributeType === 'browser') {
      return (
        <select
          ref={innerRef}
          value={Array.isArray(value) ? value[0] || '' : value}
          onChange={(e) => onChange(e.target.value)}
          onKeyDown={onKeyDown}
          disabled={disabled}
          className="px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 min-w-[150px]"
          aria-label="Select browser"
        >
          <option value="">Select browser...</option>
          {COMMON_BROWSERS.map((browser) => (
            <option key={browser} value={browser}>
              {browser}
            </option>
          ))}
        </select>
      )
    }

    // Render dropdown for OS
    if (attributeType === 'os') {
      return (
        <select
          ref={innerRef}
          value={Array.isArray(value) ? value[0] || '' : value}
          onChange={(e) => onChange(e.target.value)}
          onKeyDown={onKeyDown}
          disabled={disabled}
          className="px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 min-w-[150px]"
          aria-label="Select operating system"
        >
          <option value="">Select OS...</option>
          {COMMON_OS.map((os) => (
            <option key={os} value={os}>
              {os}
            </option>
          ))}
        </select>
      )
    }

    // Render dropdown for screen size
    if (attributeType === 'string' && attribute.includes('screen')) {
      return (
        <select
          ref={innerRef}
          value={Array.isArray(value) ? value[0] || '' : value}
          onChange={(e) => onChange(e.target.value)}
          onKeyDown={onKeyDown}
          disabled={disabled}
          className="px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 min-w-[150px]"
          aria-label="Select screen size"
        >
          <option value="">Select screen...</option>
          {SCREEN_SIZES.map((screen) => (
            <option key={screen} value={screen}>
              {screen}
            </option>
          ))}
        </select>
      )
    }

    // Render dropdown for channel
    if (attributeType === 'channel') {
      return (
        <select
          ref={innerRef}
          value={Array.isArray(value) ? value[0] || '' : value}
          onChange={(e) => onChange(e.target.value)}
          onKeyDown={onKeyDown}
          disabled={disabled}
          className="px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 min-w-[150px]"
          aria-label="Select channel"
        >
          <option value="">Select channel...</option>
          {CHANNELS.map((channel) => (
            <option key={channel} value={channel}>
              {channel}
            </option>
          ))}
        </select>
      )
    }

    // Render text input for other types
    return (
      <input
        ref={innerRef as React.RefObject<HTMLInputElement>}
        type="text"
        value={inputValue}
        onChange={handleChange}
        onKeyDown={onKeyDown as React.KeyboardEventHandler<HTMLInputElement>}
        disabled={disabled}
        placeholder="Enter value..."
        className="px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 min-w-[200px]"
        aria-label="Enter value"
      />
    )
  }
)
