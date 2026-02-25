// API functions for segment operations
import { FilterExpression, filterExpressionToLegacyFilters } from '../types/filter-expression'
import { handleSegmentResponse, SavedSegment, SegmentData } from '../filtering/segments'

const DEFAULT_HEADERS = {
  'Content-Type': 'application/json',
}

interface CreateSegmentRequest {
  name: string
  type: 'personal' | 'site'
  filter_expression: FilterExpression
  site_id: number
}

interface CreateSegmentResponse {
  id: number
  name: string
  type: 'personal' | 'site'
  segment_data: {
    filters: unknown[]
    labels: Record<string, string>
  }
  inserted_at: string
  updated_at: string
}

export async function createSegment(
  siteId: number,
  name: string,
  type: 'personal' | 'site',
  expression: FilterExpression,
  labels: Record<string, string> = {}
): Promise<SavedSegment & { segment_data: SegmentData }> {
  const legacyFilters = filterExpressionToLegacyFilters(expression)

  const response = await fetch(`/api/sites/${siteId}/segments`, {
    method: 'POST',
    headers: DEFAULT_HEADERS,
    body: JSON.stringify({
      name,
      type,
      site_id: siteId,
      segment_data: {
        filters: legacyFilters,
        labels
      }
    })
  })

  if (!response.ok) {
    const error = await response.json()
    throw new Error(error.message || 'Failed to create segment')
  }

  const data = await response.json()
  return handleSegmentResponse(data as any)
}

export async function updateSegment(
  segmentId: number,
  name: string,
  expression: FilterExpression,
  labels: Record<string, string> = {}
): Promise<SavedSegment & { segment_data: SegmentData }> {
  const legacyFilters = filterExpressionToLegacyFilters(expression)

  const response = await fetch(`/api/segments/${segmentId}`, {
    method: 'PUT',
    headers: DEFAULT_HEADERS,
    body: JSON.stringify({
      name,
      segment_data: {
        filters: legacyFilters,
        labels
      }
    })
  })

  if (!response.ok) {
    const error = await response.json()
    throw new Error(error.message || 'Failed to update segment')
  }

  const data = await response.json()
  return handleSegmentResponse(data as any)
}

export async function deleteSegment(segmentId: number): Promise<void> {
  const response = await fetch(`/api/segments/${segmentId}`, {
    method: 'DELETE',
    headers: DEFAULT_HEADERS
  })

  if (!response.ok) {
    const error = await response.json()
    throw new Error(error.message || 'Failed to delete segment')
  }
}

export async function fetchSegments(siteId: number): Promise<SavedSegment[]> {
  const response = await fetch(`/api/sites/${siteId}/segments`, {
    method: 'GET',
    headers: DEFAULT_HEADERS
  })

  if (!response.ok) {
    const error = await response.json()
    throw new Error(error.message || 'Failed to fetch segments')
  }

  const data = await response.json()
  return data.segments as SavedSegment[]
}
