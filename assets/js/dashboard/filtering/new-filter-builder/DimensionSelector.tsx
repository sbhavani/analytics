import React from 'react'
import { FILTER_MODAL_TO_FILTER_GROUP } from '../util/filters'

interface DimensionSelectorProps {
  value: string
  onChange: (dimension: string) => void
  disabled?: boolean
  className?: string
}

interface DimensionOption {
  value: string
  label: string
}

interface DimensionGroup {
  title: string
  options: DimensionOption[]
}

function formatDimensionLabel(dim: string): string {
  return dim.charAt(0).toUpperCase() + dim.slice(1).replace(/_/g, ' ')
}

function formatGroupLabel(groupKey: string): string {
  const labels: Record<string, string> = {
    page: 'Page',
    source: 'Acquisition',
    location: 'Location',
    screen: 'Device',
    browser: 'Browser',
    os: 'Operating System',
    utm: 'UTM Parameters',
    goal: 'Goal',
    props: 'Custom Properties',
    hostname: 'Hostname',
    segment: 'Segment'
  }
  return labels[groupKey] || groupKey
}

export function getDimensionGroups(sitePropsAvailable?: boolean): DimensionGroup[] {
  const groups: DimensionGroup[] = []

  Object.entries(FILTER_MODAL_TO_FILTER_GROUP).forEach(([category, dimensions]) => {
    // Skip 'props' if not available
    if (category === 'props' && !sitePropsAvailable) return

    groups.push({
      title: formatGroupLabel(category),
      options: dimensions.map((dim) => ({
        value: dim,
        label: formatDimensionLabel(dim)
      }))
    })
  })

  return groups
}

export function DimensionSelector({
  value,
  onChange,
  disabled = false,
  className = ''
}: DimensionSelectorProps) {
  const dimensionGroups = getDimensionGroups()
  const selectedOptionLabel = dimensionGroups
    .flatMap((g) => g.options)
    .find((opt) => opt.value === value)?.label || 'Select dimension'

  const handleChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    onChange(e.target.value)
  }

  return (
    <select
      className={`dimension-selector ${className}`}
      value={value}
      onChange={handleChange}
      disabled={disabled}
      data-testid="dimension-select"
    >
      <option value="">{selectedOptionLabel}</option>
      {dimensionGroups.map((group) => (
        <optgroup key={group.title} label={group.title}>
          {group.options.map((option) => (
            <option key={option.value} value={option.value}>
              {option.label}
            </option>
          ))}
        </optgroup>
      ))}
    </select>
  )
}
