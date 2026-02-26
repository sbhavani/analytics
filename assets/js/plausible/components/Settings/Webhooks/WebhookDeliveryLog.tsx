interface WebhookDelivery {
  id: string
  trigger_id: string
  status_code: number | null
  success: boolean
  error_message: string | null
  attempt: number
  inserted_at: string
}

interface WebhookDeliveryLogProps {
  deliveries: WebhookDelivery[]
}

export function WebhookDeliveryLog({ deliveries }: WebhookDeliveryLogProps) {
  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleString()
  }

  if (deliveries.length === 0) {
    return (
      <div className="text-center py-8 text-gray-500">
        No delivery history yet
      </div>
    )
  }

  return (
    <div className="overflow-hidden shadow ring-1 ring-black ring-opacity-5 md:rounded-lg">
      <table className="min-w-full divide-y divide-gray-300">
        <thead className="bg-gray-50">
          <tr>
            <th className="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-6">
              Time
            </th>
            <th className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
              Status
            </th>
            <th className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
              Attempt
            </th>
            <th className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
              Error
            </th>
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-200 bg-white">
          {deliveries.map((delivery) => (
            <tr key={delivery.id}>
              <td className="whitespace-nowrap py-4 pl-4 pr-3 text-sm text-gray-900 sm:pl-6">
                {formatDate(delivery.inserted_at)}
              </td>
              <td className="whitespace-nowrap px-3 py-4 text-sm">
                {delivery.success ? (
                  <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                    {delivery.status_code || 'Success'}
                  </span>
                ) : (
                  <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
                    {delivery.status_code || 'Failed'}
                  </span>
                )}
              </td>
              <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                {delivery.attempt}
              </td>
              <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                {delivery.error_message || '-'}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
