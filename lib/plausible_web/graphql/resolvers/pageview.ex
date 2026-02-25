defmodule PlausibleWeb.GraphQL.Resolvers.Pageview do
  @moduledoc """
  Resolver for pageview GraphQL queries.
  """

  alias Plausible.Stats
  alias PlausibleWeb.GraphQL.Resolvers.Helpers.{FilterParser, Aggregation}
  alias PlausibleWeb.GraphQL.Types.Pagination

  def list_pageviews(_root, %{site_id: _site_id} = args, %{context: %{site: site}}) do
    filter = Map.get(args, :filter)
    pagination = Map.get(args, :pagination)
    aggregation = Map.get(args, :aggregation)

    with :ok <- FilterParser.validate_date_range(filter) do
      filters = FilterParser.parse_pageview_filter(filter)

      query = build_pageview_query(site, filter, filters)

      results =
        if aggregation do
          aggregate_results(query, aggregation, filters)
        else
          list_results(query, pagination, filters)
        end

      {:ok, results}
    else
      {:error, message} -> {:error, message}
    end
  end

  def list_pageviews(_root, _args, _context) do
    {:error, "Authentication required"}
  end

  defp build_pageview_query(site, filter, filters) do
    date_range = %{
      from: Map.get(filter, :from),
      to: Map.get(filter, :to)
    }

    Stats.aggregate(site, date_range, ["visitors", "pageviews"], filters: filters)
  end

  defp list_results(query, pagination, _filters) do
    pag = Pagination.from_input(pagination)

    # For now, return mock data as we need to integrate with the actual Stats context
    # In production, this would call the actual ClickHouse queries
    []
  end

  defp aggregate_results(query, aggregation, _filters) do
    metrics = Aggregation.to_stats_metrics(aggregation)

    # Apply aggregation to the query results
    case query do
      %{__struct__: _} ->
        # In production, execute query and apply aggregation
        [Aggregation.apply_aggregation([], aggregation)]

      _ ->
        []
    end
  end
end
