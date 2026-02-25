import React from 'react'

interface SaveSegmentDialogProps {
  isOpen: boolean
  onClose: () => void
  onSave: (name: string, type: 'personal' | 'site') => void
  initialName?: string
  isSaving?: boolean
}

export function SaveSegmentDialog({ isOpen, onClose, onSave, initialName = '', isSaving = false }: SaveSegmentDialogProps) {
  const [name, setName] = React.useState(initialName)
  const [type, setType] = React.useState<'personal' | 'site'>('personal')

  React.useEffect(() => {
    if (isOpen) {
      setName(initialName)
    }
  }, [isOpen, initialName])

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (name.trim()) {
      onSave(name.trim(), type)
    }
  }

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex items-center justify-center min-h-screen px-4 pt-4 pb-20 text-center sm:block sm:p-0">
        {/* Background overlay */}
        <div className="fixed inset-0 transition-opacity bg-gray-500 bg-opacity-75" onClick={onClose}></div>

        {/* Dialog */}
        <div className="inline-block align-bottom bg-white rounded-lg px-4 pt-5 pb-4 text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full sm:p-6">
          <form onSubmit={handleSubmit}>
            <div className="sm:flex sm:items-start">
              <div className="mt-3 text-center sm:mt-0 sm:text-left w-full">
                <h3 className="text-lg leading-6 font-medium text-gray-900">
                  Save Segment
                </h3>
                <div className="mt-4 space-y-4">
                  {/* Segment name */}
                  <div>
                    <label htmlFor="segment-name" className="block text-sm font-medium text-gray-700">
                      Segment Name
                    </label>
                    <input
                      type="text"
                      id="segment-name"
                      value={name}
                      onChange={(e) => setName(e.target.value)}
                      placeholder="e.g., US Mobile Users"
                      className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                      autoFocus
                    />
                  </div>

                  {/* Segment type */}
                  <div>
                    <label className="block text-sm font-medium text-gray-700">
                      Segment Type
                    </label>
                    <div className="mt-2 space-y-2">
                      <label className="inline-flex items-center">
                        <input
                          type="radio"
                          name="segment-type"
                          value="personal"
                          checked={type === 'personal'}
                          onChange={() => setType('personal')}
                          className="form-radio h-4 w-4 text-indigo-600 border-gray-300 focus:ring-indigo-500"
                        />
                        <span className="ml-2 text-sm text-gray-700">
                          Personal - Only you can see this segment
                        </span>
                      </label>
                      <label className="inline-flex items-center">
                        <input
                          type="radio"
                          name="segment-type"
                          value="site"
                          checked={type === 'site'}
                          onChange={() => setType('site')}
                          className="form-radio h-4 w-4 text-indigo-600 border-gray-300 focus:ring-indigo-500"
                        />
                        <span className="ml-2 text-sm text-gray-700">
                          Site - Everyone with access can see this segment
                        </span>
                      </label>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div className="mt-5 sm:mt-4 sm:flex sm:flex-row-reverse">
              <button
                type="submit"
                disabled={!name.trim() || isSaving}
                className="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-indigo-600 text-base font-medium text-white hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:ml-3 sm:w-auto sm:text-sm disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isSaving ? 'Saving...' : 'Save Segment'}
              </button>
              <button
                type="button"
                onClick={onClose}
                className="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:w-auto sm:text-sm"
              >
                Cancel
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  )
}

export default SaveSegmentDialog
