import React, { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useSiteContext } from '../site-context'
import { get, mutation } from '../api'

type Webhook = {
  id: string
  url: string
  enabled: boolean
  trigger_types: string[]
  site_id: string
  created_at: string
  updated_at: string
}

type Delivery = {
  id: string
  event_type: string
  payload: object
  status: 'pending' | 'success' | 'failed'
  response_code: number | null
  error_message: string | null
  attempted_at: string
  completed_at: string | null
}

type WebhookFormData = {
  url: string
  enabled: boolean
  trigger_types: string[]
}

const TRIGGER_TYPES = [
  { value: 'visitor_spike', label: 'Visitor Spike' },
  { value: 'goal_completion', label: 'Goal Completion' }
]

function WebhookForm({
  webhook,
  onSave,
  onCancel
}: {
  webhook?: Webhook
  onSave: (data: WebhookFormData) => void
  onCancel: () => void
}) {
  const [url, setUrl] = useState(webhook?.url || '')
  const [enabled, setEnabled] = useState(webhook?.enabled ?? true)
  const [triggerTypes, setTriggerTypes] = useState<string[]>(
    webhook?.trigger_types || ['visitor_spike']
  )
  const [errors, setErrors] = useState<Record<string, string>>({})

  const validate = () => {
    const newErrors: Record<string, string> = {}
    if (!url) {
      newErrors.url = 'URL is required'
    } else if (!url.startsWith('https://')) {
      newErrors.url = 'URL must use HTTPS'
    }
    if (triggerTypes.length === 0) {
      newErrors.trigger_types = 'Select at least one trigger type'
    }
    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (validate()) {
      onSave({ url, enabled, trigger_types: triggerTypes })
    }
  }

  const toggleTriggerType = (type: string) => {
    if (triggerTypes.includes(type)) {
      setTriggerTypes(triggerTypes.filter((t) => t !== type))
    } else {
      setTriggerTypes([...triggerTypes, type])
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300">
          Webhook URL
        </label>
        <input
          type="url"
          value={url}
          onChange={(e) => setUrl(e.target.value)}
          placeholder="https://example.com/webhook"
          className="mt-1 block w-full rounded-md border border-gray-300 dark:border-gray-700 px-3 py-2 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500"
        />
        {errors.url && (
          <p className="mt-1 text-sm text-red-600 dark:text-red-400">
            {errors.url}
          </p>
        )}
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
          Trigger Types
        </label>
        <div className="space-y-2">
          {TRIGGER_TYPES.map((type) => (
            <label key={type.value} className="flex items-center">
              <input
                type="checkbox"
                checked={triggerTypes.includes(type.value)}
                onChange={() => toggleTriggerType(type.value)}
                className="rounded border-gray-300 dark:border-gray-700 text-indigo-600 focus:ring-indigo-500"
              />
              <span className="ml-2 text-gray-700 dark:text-gray-300">
                {type.label}
              </span>
            </label>
          ))}
        </div>
        {errors.trigger_types && (
          <p className="mt-1 text-sm text-red-600 dark:text-red-400">
            {errors.trigger_types}
          </p>
        )}
      </div>

      <div className="flex items-center">
        <input
          type="checkbox"
          id="enabled"
          checked={enabled}
          onChange={(e) => setEnabled(e.target.checked)}
          className="rounded border-gray-300 dark:border-gray-700 text-indigo-600 focus:ring-indigo-500"
        />
        <label htmlFor="enabled" className="ml-2 text-sm text-gray-700 dark:text-gray-300">
          Webhook enabled
        </label>
      </div>

      <div className="flex justify-end space-x-3">
        <button
          type="button"
          onClick={onCancel}
          className="px-4 py-2 border border-gray-300 dark:border-gray-700 rounded-md text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-800"
        >
          Cancel
        </button>
        <button
          type="submit"
          className="px-4 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700"
        >
          {webhook ? 'Update' : 'Create'} Webhook
        </button>
      </div>
    </form>
  )
}

function WebhookItem({
  webhook,
  onEdit,
  onDelete,
  onTest
}: {
  webhook: Webhook
  onEdit: () => void
  onDelete: () => void
  onTest: () => void
}) {
  return (
    <div className="border border-gray-200 dark:border-gray-700 rounded-lg p-4 bg-white dark:bg-gray-800">
      <div className="flex items-start justify-between">
        <div className="flex-1">
          <div className="flex items-center space-x-2">
            <span
              className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                webhook.enabled
                  ? 'bg-green-100 text-green-800 dark:bg-green-900/60 dark:text-green-300'
                  : 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300'
              }`}
            >
              {webhook.enabled ? 'Active' : 'Inactive'}
            </span>
          </div>
          <p className="mt-2 text-sm font-mono text-gray-900 dark:text-gray-100 break-all">
            {webhook.url}
          </p>
          <div className="mt-2 flex flex-wrap gap-2">
            {webhook.trigger_types.map((type) => (
              <span
                key={type}
                className="inline-flex items-center px-2 py-1 rounded text-xs bg-indigo-50 text-indigo-700 dark:bg-indigo-900/40 dark:text-indigo-300"
              >
                {type.replace('_', ' ')}
              </span>
            ))}
          </div>
        </div>
        <div className="flex space-x-2 ml-4">
          <button
            onClick={onTest}
            className="px-3 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700"
          >
            Test
          </button>
          <button
            onClick={onEdit}
            className="px-3 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700"
          >
            Edit
          </button>
          <button
            onClick={onDelete}
            className="px-3 py-1 text-sm border border-red-300 dark:border-red-700 rounded text-red-700 dark:text-red-300 hover:bg-red-50 dark:hover:bg-red-900/20"
          >
            Delete
          </button>
        </div>
      </div>
    </div>
  )
}

function DeliveryHistory({ webhookId }: { webhookId: string }) {
  const site = useSiteContext()
  const { data, isLoading } = useQuery({
    queryKey: ['webhook-deliveries', webhookId],
    queryFn: async () => {
      const response = await get(
        `/api/${site.domain}/webhooks/${webhookId}/deliveries`
      )
      return response as { deliveries: Delivery[] }
    }
  })

  if (isLoading) {
    return <div className="text-gray-500">Loading delivery history...</div>
  }

  const deliveries = data?.deliveries || []

  if (deliveries.length === 0) {
    return <div className="text-gray-500">No deliveries yet</div>
  }

  return (
    <div className="space-y-2">
      {deliveries.slice(0, 10).map((delivery) => (
        <div
          key={delivery.id}
          className="flex items-center justify-between text-sm p-2 bg-gray-50 dark:bg-gray-900 rounded"
        >
          <div className="flex items-center space-x-3">
            <span
              className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${
                delivery.status === 'success'
                  ? 'bg-green-100 text-green-800 dark:bg-green-900/60 dark:text-green-300'
                  : delivery.status === 'failed'
                  ? 'bg-red-100 text-red-800 dark:bg-red-900/60 dark:text-red-300'
                  : 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/60 dark:text-yellow-300'
              }`}
            >
              {delivery.status}
            </span>
            <span className="text-gray-700 dark:text-gray-300">
              {delivery.event_type}
            </span>
            {delivery.response_code && (
              <span className="text-gray-500">Code: {delivery.response_code}</span>
            )}
          </div>
          <span className="text-gray-500 text-xs">
            {new Date(delivery.attempted_at).toLocaleString()}
          </span>
        </div>
      ))}
    </div>
  )
}

export default function WebhookSettings() {
  const site = useSiteContext()
  const queryClient = useQueryClient()
  const [showForm, setShowForm] = useState(false)
  const [editingWebhook, setEditingWebhook] = useState<Webhook | null>(null)
  const [expandedWebhookId, setExpandedWebhookId] = useState<string | null>(null)

  const { data, isLoading } = useQuery({
    queryKey: ['webhooks', site.domain],
    queryFn: async () => {
      const response = await get(`/api/${site.domain}/webhooks`)
      return response as { webhooks: Webhook[] }
    }
  })

  const createMutation = useMutation({
    mutationFn: async (data: WebhookFormData) => {
      return mutation(`/api/${site.domain}/webhooks`, {
        method: 'POST',
        body: data
      })
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['webhooks', site.domain] })
      setShowForm(false)
    }
  })

  const updateMutation = useMutation({
    mutationFn: async ({ id, data }: { id: string; data: WebhookFormData }) => {
      return mutation(`/api/${site.domain}/webhooks/${id}`, {
        method: 'PUT',
        body: data
      })
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['webhooks', site.domain] })
      setEditingWebhook(null)
    }
  })

  const deleteMutation = useMutation({
    mutationFn: async (id: string) => {
      return mutation(`/api/${site.domain}/webhooks/${id}`, {
        method: 'DELETE'
      })
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['webhooks', site.domain] })
    }
  })

  const testMutation = useMutation({
    mutationFn: async (id: string) => {
      return mutation(`/api/${site.domain}/webhooks/${id}/test`, {
        method: 'POST',
        body: {}
      })
    }
  })

  const webhooks = data?.webhooks || []

  const handleSave = (formData: WebhookFormData) => {
    if (editingWebhook) {
      updateMutation.mutate({ id: editingWebhook.id, data: formData })
    } else {
      createMutation.mutate(formData)
    }
  }

  const handleDelete = (id: string) => {
    if (confirm('Are you sure you want to delete this webhook?')) {
      deleteMutation.mutate(id)
    }
  }

  const handleTest = async (id: string) => {
    try {
      const result = await testMutation.mutateAsync(id)
      alert(result.message || 'Test webhook sent')
    } catch (error: unknown) {
      const err = error as { message?: string }
      alert(err.message || 'Failed to send test webhook')
    }
  }

  if (isLoading) {
    return (
      <div className="p-6">
        <div className="animate-pulse space-y-4">
          <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-1/4"></div>
          <div className="h-20 bg-gray-200 dark:bg-gray-700 rounded"></div>
        </div>
      </div>
    )
  }

  return (
    <div className="p-6 max-w-4xl mx-auto">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100">
            Webhooks
          </h1>
          <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
            Configure HTTP endpoints to receive notifications when events occur
          </p>
        </div>
        <button
          onClick={() => setShowForm(true)}
          className="px-4 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700"
        >
          Add Webhook
        </button>
      </div>

      {showForm && (
        <div className="mb-6 p-4 border border-gray-200 dark:border-gray-700 rounded-lg bg-gray-50 dark:bg-gray-900">
          <h2 className="text-lg font-medium text-gray-900 dark:text-gray-100 mb-4">
            Create New Webhook
          </h2>
          <WebhookForm
            onSave={handleSave}
            onCancel={() => setShowForm(false)}
          />
        </div>
      )}

      {editingWebhook && (
        <div className="mb-6 p-4 border border-gray-200 dark:border-gray-700 rounded-lg bg-gray-50 dark:bg-gray-900">
          <h2 className="text-lg font-medium text-gray-900 dark:text-gray-100 mb-4">
            Edit Webhook
          </h2>
          <WebhookForm
            webhook={editingWebhook}
            onSave={handleSave}
            onCancel={() => setEditingWebhook(null)}
          />
        </div>
      )}

      {webhooks.length === 0 ? (
        <div className="text-center py-12 border-2 border-dashed border-gray-200 dark:border-gray-700 rounded-lg">
          <p className="text-gray-500 dark:text-gray-400">
            No webhooks configured yet
          </p>
          <button
            onClick={() => setShowForm(true)}
            className="mt-2 text-indigo-600 hover:text-indigo-700"
          >
            Add your first webhook
          </button>
        </div>
      ) : (
        <div className="space-y-4">
          {webhooks.map((webhook) => (
            <div key={webhook.id}>
              <WebhookItem
                webhook={webhook}
                onEdit={() => setEditingWebhook(webhook)}
                onDelete={() => handleDelete(webhook.id)}
                onTest={() => handleTest(webhook.id)}
              />
              {expandedWebhookId === webhook.id && (
                <div className="mt-2 ml-4 p-3 bg-gray-50 dark:bg-gray-900 rounded">
                  <h3 className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    Delivery History
                  </h3>
                  <DeliveryHistory webhookId={webhook.id} />
                  <button
                    onClick={() => setExpandedWebhookId(null)}
                    className="mt-2 text-sm text-gray-500 hover:text-gray-700 dark:hover:text-gray-300"
                  >
                    Hide history
                  </button>
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
