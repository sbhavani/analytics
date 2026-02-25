import { useState, useCallback } from 'react'

interface UseSuggestionsReturn {
  suggestions: string[]
  isLoading: boolean
  error: string | null
  fetchSuggestions: (input: string) => Promise<void>
}

export function useSuggestions(field: string): UseSuggestionsReturn {
  const [suggestions, setSuggestions] = useState<string[]>([])
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const fetchSuggestions = useCallback(async (input: string) => {
    if (!field || input.length < 2) {
      setSuggestions([])
      return
    }

    setIsLoading(true)
    setError(null)

    try {
      // Build the API URL
      const siteId = window.plausible?.siteId || ''
      const url = `/api/stats/${siteId}/suggestions/${field}?q=${encodeURIComponent(input)}`

      const response = await fetch(url)

      if (!response.ok) {
        throw new Error('Failed to fetch suggestions')
      }

      const data = await response.json()
      const suggestionsList = Array.isArray(data) ? data : data.results || []
      setSuggestions(suggestionsList)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error')
      setSuggestions([])
    } finally {
      setIsLoading(false)
    }
  }, [field])

  return {
    suggestions,
    isLoading,
    error,
    fetchSuggestions
  }
}
