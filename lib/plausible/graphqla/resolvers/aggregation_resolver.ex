defmodule Plausible.Graphqla.Resolvers.AggregationResolver do
  @moduledoc """
  Resolver for aggregation-related GraphQL queries
  """
  alias Plausible.ClickhouseRepo
  alias Plausible.Site
  alias Plausible.Stats.Query
  import Ecto.Query

  @spec pageview_aggregations(any(), map()) :: {:ok, list()} | {:error, String.t()}
  def pageview_aggregations(_parent, %{filter: filter, granularity: granularity}) do
    with {:ok, site} <- resolve_site(filter.site_id),
         {:ok, query} <- build_query(filter, site) do
      aggregations = fetch_pageview_aggregations(query, granularity)
      {:ok, aggregations}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def pageview_aggregations(_parent, %{filter: filter}) do
    pageview_aggregations(_parent, %{filter: filter, granularity: :day})
  end

  def pageview_aggregations(_parent, _) do
    {:error, "Filter with site_id is required"}
  end

  @spec event_aggregations(any(), map()) :: {:ok, list()} | {:error, String.t()}
  def event_aggregations(_parent, %{filter: filter, group_by: group_by}) do
    with {:ok, site} <- resolve_site(filter.site_id),
         {:ok, query} <- build_query(filter, site) do
      aggregations = fetch_event_aggregations(query, group_by)
      {:ok, aggregations}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def event_aggregations(_parent, %{filter: filter}) do
    event_aggregations(_parent, %{filter: filter, group_by: "name"})
  end

  def event_aggregations(_parent, _) do
    {:error, "Filter with site_id is required"}
  end

  @spec custom_metric_aggregations(any(), map()) :: {:ok, list()} | {:error, String.t()}
  def custom_metric_aggregations(_parent, %{filter: filter}) do
    with {:ok, site} <- resolve_site(filter.site_id),
         {:ok, query} <- build_query(filter, site) do
      aggregations = fetch_custom_metric_aggregations(query, filter)
      {:ok, aggregations}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def custom_metric_aggregations(_parent, _) do
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

  # Time-based aggregation for pageviews
  defp fetch_pageview_aggregations(query, granularity) do
    interval = case granularity do
      :hour -> "toStartOfHour"
      :day -> "toDate"
      :week -> "toStartOfWeek"
      :month -> "toStartOfMonth"
      _ -> "toDate"
    end

    from(e in "events_v2",
      where: e.site_id == ^query.site_id,
      where: e.name == "pageview",
      where: fragment("toDate(?)", e.timestamp) >= ^Date.from_iso8601!(elem(query.date_range, 0)),
      where: fragment("toDate(?)", e.timestamp) <= ^Date.from_iso8601!(elem(query.date_range, 1)),
      group_by: fragment("#{interval}(?)", e.timestamp),
      order_by: [asc: fragment("#{interval}(?)", e.timestamp)],
      select: %{
        key: fragment("#{interval}(?)", e.timestamp),
        count: count(e.uuid)
      }
    )
    |> ClickhouseRepo.all()
    |> Enum.map(fn row ->
      %{
        key: to_string(row.key),
        count: row.count,
        sum: nil,
        average: nil
      }
    end)
  end

  # Categorical aggregation for events
  defp fetch_event_aggregations(query, group_by) do
    group_field = case group_by do
      "name" -> e.name
      _ -> e.name
    end

    from(e in "events_v2",
      where: e.site_id == ^query.site_id,
      where: e.name != "pageview",
      where: fragment("toDate(?)", e.timestamp) >= ^Date.from_iso8601!(elem(query.date_range, 0)),
      where: fragment("toDate(?)", e.timestamp) <= ^Date.from_iso8601!(elem(query.date_range, 1)),
      group_by: ^group_field,
      order_by: [desc: count(e.uuid)],
      select: %{
        key: ^group_field,
        count: count(e.uuid)
      }
    )
    |> ClickhouseRepo.all()
    |> Enum.map(fn row ->
      %{
        key: row.key,
        count: row.count,
        sum: nil,
        average: nil
      }
    end)
  end

  # Custom metric aggregations
  defp fetch_custom_metric_aggregations(query, filter) do
    base_query =
      from(e in "events_v2",
        where: e.site_id == ^query.site_id,
        where: e.name == "custom_metric",
        where: fragment("toDate(?)", e.timestamp) >= ^Date.from_iso8601!(elem(query.date_range, 0)),
        where: fragment("toDate(?)", e.timestamp) <= ^Date.from_iso8601!(elem(query.date_range, 1))
      )

    query = if filter.metric_name do
      from(e in base_query,
        where: fragment("?->>'name' = ?", e.properties, ^filter.metric_name),
        select: %{
          sum: sum(fragment("cast(?->>'value' as Float64)", e.properties)),
          count: count(e.uuid),
          average: avg(fragment("cast(?->>'value' as Float64)", e.properties))
        }
      )
    else
      from(e in base_query,
        select: %{
          sum: sum(fragment("cast(?->>'value' as Float64)", e.properties)),
          count: count(e.uuid),
          average: avg(fragment("cast(?->>'value' as Float64)", e.properties))
        }
      )
    end

    [result] = ClickhouseRepo.all(query)

    [%{
      key: filter.metric_name || "all",
      count: result.count || 0,
      sum: result.sum || 0.0,
      average: result.average || 0.0
    }]
  end
end
