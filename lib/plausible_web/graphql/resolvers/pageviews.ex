defmodule PlausibleWeb.GraphQL.Resolvers.Pageviews do
  @moduledoc """
  Resolvers for pageview queries.
  """

  alias Plausible.Stats
  alias PlausibleWeb.GraphQL.Resolvers.Helpers

  require Logger

  @doc """
  Lists pageviews for a site with optional filtering and pagination.
  """
  def list_pageviews(_parent, %{site_id: site_id, date_range: date_range} = args, _resolution) do
    start_time = System.monotonic_time(:millisecond)

    with {:ok, date_range} <- Helpers.parse_date_range(date_range),
         :ok <- Helpers.validate_date_range(date_range),
         {:ok, site} <- Helpers.get_site(site_id) do
      # Build query using existing Stats infrastructure
      query = Helpers.build_query(site, date_range)

      # Pagination params
      pagination = {
        args[:pagination][:first] || 100,
        args[:pagination][:page] || 1
      }

      # Metrics to fetch
      metrics = [:visitors, :pageviews, :views_per_visit, :bounce_rate]

      # Use existing breakdown query
      case Stats.breakdown(site, query, metrics, pagination) do
        %{results: results, meta: meta} ->
          # Transform results to GraphQL format
          pageviews = transform_results(results)

          duration_ms = System.monotonic_time(:millisecond) - start_time
          Helpers.log_operation("pageviews", site_id, duration_ms)

          {:ok, %{
            edges: Enum.map(pageviews, &build_edge/1),
            page_info: build_page_info(pageviews, meta),
            total_count: meta[:total_rows] || length(pageviews)
          }}

        {:error, reason} ->
          Helpers.handle_stats_result({:error, reason})
      end
    else
      {:error, %{message: _} = error} ->
        {:error, error}
    end
  end

  defp transform_results(results) do
    Enum.map(results, fn r ->
      %{
        url: r[:page] || "",
        title: r[:title],
        visitors: r[:visitors] || 0,
        views_per_visit: r[:views_per_visit],
        bounce_rate: r[:bounce_rate],
        timestamp: r[:date]
      }
    end)
  end

  defp build_edge(pageview) do
    %{
      node: pageview,
      cursor: encode_cursor(pageview[:url])
    }
  end

  defp build_page_info(results, meta) do
    %{
      has_next_page: length(results) >= (meta[:limit] || 100),
      has_previous_page: (meta[:page] || 1) > 1,
      start_cursor: if(length(results) > 0, do: encode_cursor(hd(results)[:url]), else: nil),
      end_cursor: if(length(results) > 0, do: encode_cursor(List.last(results)[:url]), else: nil)
    }
  end

  defp encode_cursor(nil), do: nil
  defp encode_cursor(data) when is_binary(data) do
    Base.encode64(data)
  end
end
