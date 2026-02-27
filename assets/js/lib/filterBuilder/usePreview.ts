import { useState, useEffect, useRef, useCallback } from 'react'
import { FilterTree } from './types'

export interface PreviewResult {
  matchingVisitors: number
  totalVisitors: number
  percentage: number
}

const API_BASE = '/api/v1/sites'

interface UsePreviewOptions {
  siteId: string
  debounceMs?: number
}

export function usePreview({ siteId, debounceMs = 300 }: UsePreviewOptions) {
  const [tree, setTree] = useState<FilterTree | null>(null)
  const [result, setResult] = useState<PreviewResult | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const debounceRef = useRef<NodeJS.Timeout | null>(null)

  const fetchPreview = useCallback(
    async (filterTree: FilterTree) => {
      if (!siteId) return

      setLoading(true)
      setError(null)

      try {
        const response = await fetch(`${API_BASE}/${siteId}/segments/preview`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            filter_tree: filterTree,
          }),
        })

        if (!response.ok) {
          throw new Error(`Preview failed: ${response.statusText}`)
        }

        const data = await response.json()
        setResult(data)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error')
        setResult(null)
      } finally {
        setLoading(false)
      }
    },
    [siteId]
  )

  const updateTree = useCallback(
    (newTree: FilterTree) => {
      setTree(newTree)

      if (debounceRef.current) {
        clearTimeout(debounceRef.current)
      }

      debounceRef.current = setTimeout(() => {
        fetchPreview(newTree)
      }, debounceMs)
    },
    [fetchPreview, debounceMs]
  )

  useEffect(() => {
    return () => {
      if (debounceRef.current) {
        clearTimeout(debounceRef.current)
      }
    }
  }, [])

  return {
    tree,
    result,
    loading,
    error,
    updateTree,
    refresh: tree ? () => fetchPreview(tree) : undefined,
  }
}
