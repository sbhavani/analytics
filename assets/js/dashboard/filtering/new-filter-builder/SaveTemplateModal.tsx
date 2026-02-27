import React, { useState } from 'react'
import { useFilterBuilder } from './FilterBuilderContext'

interface SaveTemplateModalProps {
  isOpen: boolean
  onClose: () => void
  onSave: (name: string, filterTree: any) => Promise<void>
}

export function SaveTemplateModal({ isOpen, onClose, onSave }: SaveTemplateModalProps) {
  const { state, getFilterTree, clearAll } = useFilterBuilder()
  const [name, setName] = useState('')
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)

  if (!isOpen) return null

  const handleSave = async () => {
    if (!name.trim()) {
      setError('Please enter a name')
      return
    }

    setSaving(true)
    setError(null)

    try {
      const filterTree = getFilterTree()
      await onSave(name.trim(), filterTree)
      clearAll()
      setName('')
      onClose()
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to save segment')
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="modal-overlay" data-testid="save-template-modal">
      <div className="modal">
        <div className="modal__header">
          <h3>Save as Segment</h3>
          <button type="button" className="modal__close" onClick={onClose}>
            ×
          </button>
        </div>

        <div className="modal__body">
          <div className="form-group">
            <label htmlFor="segment-name">Segment Name</label>
            <input
              id="segment-name"
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g., Mobile US Visitors"
              disabled={saving}
            />
          </div>

          {error && (
            <div className="error-message" data-testid="save-error">
              {error}
            </div>
          )}
        </div>

        <div className="modal__footer">
          <button
            type="button"
            className="btn btn--secondary"
            onClick={onClose}
            disabled={saving}
          >
            Cancel
          </button>
          <button
            type="button"
            className="btn btn--primary"
            onClick={handleSave}
            disabled={saving || !state.isValid}
          >
            {saving ? 'Saving...' : 'Save'}
          </button>
        </div>
      </div>
    </div>
  )
}
