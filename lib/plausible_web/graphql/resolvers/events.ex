defmodule PlausibleWeb.GraphQL.Resolvers.Events do
  @moduledoc """
  Resolvers for event queries.
  """

  alias Plausible.Stats
  alias PlausibleWeb.GraphQL.Resolvers.Helpers

  require Logger

  @doc """
  Lists events for a site with optional filtering and pagination.
  """
  def list_events(_parent, %{site_id: site_id, date_range: date_range} = args, _resolution) do
    start_time = System.monotonic_time(:millisecond)

    with {:ok, date_range} <- Helpers.parse_date_range(date_range),
         :ok <- Helpers.validate_date_range(date_range),
         {:ok, site} <- Helpers.get_site(site_id) do
      # Build query using existing Stats infrastructure
      query = Helpers.build_query(site, date_range, args[:filter])

      # Add event name filter if provided
      query =
        if args[:filter][:name] do
          Map.put(query, :filters, Map.put(query.filters || %{}, "event:name", args[:filter][:name]))
        else
          query
        end

      # Pagination params
      pagination = {
        args[:pagination][:first] || 100,
        args[:pagination][:page] || 1
      }

      # Metrics to fetch
      metrics = [:visitors, :events]

      # Use existing breakdown query with event:name dimension
      case Stats.breakdown(site, query, metrics, pagination, dimensions: ["event:name"]) do
        %{results: results, meta: meta} ->
          # Transform results to GraphQL format
          events = transform_results(results, args[:filter])

          duration_ms = System.monotonic_time(:millisecond) - start_time
          Helpers.log_operation("events", site_id, duration_ms)

          {:ok, %{
            edges: Enum.map(events, &build_edge/1),
            page_info: build_page_info(events, meta),
            total_count: meta[:total_rows] || length(events)
          }}

        {:error, reason} ->
          Helpers.handle_stats_result({:error, reason})
      end
    else
      {:error, %{message: _} = error} ->
        {:error, error}
    end
  end

  defp transform_results(results, filter) do
    # Filter by category if provided
    results
    |> Enum.map(fn r ->
      %{
        name: r[:"event:name"] || "",
        category: r[:category],
        timestamp: r[:date],
        properties: %{},
        visitors: r[:visitors] || 0,
        events: r[:events] || 0
      }
    end)
    |> then(fn events ->
      if filter[:category] do
        Enum.filter(events, &(&1.category == filter[:category]))
      else
        events
      end
    end)
  end

  defp build_edge(event) do
    %{
      node: event,
      cursor: encode_cursor(event[:name])
    }
  end

  defp build_page_info(results, meta) do
    %{
      has_next_page: length(results) >= (meta[:limit] || 100),
      has_previous_page: (meta[:page] || 1) > 1,
      start_cursor: if(length(results) > 0, do: encode_cursor(hd(results).name), else: nil),
      end_cursor: if(length(results) > 0, do: encode_cursor(List.last(results).name), else: nil)
    }
  end

  defp encode_cursor(nil), do: nil
  defp encode_cursor(data) when is_binary(data) do
    Base.encode64(data)
  end
end
