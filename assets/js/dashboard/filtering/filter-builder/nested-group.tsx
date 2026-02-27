import React from 'react'

interface NestedGroupIndicatorProps {
  depth: number
  maxDepth: number
}

export const NestedGroupIndicator: React.FC<NestedGroupIndicatorProps> = ({
  depth,
  maxDepth
}) => {
  const remainingDepth = maxDepth - depth

  if (remainingDepth <= 0) {
    return null
  }

  return (
    <div className="flex items-center gap-2 text-xs text-gray-500">
      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth={2}
          d="M4 5a1 1 0 011-1h14a1 1 0 011 1v2a1 1 0 01-1 1H5a1 1 0 01-1-1V5zM4 13a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H5a1 1 0 01-1-1v-6zM16 13a1 1 0 011-1h2a1 1 0 011 1v6a1 1 0 01-1 1h-2a1 1 0 01-1-1v-6z"
        />
      </svg>
      <span>
        Nested group ({remainingDepth} level{remainingDepth !== 1 ? 's' : ''} remaining)
      </span>
    </div>
  )
}

export default NestedGroupIndicator
