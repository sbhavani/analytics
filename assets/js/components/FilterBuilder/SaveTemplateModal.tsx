import React, { useState } from 'react'
import { FilterTree } from '../lib/filterBuilder/types'
import * as templateLoader from '../lib/filterBuilder/templateLoader'

interface SaveTemplateModalProps {
  siteId: string
  filterTree: FilterTree
  onClose: () => void
  onSave: (template: { id: string; name: string }) => void
}

export function SaveTemplateModal({
  siteId,
  filterTree,
  onClose,
  onSave,
}: SaveTemplateModalProps) {
  const [templateName, setTemplateName] = useState('')
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const handleSave = async () => {
    if (!templateName.trim()) return

    setSaving(true)
    setError(null)
    try {
      const template = await templateLoader.createTemplate(siteId, templateName, filterTree)
      onSave({ id: template.id, name: template.name })
      onClose()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save template')
    } finally {
      setSaving(false)
    }
  }

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && templateName.trim() && !saving) {
      handleSave()
    }
    if (e.key === 'Escape') {
      onClose()
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50" onClick={onClose}>
      <div
        className="bg-white dark:bg-gray-800 rounded-lg shadow-xl p-6 w-full max-w-md"
        onClick={(e) => e.stopPropagation()}
      >
        <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4">
          Save Filter Template
        </h3>

        <input
          type="text"
          value={templateName}
          onChange={(e) => setTemplateName(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder="Template name..."
          className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-1 focus:ring-indigo-500 dark:bg-gray-700 dark:border-gray-600 dark:text-gray-100"
          autoFocus
        />

        {error && (
          <p className="mt-2 text-sm text-red-600 dark:text-red-400">
            {error}
          </p>
        )}

        <div className="flex justify-end gap-2 mt-4">
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 text-sm text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 dark:bg-gray-700 dark:text-gray-300 dark:border-gray-600 dark:hover:bg-gray-600"
          >
            Cancel
          </button>
          <button
            type="button"
            onClick={handleSave}
            disabled={!templateName.trim() || saving}
            className="px-4 py-2 text-sm text-white bg-indigo-600 rounded-md hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {saving ? 'Saving...' : 'Save'}
          </button>
        </div>
      </div>
    </div>
  )
}
