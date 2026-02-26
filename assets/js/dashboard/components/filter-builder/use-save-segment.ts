/**
 * Save Segment Hook
 *
 * Custom hook for saving segments from the Filter Builder
 * Uses the existing segments API
 */

import { useCallback } from 'react'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { mutation as apiMutation } from '../../api'
import { useSiteContext } from '../../site-context'
import { useSegmentsContext } from '../../filtering/segments-context'
import {
  FilterExpression,
  SegmentDataWithExpression,
  expressionToFilters
} from './types'
import { remapToApiFilters, cleanLabels } from '../../util/filters'
import { handleSegmentResponse, SavedSegment, SegmentDataFromApi } from '../../filtering/segments'

interface SaveSegmentParams {
  name: string
  type: 'personal' | 'site'
  expression: FilterExpression
}

interface SaveSegmentOptions {
  /** Callback on successful save */
  onSuccess?: (segment: SavedSegment) => void
  /** Callback on error */
  onError?: (error: Error) => void
}

/**
 * Hook for saving a segment from the Filter Builder
 *
 * Uses the existing segments API and includes both:
 * - Legacy filters for backward compatibility
 * - Full expression for the new filter builder
 */
export function useSaveSegment(options?: SaveSegmentOptions) {
  const site = useSiteContext()
  const queryClient = useQueryClient()
  const { addOne } = useSegmentsContext()

  const mutation = useMutation({
    mutationFn: async ({ name, type, expression }: SaveSegmentParams) => {
      // Convert expression to legacy filters for backward compatibility
      const legacyFilters = expressionToFilters(expression)

      // Build segment data with both formats
      const segmentData: SegmentDataWithExpression = {
        // Legacy format for backward compatibility
        filters: remapToApiFilters(legacyFilters),
        labels: cleanLabels(legacyFilters, {}),
        // New format for filter builder
        expression
      }

      // Call the existing segments API
      const response: SavedSegment & { segment_data: SegmentDataFromApi } =
        await apiMutation(`/api/${encodeURIComponent(site.domain)}/segments`, {
          method: 'POST',
          body: {
            name,
            type,
            segment_data: segmentData
          }
        })

      return handleSegmentResponse(response)
    },
    onSuccess: (segment) => {
      // Add the new segment to the context
      addOne(segment)
      // Invalidate segments query to refresh the list
      queryClient.invalidateQueries({ queryKey: ['segments'] })
      // Call the success callback
      options?.onSuccess?.(segment)
    },
    onError: (error) => {
      // Call the error callback
      options?.onError?.(error as Error)
    }
  })

  const saveSegment = useCallback(
    (name: string, type: 'personal' | 'site', expression: FilterExpression) => {
      mutation.mutate({ name, type, expression })
    },
    [mutation]
  )

  return {
    saveSegment,
    isSaving: mutation.isPending,
    error: mutation.error,
    reset: mutation.reset
  }
}

/**
 * Hook for updating an existing segment from the Filter Builder
 */
export function useUpdateSegment(options?: SaveSegmentOptions) {
  const site = useSiteContext()
  const queryClient = useQueryClient()
  const { updateOne } = useSegmentsContext()

  const mutation = useMutation({
    mutationFn: async ({
      id,
      name,
      type,
      expression
    }: {
      id: number
      name?: string
      type?: 'personal' | 'site'
      expression: FilterExpression
    }) => {
      // Convert expression to legacy filters for backward compatibility
      const legacyFilters = expressionToFilters(expression)

      // Build segment data with both formats
      const segmentData: SegmentDataWithExpression = {
        // Legacy format for backward compatibility
        filters: remapToApiFilters(legacyFilters),
        labels: cleanLabels(legacyFilters, {}),
        // New format for filter builder
        expression
      }

      // Call the existing segments API
      const response: SavedSegment & { segment_data: SegmentDataFromApi } =
        await apiMutation(`/api/${encodeURIComponent(site.domain)}/segments/${id}`, {
          method: 'PATCH',
          body: {
            name,
            type,
            segment_data: segmentData
          }
        })

      return handleSegmentResponse(response)
    },
    onSuccess: (segment) => {
      // Update the segment in the context
      updateOne(segment)
      // Invalidate segments query to refresh the list
      queryClient.invalidateQueries({ queryKey: ['segments'] })
      // Call the success callback
      options?.onSuccess?.(segment)
    },
    onError: (error) => {
      // Call the error callback
      options?.onError?.(error as Error)
    }
  })

  const updateSegment = useCallback(
    (id: number, name?: string, type?: 'personal' | 'site', expression?: FilterExpression) => {
      if (!expression) return
      mutation.mutate({ id, name, type, expression })
    },
    [mutation]
  )

  return {
    updateSegment,
    isUpdating: mutation.isPending,
    error: mutation.error,
    reset: mutation.reset
  }
}
