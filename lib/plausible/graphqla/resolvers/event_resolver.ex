defmodule Plausible.Graphqla.Resolvers.EventResolver do
  @moduledoc """
  Resolver for event-related GraphQL queries
  """
  alias Plausible.ClickhouseRepo
  alias Plausible.Site
  alias Plausible.Stats.Query
  import Ecto.Query

  @default_limit 100
  @max_limit 1000

  @spec list_events(any(), map()) :: {:ok, map()} | {:error, String.t()}
  def list_events(_parent, %{filter: filter, pagination: pagination}) do
    with {:ok, site} <- resolve_site(filter.site_id),
         {:ok, query} <- build_query(filter, site) do
      events = fetch_events(query, filter, pagination)
      {:ok, %{edges: events, page_info: %{has_next_page: false, end_cursor: nil}}}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def list_events(_parent, %{filter: filter}) do
    list_events(_parent, %{filter: filter, pagination: %{limit: @default_limit, offset: 0}})
  end

  def list_events(_parent, _) do
    {:error, "Filter with site_id is required"}
  end

  defp resolve_site(site_id) do
    case Site.get_by(id: site_id) do
      nil -> {:error, "Site not found"}
      site -> {:ok, site}
    end
  end

  defp build_query(filter, site) do
    date_range =
      case filter.date_range do
        %{from: from, to: to} ->
          {from, to}

        _ ->
          {Timex.today(), Timex.today()}
      end

    query =
      Query.new(date_range: date_range, site: site)
      |> Query.put_filter("event:name", filter.event_type)

    {:ok, query}
  end

  defp fetch_events(query, filter, pagination) do
    limit = min(pagination[:limit] || @default_limit, @max_limit)
    offset = pagination[:offset] || 0

    base_query =
      from(e in "events_v2",
        where: e.site_id == ^query.site_id,
        where: e.name != "pageview",
        where: fragment("toDate(?)", e.timestamp) >= ^Date.from_iso8601!(elem(query.date_range, 0)),
        where: fragment("toDate(?)", e.timestamp) <= ^Date.from_iso8601!(elem(query.date_range, 1))
      )

    query =
      if filter.event_type do
        from(e in base_query,
          where: e.name == ^filter.event_type,
          order_by: [desc: e.timestamp],
          limit: ^limit,
          offset: ^offset,
          select: %{
            id: e.uuid,
            timestamp: e.timestamp,
            name: e.name,
            properties: e.properties,
            browser: e.browser,
            device: e.device,
            country: e.country
          }
        )
      else
        from(e in base_query,
          order_by: [desc: e.timestamp],
          limit: ^limit,
          offset: ^offset,
          select: %{
            id: e.uuid,
            timestamp: e.timestamp,
            name: e.name,
            properties: e.properties,
            browser: e.browser,
            device: e.device,
            country: e.country
          }
        )
      end

    ClickhouseRepo.all(query)
  end
end
