import { useState } from 'react'

interface Webhook {
  id: string
  name: string
  url: string
  enabled: boolean
  created_at: string
}

interface WebhookListProps {
  siteId: string
  webhooks: Webhook[]
  onAddWebhook: () => void
  onEditWebhook: (webhook: Webhook) => void
  onDeleteWebhook: (webhook: Webhook) => void
  onToggleWebhook: (webhook: Webhook) => void
  onTestWebhook: (webhook: Webhook) => void
}

export function WebhookList({
  webhooks,
  onAddWebhook,
  onEditWebhook,
  onDeleteWebhook,
  onToggleWebhook,
  onTestWebhook
}: WebhookListProps) {
  const [testingId, setTestingId] = useState<string | null>(null)
  const [testResult, setTestResult] = useState<{ id: string; success: boolean; message: string } | null>(null)

  const handleTest = async (webhook: Webhook) => {
    setTestingId(webhook.id)
    setTestResult(null)

    try {
      const response = await fetch(`/api/sites/${webhook.id}/webhook/test`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        }
      })

      const data = await response.json()

      setTestResult({
        id: webhook.id,
        success: response.ok,
        message: response.ok ? 'Test successful!' : data.error || 'Test failed'
      })
    } catch (error) {
      setTestResult({
        id: webhook.id,
        success: false,
        message: 'Network error'
      })
    } finally {
      setTestingId(null)
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h2 className="text-lg font-medium text-gray-900">Webhooks</h2>
        <button
          onClick={onAddWebhook}
          className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
        >
          Add Webhook
        </button>
      </div>

      {webhooks.length === 0 ? (
        <div className="text-center py-12 bg-gray-50 rounded-lg">
          <svg
            className="mx-auto h-12 w-12 text-gray-400"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1"
            />
          </svg>
          <h3 className="mt-2 text-sm font-medium text-gray-900">No webhooks configured</h3>
          <p className="mt-1 text-sm text-gray-500">Get started by adding a new webhook.</p>
        </div>
      ) : (
        <div className="space-y-4">
          {webhooks.map((webhook) => (
            <div
              key={webhook.id}
              className={`bg-white border rounded-lg p-4 ${
                webhook.enabled ? 'border-gray-200' : 'border-gray-200 opacity-60'
              }`}
            >
              <div className="flex items-center justify-between">
                <div className="flex-1 min-w-0">
                  <h3 className="text-sm font-medium text-gray-900 truncate">
                    {webhook.name}
                  </h3>
                  <p className="text-xs text-gray-500 truncate">{webhook.url}</p>
                </div>

                <div className="ml-4 flex items-center space-x-2">
                  <button
                    onClick={() => onTestWebhook(webhook)}
                    disabled={testingId === webhook.id}
                    className="inline-flex items-center px-3 py-1.5 border border-gray-300 text-xs font-medium rounded text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
                  >
                    {testingId === webhook.id ? 'Testing...' : 'Test'}
                  </button>

                  <button
                    onClick={() => onToggleWebhook(webhook)}
                    className={`inline-flex items-center px-3 py-1.5 border text-xs font-medium rounded ${
                      webhook.enabled
                        ? 'border-green-300 text-green-700 bg-green-50 hover:bg-green-100'
                        : 'border-gray-300 text-gray-700 bg-white hover:bg-gray-50'
                    }`}
                  >
                    {webhook.enabled ? 'Enabled' : 'Disabled'}
                  </button>

                  <button
                    onClick={() => onEditWebhook(webhook)}
                    className="inline-flex items-center px-3 py-1.5 border border-gray-300 text-xs font-medium rounded text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                  >
                    Edit
                  </button>

                  <button
                    onClick={() => onDeleteWebhook(webhook)}
                    className="inline-flex items-center px-3 py-1.5 border border-red-300 text-xs font-medium rounded text-red-700 bg-white hover:bg-red-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
                  >
                    Delete
                  </button>
                </div>
              </div>

              {testResult && testResult.id === webhook.id && (
                <div
                  className={`mt-3 p-2 text-xs rounded ${
                    testResult.success
                      ? 'bg-green-50 text-green-800'
                      : 'bg-red-50 text-red-800'
                  }`}
                >
                  {testResult.message}
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
