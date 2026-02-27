import React, { useState, useEffect } from 'react'
import { FilterTemplate } from '../lib/filterBuilder/types'
import * as templateLoader from '../lib/filterBuilder/templateLoader'

interface TemplateListProps {
  siteId: string
  onSelect: (template: FilterTemplate) => void
  onDelete?: (templateId: string) => void
}

export function TemplateList({ siteId, onSelect, onDelete }: TemplateListProps) {
  const [templates, setTemplates] = useState<FilterTemplate[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!siteId) return

    setLoading(true)
    templateLoader
      .listTemplates(siteId)
      .then(setTemplates)
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false))
  }, [siteId])

  const handleDelete = async (templateId: string, e: React.MouseEvent) => {
    e.stopPropagation()
    if (!confirm('Are you sure you want to delete this template?')) return

    try {
      await templateLoader.deleteTemplate(siteId, templateId)
      setTemplates((prev) => prev.filter((t) => t.id !== templateId))
      onDelete?.(templateId)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete template')
    }
  }

  if (loading) {
    return (
      <div className="p-4 text-center text-gray-500 dark:text-gray-400">
        Loading templates...
      </div>
    )
  }

  if (error) {
    return (
      <div className="p-4 text-red-500">
        Error: {error}
      </div>
    )
  }

  if (templates.length === 0) {
    return (
      <div className="p-4 text-center text-gray-500 dark:text-gray-400">
        No saved templates yet.
      </div>
    )
  }

  return (
    <div className="space-y-2 max-h-64 overflow-y-auto">
      {templates.map((template) => (
        <div
          key={template.id}
          onClick={() => onSelect(template)}
          className="flex items-center justify-between p-3 bg-white border border-gray-200 rounded-lg cursor-pointer hover:border-indigo-300 dark:bg-gray-800 dark:border-gray-700 dark:hover:border-indigo-600 transition-colors"
        >
          <div>
            <div className="font-medium text-gray-900 dark:text-gray-100">
              {template.name}
            </div>
            <div className="text-xs text-gray-500 dark:text-gray-400">
              {template.filter_tree.rootGroup.conditions.length} condition
              {template.filter_tree.rootGroup.conditions.length !== 1 ? 's' : ''}
            </div>
          </div>

          {onDelete && (
            <button
              onClick={(e) => handleDelete(template.id, e)}
              className="p-1 text-gray-400 hover:text-red-500 transition-colors"
              title="Delete template"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                className="w-4 h-4"
                viewBox="0 0 20 20"
                fill="currentColor"
              >
                <path
                  fillRule="evenodd"
                  d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z"
                  clipRule="evenodd"
                />
              </svg>
            </button>
          )}
        </div>
      ))}
    </div>
  )
}
