import { DashboardState } from './dashboard-state'
import { formatISO } from './util/date'
import { serializeApiFilters } from './util/filters'

let abortController = new AbortController()
let SHARED_LINK_AUTH: null | string = null

export class ApiError extends Error {
  payload: unknown
  constructor(message: string, payload: unknown) {
    super(message)
    this.name = 'ApiError'
    this.payload = payload
  }
}

function serializeUrlParams(params: Record<string, string | boolean | number>) {
  const str: string[] = []
  for (const p in params)
    if (params.hasOwnProperty(p)) {
      str.push(`${encodeURIComponent(p)}=${encodeURIComponent(params[p])}`)
    }
  return str.join('&')
}

export function setSharedLinkAuth(auth: string) {
  SHARED_LINK_AUTH = auth
}

export function cancelAll() {
  abortController.abort()
  abortController = new AbortController()
}

export function dashboardStateToSearchParams(
  dashboardState: DashboardState,
  extraQuery: unknown[] = []
): string {
  const queryObj: Record<string, string> = {}
  if (dashboardState.period) {
    queryObj.period = dashboardState.period
  }
  if (dashboardState.date) {
    queryObj.date = formatISO(dashboardState.date)
  }
  if (dashboardState.from) {
    queryObj.from = formatISO(dashboardState.from)
  }
  if (dashboardState.to) {
    queryObj.to = formatISO(dashboardState.to)
  }
  if (dashboardState.filters) {
    queryObj.filters = serializeApiFilters(dashboardState.filters)
  }
  if (dashboardState.with_imported) {
    queryObj.with_imported = String(dashboardState.with_imported)
  }

  if (dashboardState.comparison) {
    queryObj.comparison = dashboardState.comparison
    queryObj.compare_from = dashboardState.compare_from
      ? formatISO(dashboardState.compare_from)
      : undefined
    queryObj.compare_to = dashboardState.compare_to
      ? formatISO(dashboardState.compare_to)
      : undefined
    queryObj.match_day_of_week = String(dashboardState.match_day_of_week)
  }

  const sharedLinkParams = getSharedLinkSearchParams()
  if (sharedLinkParams.auth) {
    queryObj.auth = sharedLinkParams.auth
  }

  Object.assign(queryObj, ...extraQuery)

  return serializeUrlParams(queryObj)
}

function getHeaders(): Record<string, string> {
  return SHARED_LINK_AUTH ? { 'X-Shared-Link-Auth': SHARED_LINK_AUTH } : {}
}

async function handleApiResponse(response: Response) {
  const payload = await response.json()
  if (!response.ok) {
    throw new ApiError(payload.error, payload)
  }

  return payload
}

function getSharedLinkSearchParams(): Record<string, string> {
  return SHARED_LINK_AUTH ? { auth: SHARED_LINK_AUTH } : {}
}

export async function get(
  url: string,
  dashboardState?: DashboardState,
  ...extraQueryParams: unknown[]
) {
  const queryString = dashboardState
    ? dashboardStateToSearchParams(dashboardState, [...extraQueryParams])
    : serializeUrlParams(getSharedLinkSearchParams())

  const response = await fetch(queryString ? `${url}?${queryString}` : url, {
    signal: abortController.signal,
    headers: { ...getHeaders(), Accept: 'application/json' }
  })

  return handleApiResponse(response)
}

export const mutation = async <
  TBody extends Record<string, unknown> = Record<string, unknown>
>(
  url: string,
  options:
    | { body: TBody; method: 'PATCH' | 'PUT' | 'POST' }
    | { method: 'DELETE' }
) => {
  const queryString = serializeUrlParams(getSharedLinkSearchParams())
  const fetchOptions =
    options.method === 'DELETE'
      ? {}
      : {
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(options.body)
        }
  const response = await fetch(queryString ? `${url}?${queryString}` : url, {
    method: options.method,
    headers: {
      ...getHeaders(),
      ...fetchOptions.headers,
      Accept: 'application/json'
    },
    body: fetchOptions.body,
    signal: abortController.signal
  })
  return handleApiResponse(response)
}

// Webhook Types
export interface Webhook {
  id: string
  url: string
  name: string
  active: boolean
  secret: boolean | null
  triggers: Trigger[]
  inserted_at: string
  updated_at: string
}

export interface Trigger {
  id: string
  type: 'visitor_spike' | 'goal_completion'
  threshold: number | null
  goal_id: string | null
  inserted_at: string
}

export interface Delivery {
  id: string
  event_id: string
  status: 'pending' | 'success' | 'failed' | 'retrying'
  response_code: number | null
  response_body: string | null
  error_message: string | null
  attempt: number
  inserted_at: string
}

export interface DeliveryPagination {
  page: number
  limit: number
  total_pages: number
  total_count: number
}

// Webhook API functions
export const webhooks = {
  async list(siteId: string): Promise<{ webhooks: Webhook[] }> {
    return get(`/api/sites/${siteId}/webhooks`)
  },

  async get(siteId: string, webhookId: string): Promise<{ webhook: Webhook }> {
    return get(`/api/sites/${siteId}/webhooks/${webhookId}`)
  },

  async create(siteId: string, webhook: {
    url: string
    name: string
    secret?: string
    triggers?: { type: string; threshold?: number; goal_id?: string }[]
  }): Promise<{ webhook: Webhook }> {
    return mutation(`/api/sites/${siteId}/webhooks`, {
      method: 'POST',
      body: { webhook }
    })
  },

  async update(siteId: string, webhookId: string, webhook: {
    url?: string
    name?: string
    secret?: string
    active?: boolean
  }): Promise<{ webhook: Webhook }> {
    return mutation(`/api/sites/${siteId}/webhooks/${webhookId}`, {
      method: 'PUT',
      body: { webhook }
    })
  },

  async delete(siteId: string, webhookId: string): Promise<void> {
    return mutation(`/api/sites/${siteId}/webhooks/${webhookId}`, {
      method: 'DELETE'
    })
  },

  async addTrigger(siteId: string, webhookId: string, trigger: {
    type: string
    threshold?: number
    goal_id?: string
  }): Promise<{ trigger: Trigger }> {
    return mutation(`/api/sites/${siteId}/webhooks/${webhookId}/triggers`, {
      method: 'POST',
      body: { trigger }
    })
  },

  async removeTrigger(siteId: string, webhookId: string, triggerId: string): Promise<void> {
    return mutation(`/api/sites/${siteId}/webhooks/${webhookId}/triggers/${triggerId}`, {
      method: 'DELETE'
    })
  },

  async getDeliveries(siteId: string, webhookId: string, page = 1, limit = 20): Promise<{
    deliveries: Delivery[]
    pagination: DeliveryPagination
  }> {
    return get(`/api/sites/${siteId}/webhooks/${webhookId}/deliveries?page=${page}&limit=${limit}`)
  }
}
