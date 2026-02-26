import { useState } from 'react'

interface TriggerFormProps {
  webhookId: string
  trigger?: {
    id: string
    trigger_type: 'visitor_spike' | 'goal_completion'
    threshold?: number
    goal_id?: string
    enabled: boolean
  }
  goals: Array<{ id: string; name: string }>
  onSubmit: (data: TriggerFormData) => void
  onCancel: () => void
}

interface TriggerFormData {
  trigger_type: 'visitor_spike' | 'goal_completion'
  threshold?: number
  goal_id?: string
  enabled: boolean
}

export function TriggerForm({
  trigger,
  goals,
  onSubmit,
  onCancel
}: TriggerFormProps) {
  const [formData, setFormData] = useState<TriggerFormData>({
    trigger_type: trigger?.trigger_type || 'visitor_spike',
    threshold: trigger?.threshold || 100,
    goal_id: trigger?.goal_id,
    enabled: trigger?.enabled ?? true
  })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    onSubmit(formData)
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <label htmlFor="trigger_type" className="block text-sm font-medium text-gray-700">
          Trigger Type
        </label>
        <select
          id="trigger_type"
          value={formData.trigger_type}
          onChange={(e) =>
            setFormData({ ...formData, trigger_type: e.target.value as any })
          }
          className="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
        >
          <option value="visitor_spike">Visitor Spike</option>
          <option value="goal_completion">Goal Completion</option>
        </select>
      </div>

      {formData.trigger_type === 'visitor_spike' && (
        <div>
          <label htmlFor="threshold" className="block text-sm font-medium text-gray-700">
            Threshold (visitors)
          </label>
          <input
            type="number"
            id="threshold"
            min="1"
            value={formData.threshold}
            onChange={(e) =>
              setFormData({ ...formData, threshold: parseInt(e.target.value) || 0 })
            }
            className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
          />
          <p className="mt-1 text-xs text-gray-500">
            Trigger when current visitors exceed this threshold
          </p>
        </div>
      )}

      {formData.trigger_type === 'goal_completion' && (
        <div>
          <label htmlFor="goal_id" className="block text-sm font-medium text-gray-700">
            Goal
          </label>
          <select
            id="goal_id"
            value={formData.goal_id || ''}
            onChange={(e) => setFormData({ ...formData, goal_id: e.target.value })}
            className="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
          >
            <option value="">Select a goal</option>
            {goals.map((goal) => (
              <option key={goal.id} value={goal.id}>
                {goal.name}
              </option>
            ))}
          </select>
        </div>
      )}

      <div className="flex items-center">
        <input
          id="enabled"
          type="checkbox"
          checked={formData.enabled}
          onChange={(e) => setFormData({ ...formData, enabled: e.target.checked })}
          className="h-4 w-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500"
        />
        <label htmlFor="enabled" className="ml-2 block text-sm text-gray-900">
          Enable this trigger
        </label>
      </div>

      <div className="flex justify-end space-x-3 pt-4">
        <button
          type="button"
          onClick={onCancel}
          className="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
        >
          Cancel
        </button>
        <button
          type="submit"
          className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
        >
          {trigger ? 'Update Trigger' : 'Add Trigger'}
        </button>
      </div>
    </form>
  )
}
