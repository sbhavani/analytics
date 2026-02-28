defmodule Plausible.GraphQL.Resolvers.Pageview do
  @moduledoc """
  Resolvers for pageview GraphQL queries.
  """

  alias Plausible.GraphQL.Resolvers.Filter
  alias Plausible.GraphQL.Resolvers.Aggregation
  alias Plausible.Repo
  require Logger

  @doc """
  Lists pageviews with optional filtering and pagination.
  """
  def list_pageviews(_parent, %{site_id: site_id, date_range: date_range} = args, %{context: %{auth: auth}}) do
    with {:ok, site} <- authorize_site_access(site_id, auth),
         {:ok, query} <- build_stats_query(site, date_range, args[:filter]),
         {:ok, pageviews} <- fetch_pageviews(query, args[:limit], args[:offset]) do
      {:ok, pageviews}
    else
      {:error, reason} ->
        Logger.warning("Failed to list pageviews: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def list_pageviews(_parent, _args, _context) do
    {:error, :unauthorized}
  end

  @doc """
  Returns aggregated pageview metrics.
  """
  def aggregate_pageviews(_parent, %{site_id: site_id, date_range: date_range, aggregation: aggregation} = args, %{context: %{auth: auth}}) do
    with {:ok, site} <- authorize_site_access(site_id, auth),
         {:ok, query} <- build_stats_query(site, date_range, args[:filter]),
         {:ok, result} <- Aggregation.aggregate(query, aggregation) do
      {:ok, result}
    else
      {:error, reason} ->
        Logger.warning("Failed to aggregate pageviews: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def aggregate_pageviews(_parent, _args, _context) do
    {:error, :unauthorized}
  end

  defp authorize_site_access(site_id, %{api_key: _api_key}) do
    case Repo.get(Plausible.Site, site_id) do
      nil -> {:error, :not_found}
      site -> {:ok, site}
    end
  end

  defp authorize_site_access(_site_id, _auth), do: {:error, :unauthorized}

  defp build_stats_query(site, date_range, filter) do
    datetime_range = Plausible.Stats.DateTimeRange.new!(date_range.from, date_range.to)

    query = %Plausible.Stats.Query{
      site_id: site.id,
      utc_time_range: datetime_range,
      input_date_range: Date.range(date_range.from, date_range.to),
      filters: Filter.build_filters(filter)
    }

    {:ok, query}
  end

  defp fetch_pageviews(_query, _limit, _offset) do
    # This would call the existing Stats.breakdown/3
    # For now returning a placeholder structure
    {:ok, []}
  end
end
