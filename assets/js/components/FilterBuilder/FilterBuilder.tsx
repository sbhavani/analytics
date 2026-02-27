import React, { useState, useEffect } from 'react'
import { FilterTree } from '../lib/filterBuilder/types'
import { useFilterState } from '../lib/filterBuilder/useFilterState'
import { usePreview } from '../lib/filterBuilder/usePreview'
import { FilterGroup } from './FilterGroup'
import { PreviewPanel } from './PreviewPanel'
import { TemplateList } from './TemplateList'
import { SaveTemplateModal } from './SaveTemplateModal'
import * as templateLoader from '../lib/filterBuilder/templateLoader'

interface FilterBuilderProps {
  siteId: string
  initialTree?: FilterTree
  onSave?: (tree: FilterTree) => void
  onApply?: (tree: FilterTree) => void
  showPreview?: boolean
  showTemplates?: boolean
}

export function FilterBuilder({
  siteId,
  initialTree,
  onSave,
  onApply,
  showPreview = true,
  showTemplates = true,
}: FilterBuilderProps) {
  const {
    tree,
    isDirty,
    isValid,
    errors,
    addCondition,
    updateCondition,
    removeCondition,
    changeConnector,
    createGroup,
    ungroup,
    loadTree,
    resetTree,
  } = useFilterState(initialTree)

  const [showTemplateList, setShowTemplateList] = useState(false)
  const [showSaveModal, setShowSaveModal] = useState(false)

  const { result, loading, error, updateTree } = usePreview({
    siteId,
    debounceMs: 500,
  })

  useEffect(() => {
    if (showPreview) {
      updateTree(tree)
    }
  }, [tree, showPreview, updateTree])

  const handleSave = () => {
    onSave?.(tree)
  }

  const handleApply = () => {
    if (isValid) {
      onApply?.(tree)
    }
  }

  const handleLoadTemplate = (template: { filter_tree: FilterTree }) => {
    loadTree(template.filter_tree)
    setShowTemplateList(false)
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold text-gray-900 dark:text-gray-100">
          Filter Builder
        </h2>

        <div className="flex items-center gap-2">
          {showTemplates && (
            <>
              <button
                type="button"
                onClick={() => setShowTemplateList(!showTemplateList)}
                className="px-3 py-1.5 text-sm text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 dark:bg-gray-800 dark:text-gray-300 dark:border-gray-600 dark:hover:bg-gray-700"
              >
                Load Template
              </button>

              <button
                type="button"
                onClick={() => setShowSaveModal(true)}
                disabled={!isValid || !isDirty}
                className="px-3 py-1.5 text-sm text-white bg-indigo-600 rounded-md hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Save as Template
              </button>
            </>
          )}

          {onApply && (
            <button
              type="button"
              onClick={handleApply}
              disabled={!isValid}
              className="px-3 py-1.5 text-sm text-white bg-green-600 rounded-md hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Apply Filter
            </button>
          )}
        </div>
      </div>

      {showTemplateList && (
        <div className="p-4 bg-gray-50 rounded-lg dark:bg-gray-900">
          <h3 className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">
            Saved Templates
          </h3>
          <TemplateList siteId={siteId} onSelect={handleLoadTemplate} />
        </div>
      )}

      {errors.length > 0 && (
        <div className="p-3 bg-red-50 border border-red-200 rounded-lg dark:bg-red-900/20 dark:border-red-800">
          {errors.map((err, i) => (
            <p key={i} className="text-sm text-red-600 dark:text-red-400">
              {err}
            </p>
          ))}
        </div>
      )}

      <FilterGroup
        group={tree.rootGroup}
        onUpdateCondition={updateCondition}
        onRemoveCondition={removeCondition}
        onChangeConnector={(connector) => changeConnector(tree.rootGroup.id, connector)}
        onAddCondition={() => addCondition()}
        onCreateGroup={createGroup}
        onUngroup={ungroup}
        isRoot={true}
      />

      {showPreview && (
        <div className="mt-4">
          <h3 className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Preview
          </h3>
          <PreviewPanel result={result} loading={loading} error={error} />
        </div>
      )}

      {showSaveModal && (
        <SaveTemplateModal
          siteId={siteId}
          filterTree={tree}
          onClose={() => setShowSaveModal(false)}
          onSave={handleSave}
        />
      )}
    </div>
  )
}
