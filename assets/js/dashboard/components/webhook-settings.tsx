import { useState, useEffect } from 'react'
import { webhooks, Webhook, Trigger, Delivery } from '../api'

interface WebhookSettingsProps {
  siteId: string
}

export function WebhookSettings({ siteId }: WebhookSettingsProps) {
  const [webhookList, setWebhookList] = useState<Webhook[]>([])
  const [selectedWebhook, setSelectedWebhook] = useState<Webhook | null>(null)
  const [isCreating, setIsCreating] = useState(false)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    loadWebhooks()
  }, [siteId])

  const loadWebhooks = async () => {
    try {
      setIsLoading(true)
      const { webhooks: list } = await webhooks.list(siteId)
      setWebhookList(list)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load webhooks')
    } finally {
      setIsLoading(false)
    }
  }

  const handleCreateWebhook = async (data: {
    url: string
    name: string
    secret?: string
    triggers: { type: string; threshold?: number; goal_id?: string }[]
  }) => {
    try {
      const { webhook } = await webhooks.create(siteId, data)
      setWebhookList([...webhookList, webhook])
      setSelectedWebhook(webhook)
      setIsCreating(false)
    } catch (err) {
      throw err
    }
  }

  const handleUpdateWebhook = async (webhookId: string, data: {
    url?: string
    name?: string
    secret?: string
    active?: boolean
  }) => {
    try {
      const { webhook } = await webhooks.update(siteId, webhookId, data)
      setWebhookList(webhookList.map(w => w.id === webhookId ? webhook : w))
      setSelectedWebhook(webhook)
    } catch (err) {
      throw err
    }
  }

  const handleDeleteWebhook = async (webhookId: string) => {
    try {
      await webhooks.delete(siteId, webhookId)
      setWebhookList(webhookList.filter(w => w.id !== webhookId))
      if (selectedWebhook?.id === webhookId) {
        setSelectedWebhook(null)
      }
    } catch (err) {
      throw err
    }
  }

  const handleToggleActive = async (webhook: Webhook) => {
    await handleUpdateWebhook(webhook.id, { active: !webhook.active })
  }

  if (isLoading) {
    return <div className="loading">Loading webhooks...</div>
  }

  return (
    <div className="webhook-settings">
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-lg font-medium">Webhooks</h2>
        <button
          onClick={() => setIsCreating(true)}
          className="px-4 py-2 bg-gray-900 text-white rounded-md hover:bg-gray-800"
        >
          Add Webhook
        </button>
      </div>

      {error && (
        <div className="mb-4 p-3 bg-red-50 text-red-700 rounded-md">
          {error}
        </div>
      )}

      {isCreating && (
        <WebhookForm
          onSubmit={handleCreateWebhook}
          onCancel={() => setIsCreating(false)}
        />
      )}

      {webhookList.length === 0 && !isCreating ? (
        <div className="text-gray-500 text-center py-8">
          No webhooks configured. Add one to get started.
        </div>
      ) : (
        <div className="space-y-4">
          {webhookList.map(webhook => (
            <WebhookCard
              key={webhook.id}
              webhook={webhook}
              isSelected={selectedWebhook?.id === webhook.id}
              onSelect={() => setSelectedWebhook(webhook)}
              onToggleActive={() => handleToggleActive(webhook)}
              onDelete={() => handleDeleteWebhook(webhook.id)}
              onUpdate={(data) => handleUpdateWebhook(webhook.id, data)}
            />
          ))}
        </div>
      )}

      {selectedWebhook && !isCreating && (
        <WebhookDetail
          webhook={selectedWebhook}
          siteId={siteId}
          onClose={() => setSelectedWebhook(null)}
        />
      )}
    </div>
  )
}

interface WebhookFormProps {
  onSubmit: (data: {
    url: string
    name: string
    secret?: string
    triggers: { type: string; threshold?: number; goal_id?: string }[]
  }) => Promise<void>
  onCancel: () => void
  initialData?: Webhook
}

function WebhookForm({ onSubmit, onCancel, initialData }: WebhookFormProps) {
  const [url, setUrl] = useState(initialData?.url || '')
  const [name, setName] = useState(initialData?.name || '')
  const [secret, setSecret] = useState('')
  const [triggers, setTriggers] = useState<{ type: string; threshold?: number }[]>([])
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const handleAddTrigger = () => {
    setTriggers([...triggers, { type: 'visitor_spike' }])
  }

  const handleRemoveTrigger = (index: number) => {
    setTriggers(triggers.filter((_, i) => i !== index))
  }

  const handleTriggerChange = (index: number, field: string, value: string | number) => {
    const newTriggers = [...triggers]
    newTriggers[index] = { ...newTriggers[index], [field]: value }
    setTriggers(newTriggers)
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsSubmitting(true)
    setError(null)

    try {
      await onSubmit({
        url,
        name,
        secret: secret || undefined,
        triggers
      })
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save webhook')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} className="bg-white p-6 rounded-lg shadow mb-6">
      <h3 className="text-lg font-medium mb-4">
        {initialData ? 'Edit Webhook' : 'Create Webhook'}
      </h3>

      {error && (
        <div className="mb-4 p-3 bg-red-50 text-red-700 rounded-md">
          {error}
        </div>
      )}

      <div className="space-y-4">
        <div>
          <label className="block text-sm font-medium mb-1">Name</label>
          <input
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            className="w-full px-3 py-2 border rounded-md"
            required
            placeholder="My Webhook"
          />
        </div>

        <div>
          <label className="block text-sm font-medium mb-1">URL</label>
          <input
            type="url"
            value={url}
            onChange={(e) => setUrl(e.target.value)}
            className="w-full px-3 py-2 border rounded-md"
            required
            placeholder="https://example.com/webhook"
          />
          <p className="text-xs text-gray-500 mt-1">Must be HTTPS</p>
        </div>

        <div>
          <label className="block text-sm font-medium mb-1">Secret (optional)</label>
          <input
            type="password"
            value={secret}
            onChange={(e) => setSecret(e.target.value)}
            className="w-full px-3 py-2 border rounded-md"
            placeholder="Minimum 16 characters"
          />
          <p className="text-xs text-gray-500 mt-1">Used for HMAC signature verification</p>
        </div>

        <div>
          <label className="block text-sm font-medium mb-2">Triggers</label>
          {triggers.map((trigger, index) => (
            <div key={index} className="flex gap-2 mb-2 items-start">
              <select
                value={trigger.type}
                onChange={(e) => handleTriggerChange(index, 'type', e.target.value)}
                className="px-3 py-2 border rounded-md"
              >
                <option value="visitor_spike">Visitor Spike</option>
                <option value="goal_completion">Goal Completion</option>
              </select>
              {trigger.type === 'visitor_spike' && (
                <input
                  type="number"
                  value={trigger.threshold || ''}
                  onChange={(e) => handleTriggerChange(index, 'threshold', parseInt(e.target.value))}
                  className="w-24 px-3 py-2 border rounded-md"
                  placeholder="50"
                  min="1"
                  max="10000"
                />
              )}
              <button
                type="button"
                onClick={() => handleRemoveTrigger(index)}
                className="text-red-600 hover:text-red-800"
              >
                Remove
              </button>
            </div>
          ))}
          <button
            type="button"
            onClick={handleAddTrigger}
            className="text-sm text-blue-600 hover:text-blue-800"
          >
            + Add Trigger
          </button>
        </div>
      </div>

      <div className="flex justify-end gap-2 mt-6">
        <button
          type="button"
          onClick={onCancel}
          className="px-4 py-2 border rounded-md hover:bg-gray-50"
        >
          Cancel
        </button>
        <button
          type="submit"
          disabled={isSubmitting}
          className="px-4 py-2 bg-gray-900 text-white rounded-md hover:bg-gray-800 disabled:opacity-50"
        >
          {isSubmitting ? 'Saving...' : 'Save Webhook'}
        </button>
      </div>
    </form>
  )
}

interface WebhookCardProps {
  webhook: Webhook
  isSelected: boolean
  onSelect: () => void
  onToggleActive: () => void
  onDelete: () => void
  onUpdate: (data: { url?: string; name?: string; secret?: string; active?: boolean }) => Promise<void>
}

function WebhookCard({ webhook, isSelected, onSelect, onToggleActive, onDelete, onUpdate }: WebhookCardProps) {
  const [isEditing, setIsEditing] = useState(false)
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false)

  return (
    <div
      className={`border rounded-lg p-4 cursor-pointer ${isSelected ? 'border-gray-900' : 'border-gray-200'}`}
      onClick={onSelect}
    >
      <div className="flex justify-between items-start">
        <div>
          <h4 className="font-medium">{webhook.name}</h4>
          <p className="text-sm text-gray-500">{webhook.url}</p>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={(e) => { e.stopPropagation(); onToggleActive() }}
            className={`px-2 py-1 text-xs rounded ${webhook.active ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-600'}`}
          >
            {webhook.active ? 'Active' : 'Paused'}
          </button>
          <button
            onClick={(e) => { e.stopPropagation(); setIsEditing(true) }}
            className="text-gray-500 hover:text-gray-700"
          >
            Edit
          </button>
          <button
            onClick={(e) => { e.stopPropagation(); setShowDeleteConfirm(true) }}
            className="text-red-500 hover:text-red-700"
          >
            Delete
          </button>
        </div>
      </div>

      <div className="mt-2 flex gap-2">
        {webhook.triggers.map(trigger => (
          <span key={trigger.id} className="text-xs bg-gray-100 px-2 py-1 rounded">
            {trigger.type === 'visitor_spike' ? `Spike: ${trigger.threshold}%` : 'Goal Completion'}
          </span>
        ))}
      </div>

      {isEditing && (
        <WebhookForm
          initialData={webhook}
          onSubmit={async (data) => { await onUpdate(data); setIsEditing(false) }}
          onCancel={() => setIsEditing(false)}
        />
      )}

      {showDeleteConfirm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white p-6 rounded-lg max-w-md">
            <h4 className="text-lg font-medium mb-2">Delete Webhook?</h4>
            <p className="text-gray-600 mb-4">This will permanently delete "{webhook.name}" and all its delivery history.</p>
            <div className="flex justify-end gap-2">
              <button
                onClick={() => setShowDeleteConfirm(false)}
                className="px-4 py-2 border rounded-md hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={() => { onDelete(); setShowDeleteConfirm(false) }}
                className="px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700"
              >
                Delete
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

interface WebhookDetailProps {
  webhook: Webhook
  siteId: string
  onClose: () => void
}

function WebhookDetail({ webhook, siteId, onClose }: WebhookDetailProps) {
  const [deliveries, setDeliveries] = useState<Delivery[]>([])
  const [pagination, setPagination] = useState({ page: 1, limit: 20, total_pages: 0, total_count: 0 })
  const [isLoading, setIsLoading] = useState(true)
  const [activeTab, setActiveTab] = useState<'history' | 'settings'>('history')

  useEffect(() => {
    loadDeliveries()
  }, [siteId, webhook.id, pagination.page])

  const loadDeliveries = async () => {
    try {
      setIsLoading(true)
      const { deliveries: list, pagination: p } = await webhooks.getDeliveries(
        siteId,
        webhook.id,
        pagination.page,
        pagination.limit
      )
      setDeliveries(list)
      setPagination(p)
    } catch (err) {
      console.error('Failed to load deliveries:', err)
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="mt-6 border-t pt-6">
      <div className="flex justify-between items-center mb-4">
        <h3 className="text-lg font-medium">{webhook.name} - Details</h3>
        <button onClick={onClose} className="text-gray-500 hover:text-gray-700">
          Close
        </button>
      </div>

      <div className="flex gap-4 mb-4">
        <button
          onClick={() => setActiveTab('history')}
          className={`pb-2 ${activeTab === 'history' ? 'border-b-2 border-gray-900 font-medium' : 'text-gray-500'}`}
        >
          Delivery History
        </button>
        <button
          onClick={() => setActiveTab('settings')}
          className={`pb-2 ${activeTab === 'settings' ? 'border-b-2 border-gray-900 font-medium' : 'text-gray-500'}`}
        >
          Settings
        </button>
      </div>

      {activeTab === 'history' && (
        <div>
          {isLoading ? (
            <div className="text-center py-4">Loading...</div>
          ) : deliveries.length === 0 ? (
            <div className="text-center py-4 text-gray-500">No deliveries yet</div>
          ) : (
            <>
              <table className="w-full">
                <thead>
                  <tr className="text-left text-sm text-gray-500">
                    <th className="pb-2">Time</th>
                    <th className="pb-2">Status</th>
                    <th className="pb-2">Response</th>
                    <th className="pb-2">Attempt</th>
                  </tr>
                </thead>
                <tbody>
                  {deliveries.map(delivery => (
                    <tr key={delivery.id} className="border-t">
                      <td className="py-2 text-sm">
                        {new Date(delivery.inserted_at).toLocaleString()}
                      </td>
                      <td className="py-2">
                        <span className={`text-xs px-2 py-1 rounded ${
                          delivery.status === 'success' ? 'bg-green-100 text-green-800' :
                          delivery.status === 'failed' ? 'bg-red-100 text-red-800' :
                          delivery.status === 'retrying' ? 'bg-yellow-100 text-yellow-800' :
                          'bg-gray-100 text-gray-800'
                        }`}>
                          {delivery.status}
                        </span>
                      </td>
                      <td className="py-2 text-sm">
                        {delivery.response_code || '-'}
                        {delivery.error_message && <span className="text-red-500 ml-1">({delivery.error_message})</span>}
                      </td>
                      <td className="py-2 text-sm">{delivery.attempt}</td>
                    </tr>
                  ))}
                </tbody>
              </table>

              {pagination.total_pages > 1 && (
                <div className="flex justify-center gap-2 mt-4">
                  <button
                    onClick={() => setPagination(p => ({ ...p, page: p.page - 1 }))}
                    disabled={pagination.page <= 1}
                    className="px-3 py-1 border rounded disabled:opacity-50"
                  >
                    Previous
                  </button>
                  <span className="px-3 py-1">
                    Page {pagination.page} of {pagination.total_pages}
                  </span>
                  <button
                    onClick={() => setPagination(p => ({ ...p, page: p.page + 1 }))}
                    disabled={pagination.page >= pagination.total_pages}
                    className="px-3 py-1 border rounded disabled:opacity-50"
                  >
                    Next
                  </button>
                </div>
              )}
            </>
          )}
        </div>
      )}

      {activeTab === 'settings' && (
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1">URL</label>
            <div className="text-sm">{webhook.url}</div>
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Status</label>
            <div className="text-sm">{webhook.active ? 'Active' : 'Paused'}</div>
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Triggers</label>
            <div className="space-y-1">
              {webhook.triggers.map(trigger => (
                <div key={trigger.id} className="text-sm">
                  {trigger.type === 'visitor_spike' ? `Visitor Spike: ${trigger.threshold}%` : 'Goal Completion'}
                </div>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
