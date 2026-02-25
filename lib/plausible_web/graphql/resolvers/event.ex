defmodule PlausibleWeb.GraphQL.Resolvers.Event do
  @moduledoc """
  Resolver for event GraphQL queries.
  """

  alias Plausible.Stats
  alias PlausibleWeb.GraphQL.Resolvers.Helpers.{FilterParser, Aggregation}
  alias PlausibleWeb.GraphQL.Types.Pagination

  def list_events(_root, %{site_id: _site_id} = args, %{context: %{site: site}}) do
    filter = Map.get(args, :filter)
    pagination = Map.get(args, :pagination)
    aggregation = Map.get(args, :aggregation)

    with :ok <- FilterParser.validate_date_range(filter) do
      filters = FilterParser.parse_event_filter(filter)

      results =
        if aggregation do
          aggregate_events(site, filter, filters, aggregation)
        else
          list_events_results(site, filter, filters, pagination)
        end

      {:ok, results}
    else
      {:error, message} -> {:error, message}
    end
  end

  def list_events(_root, _args, _context) do
    {:error, "Authentication required"}
  end

  defp list_events_results(site, filter, filters, pagination) do
    pag = Pagination.from_input(pagination)

    date_range = %{
      from: Map.get(filter, :from),
      to: Map.get(filter, :to)
    }

    event_name = Map.get(filters, :event_name)

    # Get all events or specific event
    if event_name do
      # Query specific event
      Stats.aggregate(site, date_range, ["visitors", :events], filters: filters)
      |> process_event_results(event_name)
    else
      # Query all events (breakdown by name)
      Stats.breakdown(site, date_range, :event_name, ["visitors", "events"], filters: filters)
      |> Enum.map(&process_breakdown_result/1)
    end
  end

  defp aggregate_events(site, filter, filters, aggregation) do
    date_range = %{
      from: Map.get(filter, :from),
      to: Map.get(filter, :to)
    }

    metrics = Aggregation.to_stats_metrics(aggregation)

    # Execute aggregation query
    result = Stats.aggregate(site, date_range, metrics, filters: filters)

    [%{name: "aggregated", count: map_get(result, :visitors) || map_get(result, :events) || 0}]
  end

  defp process_event_results(results, event_name) do
    # Process event name specific results
    [%{name: event_name, count: map_get(results, :visitors) || map_get(results, :events) || 0, properties: %{}}]
  end

  defp process_breakdown_result(result) do
    %{
      name: map_get(result, :event_name) || "unknown",
      count: map_get(result, :visitors) || map_get(result, :events) || 0,
      properties: %{}
    }
  end

  defp map_get(map, key) do
    Map.get(map, key)
  end
end
