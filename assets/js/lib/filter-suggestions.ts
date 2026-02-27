/**
 * Filter Suggestions API Client
 * Provides methods for fetching filter value suggestions
 */

export interface FilterSuggestion {
  value: string
  label: string
}

/**
 * Fetches filter suggestions for a given attribute
 */
export async function fetchFilterSuggestions(
  domain: string,
  attribute: string,
  query: string = ''
): Promise<FilterSuggestion[]> {
  const params = new URLSearchParams({
    filter_attribute: attribute
  })

  if (query) {
    params.set('q', query)
  }

  const url = `/api/stats/${encodeURIComponent(domain)}/suggestions/${attribute.replace('visit:', '').replace('event:', '')}?${params}`

  try {
    const response = await fetch(url)

    if (!response.ok) {
      console.warn(`Failed to fetch suggestions for ${attribute}: ${response.statusText}`)
      return []
    }

    const data = await response.json()

    // Transform API response to FilterSuggestion format
    if (Array.isArray(data)) {
      return data.map((item: { value?: string; name?: string }) => ({
        value: item.value || item.name || '',
        label: item.name || item.value || ''
      }))
    }

    return []
  } catch (error) {
    console.warn(`Error fetching suggestions for ${attribute}:`, error)
    return []
  }
}

/**
 * Gets the list of available filter attributes
 */
export function getAvailableAttributes(): Array<{ key: string; label: string; type: 'visit' | 'event' | 'custom' }> {
  return [
    // Visit properties
    { key: 'visit:source', label: 'Source', type: 'visit' },
    { key: 'visit:channel', label: 'Channel', type: 'visit' },
    { key: 'visit:referrer', label: 'Referrer', type: 'visit' },
    { key: 'visit:utm_medium', label: 'UTM Medium', type: 'visit' },
    { key: 'visit:utm_source', label: 'UTM Source', type: 'visit' },
    { key: 'visit:utm_campaign', label: 'UTM Campaign', type: 'visit' },
    { key: 'visit:utm_content', label: 'UTM Content', type: 'visit' },
    { key: 'visit:utm_term', label: 'UTM Term', type: 'visit' },
    { key: 'visit:screen', label: 'Screen Size', type: 'visit' },
    { key: 'visit:device', label: 'Device', type: 'visit' },
    { key: 'visit:browser', label: 'Browser', type: 'visit' },
    { key: 'visit:os', label: 'Operating System', type: 'visit' },
    { key: 'visit:country', label: 'Country', type: 'visit' },
    { key: 'visit:region', label: 'Region', type: 'visit' },
    { key: 'visit:city', label: 'City', type: 'visit' },
    { key: 'visit:entry_page', label: 'Entry Page', type: 'visit' },
    { key: 'visit:exit_page', label: 'Exit Page', type: 'visit' },

    // Event properties
    { key: 'event:name', label: 'Event Name', type: 'event' },
    { key: 'event:page', label: 'Page', type: 'event' },
    { key: 'event:goal', label: 'Goal', type: 'event' },
    { key: 'event:hostname', label: 'Hostname', type: 'event' }
  ]
}

/**
 * Gets operators available for a given attribute type
 */
export function getOperatorsForAttribute(attribute: string): Array<{ value: string; label: string }> {
  const attributeType = attribute.split(':')[0]

  // Goal-related attributes only have has_done/has_not_done
  if (attribute === 'event:goal') {
    return [
      { value: 'has_done', label: 'has completed' },
      { value: 'has_not_done', label: 'has not completed' }
    ]
  }

  // Default operators for all other attributes
  return [
    { value: 'is', label: 'equals' },
    { value: 'is_not', label: 'does not equal' },
    { value: 'contains', label: 'contains' },
    { value: 'contains_not', label: 'does not contain' },
    { value: 'matches', label: 'matches (regex)' },
    { value: 'matches_not', label: 'does not match (regex)' },
    { value: 'matches_wildcard', label: 'matches (wildcard)' },
    { value: 'matches_wildcard_not', label: 'does not match (wildcard)' }
  ]
}
