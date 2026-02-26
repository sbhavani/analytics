import { useCallback, useRef, KeyboardEvent } from 'react'

export type FieldType = 'attribute' | 'operator' | 'value' | 'remove'

interface UseKeyboardNavigationOptions {
  totalFields: number
  currentFieldIndex: number
  onNextField?: () => void
  onPreviousField?: () => void
  onAddCondition?: () => void
  onRemoveCondition?: () => void
  onEnter?: () => void
}

export function useKeyboardNavigation({
  totalFields,
  currentFieldIndex,
  onNextField,
  onPreviousField,
  onAddCondition,
  onRemoveCondition,
  onEnter
}: UseKeyboardNavigationOptions) {
  const handleKeyDown = useCallback(
    (e: KeyboardEvent<HTMLSelectElement | HTMLInputElement>) => {
      // Enter: Move to next field, or add new condition if on last field
      if (e.key === 'Enter') {
        e.preventDefault()
        if (currentFieldIndex < totalFields - 1) {
          onNextField?.()
        } else if (onAddCondition) {
          onAddCondition()
        } else if (onEnter) {
          onEnter()
        }
      }

      // Arrow Right: Move to next field
      if (e.key === 'ArrowRight' && currentFieldIndex < totalFields - 1) {
        e.preventDefault()
        onNextField?.()
      }

      // Arrow Left: Move to previous field
      if (e.key === 'ArrowLeft' && currentFieldIndex > 0) {
        e.preventDefault()
        onPreviousField?.()
      }

      // Escape: Clear current value or blur
      if (e.key === 'Escape') {
        e.preventDefault()
        // Blur the current element
        if (e.currentTarget instanceof HTMLElement) {
          e.currentTarget.blur()
        }
      }

      // Delete/Backspace with Alt: Remove condition
      if ((e.key === 'Delete' || e.key === 'Backspace') && e.altKey && onRemoveCondition) {
        e.preventDefault()
        onRemoveCondition()
      }
    },
    [
      currentFieldIndex,
      totalFields,
      onNextField,
      onPreviousField,
      onAddCondition,
      onRemoveCondition,
      onEnter
    ]
  )

  return { handleKeyDown }
}

// Hook for managing focus on form fields
export function useFocusManagement() {
  const fieldRefs = useRef<Map<string, HTMLSelectElement | HTMLInputElement>>(new Map())

  const registerField = useCallback((id: string, ref: HTMLSelectElement | HTMLInputElement | null) => {
    if (ref) {
      fieldRefs.current.set(id, ref)
    } else {
      fieldRefs.current.delete(id)
    }
  }, [])

  const focusField = useCallback((id: string) => {
    const field = fieldRefs.current.get(id)
    if (field) {
      field.focus()
      // Select all text if it's an input
      if (field instanceof HTMLInputElement) {
        field.select()
      }
    }
  }, [])

  const focusNextField = useCallback((currentId: string, fieldIds: string[]) => {
    const currentIndex = fieldIds.indexOf(currentId)
    if (currentIndex >= 0 && currentIndex < fieldIds.length - 1) {
      focusField(fieldIds[currentIndex + 1])
    }
  }, [focusField])

  const focusPreviousField = useCallback((currentId: string, fieldIds: string[]) => {
    const currentIndex = fieldIds.indexOf(currentId)
    if (currentIndex > 0) {
      focusField(fieldIds[currentIndex - 1])
    }
  }, [focusField])

  return { registerField, focusField, focusNextField, focusPreviousField, fieldRefs }
}

// Keyboard shortcut hints for the UI
export const KEYBOARD_SHORTCUTS = [
  { keys: ['Tab'], description: 'Navigate between fields' },
  { keys: ['Enter'], description: 'Next field / Add condition' },
  { keys: ['←', '→'], description: 'Navigate between fields' },
  { keys: ['Alt', 'Delete'], description: 'Remove condition' },
  { keys: ['Esc'], description: 'Clear current field' }
]
