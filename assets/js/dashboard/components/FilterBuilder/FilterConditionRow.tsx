import React, { useMemo, useCallback, useRef, KeyboardEvent } from 'react'
import type { FilterCondition } from '../../../types/filter-builder'
import { AttributeSelector } from './AttributeSelector'
import { OperatorSelector } from './OperatorSelector'
import { ValueInput } from './ValueInput'

interface FilterConditionRowProps {
  condition: FilterCondition
  onUpdate: (updates: Partial<FilterCondition>) => void
  onRemove: () => void
  onAddCondition?: () => void
  onFocusNext?: () => void
  onFocusPrevious?: () => void
  isFirst?: boolean
  isLast?: boolean
  disabled?: boolean
}

export function FilterConditionRow({
  condition,
  onUpdate,
  onRemove,
  onAddCondition,
  onFocusNext,
  onFocusPrevious,
  isFirst = false,
  isLast = false,
  disabled = false
}: FilterConditionRowProps) {
  const attributeRef = useRef<HTMLSelectElement>(null)
  const operatorRef = useRef<HTMLSelectElement>(null)
  const valueRef = useRef<HTMLInputElement | HTMLSelectElement>(null)
  const removeButtonRef = useRef<HTMLButtonElement>(null)

  const showValueInput = useMemo(() => {
    const operatorsRequiringValue = [
      'equals',
      'does_not_equal',
      'contains',
      'does_not_contain',
      'matches_regexp',
      'does_not_match_regexp'
    ]
    return operatorsRequiringValue.includes(condition.operator)
  }, [condition.operator])

  const handleKeyDown = useCallback(
    (e: KeyboardEvent<HTMLSelectElement | HTMLInputElement>) => {
      // Enter: Move to next field, or add new condition if on last field
      if (e.key === 'Enter') {
        e.preventDefault()
        if (showValueInput && e.currentTarget !== valueRef.current) {
          // If not on value field and value is shown, focus value
          valueRef.current?.focus()
        } else if (isLast && onAddCondition) {
          // If on last field (or no value input), add new condition
          onAddCondition()
        } else if (onFocusNext) {
          // Move to next field in the row
          onFocusNext()
        }
      }

      // Arrow Right: Move to next field
      if (e.key === 'ArrowRight') {
        const target = e.currentTarget
        if (target === attributeRef.current) {
          operatorRef.current?.focus()
        } else if (target === operatorRef.current && showValueInput) {
          valueRef.current?.focus()
        } else if (target === valueRef.current || (target === operatorRef.current && !showValueInput)) {
          removeButtonRef.current?.focus()
        }
      }

      // Arrow Left: Move to previous field
      if (e.key === 'ArrowLeft') {
        const target = e.currentTarget
        if (target === removeButtonRef.current) {
          if (showValueInput) {
            valueRef.current?.focus()
          } else {
            operatorRef.current?.focus()
          }
        } else if (target === valueRef.current) {
          operatorRef.current?.focus()
        } else if (target === operatorRef.current) {
          attributeRef.current?.focus()
        }
      }

      // Escape: Blur current element
      if (e.key === 'Escape') {
        e.preventDefault()
        e.currentTarget.blur()
      }

      // Alt + Delete/Backspace: Remove condition
      if ((e.key === 'Delete' || e.key === 'Backspace') && e.altKey) {
        e.preventDefault()
        onRemove()
      }

      // Shift + Tab: Move to previous field
      if (e.key === 'Tab' && e.shiftKey) {
        const target = e.currentTarget
        if (target === attributeRef.current && onFocusPrevious) {
          // Prevent default and let focus move naturally
          // But we could also manually handle it
        }
      }
    },
    [showValueInput, isLast, onAddCondition, onFocusNext, onFocusPrevious, onRemove]
  )

  // Expose refs for parent focus management
  React.useImperativeHandle(
    React.useRef(null),
    () => ({
      focusAttribute: () => attributeRef.current?.focus(),
      focusOperator: () => operatorRef.current?.focus(),
      focusValue: () => valueRef.current?.focus(),
      focusRemove: () => removeButtonRef.current?.focus()
    }),
    []
  )

  return (
    <div className="flex items-center gap-2 p-2 bg-white rounded border border-gray-200">
      <AttributeSelector
        ref={attributeRef}
        value={condition.attribute}
        onChange={(attribute) => onUpdate({ attribute })}
        onKeyDown={handleKeyDown}
        disabled={disabled}
      />

      <OperatorSelector
        ref={operatorRef}
        attribute={condition.attribute}
        value={condition.operator}
        onChange={(operator) => onUpdate({ operator, value: '' })}
        onKeyDown={handleKeyDown}
        disabled={disabled}
      />

      {showValueInput && (
        <ValueInput
          ref={valueRef}
          attribute={condition.attribute}
          value={condition.value}
          onChange={(value) => onUpdate({ value })}
          onKeyDown={handleKeyDown}
          disabled={disabled}
        />
      )}

      <button
        ref={removeButtonRef}
        type="button"
        onClick={onRemove}
        disabled={disabled}
        className="p-1 text-gray-400 hover:text-red-500 transition-colors focus:outline-none focus:ring-2 focus:ring-red-500 rounded"
        title="Remove condition (Alt+Delete)"
        aria-label="Remove condition"
      >
        <svg
          className="w-5 h-5"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M6 18L18 6M6 6l12 12"
          />
        </svg>
      </button>
    </div>
  )
}
