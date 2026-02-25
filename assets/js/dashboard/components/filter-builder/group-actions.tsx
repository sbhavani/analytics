import React from 'react'

interface GroupActionsProps {
  onCreateGroup?: () => void
  canCreateGroup?: boolean
}

export function GroupActions({ onCreateGroup, canCreateGroup = true }: GroupActionsProps) {
  if (!canCreateGroup) {
    return null
  }

  return (
    <div className="flex items-center space-x-2 mt-2">
      <button
        type="button"
        onClick={onCreateGroup}
        disabled={!canCreateGroup}
        className="inline-flex items-center px-3 py-1.5 text-sm font-medium text-indigo-700 bg-indigo-50 border border-indigo-200 rounded-md hover:bg-indigo-100 disabled:opacity-50 disabled:cursor-not-allowed"
      >
        <svg className="w-4 h-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 14v6m-3-3h6M6 10h2a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v2a2 2 0 002 2zm10 0h2a2 2 0 002-2V6a2 2 0 00-2-2h-2a2 2 0 00-2 2v2a2 2 0 002 2zM6 20h2a2 2 0 002-2v-2a2 2 0 00-2-2H6a2 2 0 00-2 2v2a2 2 0 002 2z" />
        </svg>
        Group conditions
      </button>
    </div>
  )
}

export default GroupActions
