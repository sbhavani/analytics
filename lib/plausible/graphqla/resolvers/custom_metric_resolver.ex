defmodule Plausible.Graphqla.Resolvers.CustomMetricResolver do
  @moduledoc """
  Resolver for custom metric-related GraphQL queries
  """
  alias Plausible.ClickhouseRepo
  alias Plausible.Site
  alias Plausible.Stats.Query
  import Ecto.Query

  @default_limit 100
  @max_limit 1000

  @spec list_custom_metrics(any(), map()) :: {:ok, map()} | {:error, String.t()}
  def list_custom_metrics(_parent, %{filter: filter, pagination: pagination}) do
    with {:ok, site} <- resolve_site(filter.site_id),
         {:ok, query} <- build_query(filter, site) do
      metrics = fetch_custom_metrics(query, filter, pagination)
      {:ok, %{edges: metrics, page_info: %{has_next_page: false, end_cursor: nil}}}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def list_custom_metrics(_parent, %{filter: filter}) do
    list_custom_metrics(_parent, %{filter: filter, pagination: %{limit: @default_limit, offset: 0}})
  end

  def list_custom_metrics(_parent, _) do
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

    {:ok, query}
  end

  defp fetch_custom_metrics(query, filter, pagination) do
    limit = min(pagination[:limit] || @default_limit, @max_limit)
    offset = pagination[:offset] || 0

    # Custom metrics are stored as events with numeric properties
    # This is a simplified implementation - custom metrics would need
    # specific schema definitions in ClickHouse
    base_query =
      from(e in "events_v2",
        where: e.site_id == ^query.site_id,
        where: fragment("toDate(?)", e.timestamp) >= ^Date.from_iso8601!(elem(query.date_range, 0)),
        where: fragment("toDate(?)", e.timestamp) <= ^Date.from_iso8601!(elem(query.date_range, 1)),
        where: e.name == "custom_metric"
      )

    query =
      if filter.metric_name do
        from(e in base_query,
          where: fragment("?->>'name' = ?", e.properties, ^filter.metric_name),
          order_by: [desc: e.timestamp],
          limit: ^limit,
          offset: ^offset,
          select: %{
            id: e.uuid,
            timestamp: e.timestamp,
            name: fragment("?->>'name'", e.properties),
            value: fragment("?->>'value'", e.properties) |> type_cast(:float),
            site_id: e.site_id
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
            name: fragment("?->>'name'", e.properties),
            value: fragment("?->>'value'", e.properties) |> type_cast(:float),
            site_id: e.site_id
          }
        )
      end

    ClickhouseRepo.all(query)
  end

  # Helper to cast values - in practice this would need proper ClickHouse type casting
  defp type_cast(expr, :float) do
    fragment("cast(? as Float64)", ^expr)
  end
end
