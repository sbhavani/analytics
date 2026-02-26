import type { Segment, FilterData } from '../../types/filter-builder'

const BASE_URL = '/api'

interface ListSegmentsResponse {
  segments: Segment[]
}

interface CreateSegmentResponse {
  segment: Segment
}

interface UpdateSegmentResponse {
  segment: Segment
}

interface DeleteSegmentResponse {
  success: boolean
}

interface StatsQueryParams {
  site_id: string | number
  period?: string
  date?: string
  filters?: unknown[]
  metrics?: string[]
}

interface StatsResponse {
  results: Array<{
    visitors: number
  }>
}

export async function listSegments(siteId: string | number): Promise<Segment[]> {
  const response = await fetch(`${BASE_URL}/sites/${siteId}/segments`, {
    method: 'GET',
    headers: {
      'Content-Type': 'application/json'
    }
  })

  if (!response.ok) {
    const error = await response.json()
    throw new Error(error.error || 'Failed to fetch segments')
  }

  const data: ListSegmentsResponse = await response.json()
  return data.segments
}

export async function createSegment(
  siteId: string | number,
  name: string,
  segmentData: FilterData,
  type: 'personal' | 'site' = 'personal'
): Promise<Segment> {
  const response = await fetch(`${BASE_URL}/sites/${siteId}/segments`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      name,
      segment_data: segmentData,
      type
    })
  })

  if (!response.ok) {
    const error = await response.json()
    throw new Error(error.error || 'Failed to create segment')
  }

  const data: CreateSegmentResponse = await response.json()
  return data.segment
}

export async function updateSegment(
  siteId: string | number,
  segmentId: number,
  name: string,
  segmentData: FilterData
): Promise<Segment> {
  const response = await fetch(`${BASE_URL}/sites/${siteId}/segments/${segmentId}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      name,
      segment_data: segmentData
    })
  })

  if (!response.ok) {
    const error = await response.json()
    throw new Error(error.error || 'Failed to update segment')
  }

  const data: UpdateSegmentResponse = await response.json()
  return data.segment
}

export async function deleteSegment(
  siteId: string | number,
  segmentId: number
): Promise<void> {
  const response = await fetch(`${BASE_URL}/sites/${siteId}/segments/${segmentId}`, {
    method: 'DELETE',
    headers: {
      'Content-Type': 'application/json'
    }
  })

  if (!response.ok) {
    const error = await response.json()
    throw new Error(error.error || 'Failed to delete segment')
  }
}

export async function queryVisitorCount(
  siteId: string | number,
  filters: FilterData,
  period: string = '30d',
  date?: string
): Promise<number> {
  const params: StatsQueryParams = {
    site_id: siteId,
    period,
    metrics: ['visitors']
  }

  if (date) {
    params.date = date
  }

  // Convert filter data to query API format
  if (filters.filters && filters.filters.length > 0) {
    const { parseFilterDataToQueryFilters } = await import('../util/filter-query-parser')
    params.filters = parseFilterDataToQueryFilters(filters)
  }

  const queryString = new URLSearchParams()
  Object.entries(params).forEach(([key, value]) => {
    if (value !== undefined) {
      if (Array.isArray(value)) {
        queryString.set(key, JSON.stringify(value))
      } else {
        queryString.set(key, String(value))
      }
    }
  })

  const response = await fetch(`${BASE_URL}/stats/${siteId}?${queryString.toString()}`, {
    method: 'GET',
    headers: {
      'Content-Type': 'application/json'
    }
  })

  if (!response.ok) {
    const error = await response.json()
    throw new Error(error.error || 'Failed to fetch visitor count')
  }

  const data: StatsResponse = await response.json()
  return data.results?.[0]?.visitors ?? 0
}
