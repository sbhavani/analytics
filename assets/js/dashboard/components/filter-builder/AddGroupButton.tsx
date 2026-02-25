import React from 'react'
import { PlusIcon } from '@heroicons/react/20/solid'

interface AddGroupButtonProps {
  onClick: () => void
  disabled?: boolean
}

export default function AddGroupButton({ onClick, disabled = false }: AddGroupButtonProps) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      className="flex items-center gap-1 px-3 py-1.5 text-sm font-medium text-purple-600 bg-purple-50 rounded-md hover:bg-purple-100 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
      title="Add a group to combine multiple conditions"
    >
      <PlusIcon className="w-4 h-4" />
      Add Group
    </button>
  )
}
