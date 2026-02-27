/**
 * Segment API Client
 * Provides methods for interacting with the segment API endpoints
 */

import {
  FilterTree,
  SavedSegment,
  PreviewResult,
  CreateSegmentRequest,
  UpdateSegmentRequest,
  PreviewRequest
} from '../types/filter-tree'

const DEFAULT_REQUEST_OPTIONS = {
  headers: {
    'Content-Type': 'application/json'
  }
}

/**
 * Gets the API base URL for a site
 */
function getApiBaseUrl(domain: string): string {
  return `/api/sites/${encodeURIComponent(domain)}`
}

/**
 * Lists all segments for a site
 */
export async function listSegments(domain: string): Promise<SavedSegment[]> {
  const response = await fetch(`${getApiBaseUrl(domain)}/segments`, {
    method: 'GET',
    ...DEFAULT_REQUEST_OPTIONS
  })

  if (!response.ok) {
    throw new Error(`Failed to list segments: ${response.statusText}`)
  }

  const data = await response.json()
  return data.segments || []
}

/**
 * Gets a single segment by ID
 */
export async function getSegment(domain: string, segmentId: number): Promise<SavedSegment> {
  const response = await fetch(`${getApiBaseUrl(domain)}/segments/${segmentId}`, {
    method: 'GET',
    ...DEFAULT_REQUEST_OPTIONS
  })

  if (!response.ok) {
    throw new Error(`Failed to get segment: ${response.statusText}`)
  }

  return response.json()
}

/**
 * Creates a new segment
 */
export async function createSegment(
  domain: string,
  request: CreateSegmentRequest
): Promise<SavedSegment> {
  const response = await fetch(`${getApiBaseUrl(domain)}/segments`, {
    method: 'POST',
    ...DEFAULT_REQUEST_OPTIONS,
    body: JSON.stringify(request)
  })

  if (!response.ok) {
    const error = await response.json().catch(() => ({ error: 'Failed to create segment' }))
    throw new Error(error.error || `Failed to create segment: ${response.statusText}`)
  }

  return response.json()
}

/**
 * Updates an existing segment
 */
export async function updateSegment(
  domain: string,
  segmentId: number,
  request: UpdateSegmentRequest
): Promise<SavedSegment> {
  const response = await fetch(`${getApiBaseUrl(domain)}/segments/${segmentId}`, {
    method: 'PATCH',
    ...DEFAULT_REQUEST_OPTIONS,
    body: JSON.stringify(request)
  })

  if (!response.ok) {
    const error = await response.json().catch(() => ({ error: 'Failed to update segment' }))
    throw new Error(error.error || `Failed to update segment: ${response.statusText}`)
  }

  return response.json()
}

/**
 * Deletes a segment
 */
export async function deleteSegment(domain: string, segmentId: number): Promise<void> {
  const response = await fetch(`${getApiBaseUrl(domain)}/segments/${segmentId}`, {
    method: 'DELETE',
    ...DEFAULT_REQUEST_OPTIONS
  })

  if (!response.ok) {
    throw new Error(`Failed to delete segment: ${response.statusText}`)
  }
}

/**
 * Duplicates a segment
 */
export async function duplicateSegment(domain: string, segmentId: number): Promise<SavedSegment> {
  const response = await fetch(`${getApiBaseUrl(domain)}/segments/${segmentId}/duplicate`, {
    method: 'POST',
    ...DEFAULT_REQUEST_OPTIONS
  })

  if (!response.ok) {
    throw new Error(`Failed to duplicate segment: ${response.statusText}`)
  }

  return response.json()
}

/**
 * Previews a segment with the given filter tree
 */
export async function previewSegment(
  domain: string,
  filterTree: FilterTree,
  options?: {
    metrics?: string[]
    dateRange?: { period: string; compareTo?: string }
  }
): Promise<PreviewResult> {
  const request: PreviewRequest = {
    filter_tree: filterTree,
    ...(options?.metrics && { metrics: options.metrics }),
    ...(options?.dateRange && { date_range: options.dateRange })
  }

  const response = await fetch(`${getApiBaseUrl(domain)}/segments/preview`, {
    method: 'POST',
    ...DEFAULT_REQUEST_OPTIONS,
    body: JSON.stringify(request)
  })

  if (!response.ok) {
    const error = await response.json().catch(() => ({ error: 'Failed to preview segment' }))
    throw new Error(error.error || `Failed to preview segment: ${response.statusText}`)
  }

  return response.json()
}
