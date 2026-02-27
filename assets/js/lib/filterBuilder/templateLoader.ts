import { FilterTemplate, FilterTree } from './types'

const API_BASE = '/api/v1/sites'

export async function listTemplates(siteId: string): Promise<FilterTemplate[]> {
  const response = await fetch(`${API_BASE}/${siteId}/filter-templates`, {
    headers: {
      'Content-Type': 'application/json',
    },
  })

  if (!response.ok) {
    throw new Error(`Failed to list templates: ${response.statusText}`)
  }

  const data = await response.json()
  return data.data || []
}

export async function getTemplate(siteId: string, templateId: string): Promise<FilterTemplate> {
  const response = await fetch(`${API_BASE}/${siteId}/filter-templates/${templateId}`, {
    headers: {
      'Content-Type': 'application/json',
    },
  })

  if (!response.ok) {
    throw new Error(`Failed to get template: ${response.statusText}`)
  }

  const data = await response.json()
  return data.data
}

export async function createTemplate(
  siteId: string,
  name: string,
  filterTree: FilterTree
): Promise<FilterTemplate> {
  const response = await fetch(`${API_BASE}/${siteId}/filter-templates`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      name,
      filter_tree: filterTree,
    }),
  })

  if (!response.ok) {
    const error = await response.json().catch(() => ({}))
    throw new Error(error.message || `Failed to create template: ${response.statusText}`)
  }

  const data = await response.json()
  return data.data
}

export async function updateTemplate(
  siteId: string,
  templateId: string,
  updates: { name?: string; filter_tree?: FilterTree }
): Promise<FilterTemplate> {
  const response = await fetch(`${API_BASE}/${siteId}/filter-templates/${templateId}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(updates),
  })

  if (!response.ok) {
    const error = await response.json().catch(() => ({}))
    throw new Error(error.message || `Failed to update template: ${response.statusText}`)
  }

  const data = await response.json()
  return data.data
}

export async function deleteTemplate(siteId: string, templateId: string): Promise<void> {
  const response = await fetch(`${API_BASE}/${siteId}/filter-templates/${templateId}`, {
    method: 'DELETE',
    headers: {
      'Content-Type': 'application/json',
    },
  })

  if (!response.ok) {
    throw new Error(`Failed to delete template: ${response.statusText}`)
  }
}
