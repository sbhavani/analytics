import React from 'react'
import { ErrorPanel } from '../../components/error-panel'

interface CohortErrorProps {
  error: Error | unknown
}

export function CohortError({ error }: CohortErrorProps) {
  const message = error instanceof Error ? error.message : 'Failed to load cohort data'

  return (
    <div className="py-8">
      <ErrorPanel errorMessage={message} />
    </div>
  )
}
