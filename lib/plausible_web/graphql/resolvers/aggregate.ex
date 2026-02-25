defmodule PlausibleWeb.GraphQL.Resolvers.Aggregate do
  @moduledoc """
  Resolvers for aggregate and timeseries queries.
  """

  alias Plausible.Stats
  alias PlausibleWeb.GraphQL.Resolvers.Helpers

  require Logger

  @doc """
  Gets aggregated metrics for a site.
  """
  def get_aggregate(_parent, %{site_id: site_id, date_range: date_range, metrics: metrics}, _resolution) do
    start_time = System.monotonic_time(:millisecond)

    with {:ok, date_range} <- Helpers.parse_date_range(date_range),
         :ok <- Helpers.validate_date_range(date_range),
         {:ok, site} <- Helpers.get_site(site_id) do
      # Build query using existing Stats infrastructure
      query = Helpers.build_query(site, date_range)

      # Parse metrics from strings to atoms
      parsed_metrics = parse_metrics(metrics)

      # Use existing aggregate query
      case Stats.aggregate(site, query, parsed_metrics) do
        {:ok, result} ->
          duration_ms = System.monotonic_time(:millisecond) - start_time
          Helpers.log_operation("aggregate", site_id, duration_ms)

          {:ok, %{
            visitors: result[:visitors],
            pageviews: result[:pageviews],
            events: result[:events],
            bounce_rate: result[:bounce_rate],
            visit_duration: result[:visit_duration],
            views_per_visit: result[:views_per_visit]
          }}

        {:error, reason} ->
          Helpers.handle_stats_result({:error, reason})
      end
    else
      {:error, %{message: _} = error} ->
        {:error, error}
    end
  end

  @doc """
  Gets timeseries data for a site.
  """
  def get_timeseries(_parent, %{site_id: site_id, date_range: date_range, metrics: metrics} = args, _resolution) do
    start_time = System.monotonic_time(:millisecond)

    with {:ok, date_range} <- Helpers.parse_date_range(date_range),
         :ok <- Helpers.validate_date_range(date_range),
         {:ok, site} <- Helpers.get_site(site_id) do
      # Build query using existing Stats infrastructure
      query = Helpers.build_query(site, date_range)

      # Parse metrics from strings to atoms
      parsed_metrics = parse_metrics(metrics)

      # Determine interval
      interval = case args[:interval] do
        :minute -> :minute
        :hour -> :hour
        :day -> :day
        :week -> :week
        :month -> :month
        _ -> :day
      end

      # Use existing timeseries query
      case Stats.timeseries(site, query, parsed_metrics, interval) do
        {:ok, results} ->
          duration_ms = System.monotonic_time(:millisecond) - start_time
          Helpers.log_operation("timeseries", site_id, duration_ms)

          {:ok, %{
            interval: interval,
            data: transform_timeseries(results)
          }}

        {:error, reason} ->
          Helpers.handle_stats_result({:error, reason})
      end
    else
      {:error, %{message: _} = error} ->
        {:error, error}
    end
  end

  defp parse_metrics(metrics) when is_list(metrics) do
    Enum.map(metrics, &parse_metric/1)
  end

  defp parse_metric("visitors"), do: :visitors
  defp parse_metric("pageviews"), do: :pageviews
  defp parse_metric("events"), do: :events
  defp parse_metric("bounce_rate"), do: :bounce_rate
  defp parse_metric("visit_duration"), do: :visit_duration
  defp parse_metric("views_per_visit"), do: :views_per_visit
  defp parse_metric(m) when is_atom(m), do: m
  defp parse_metric(_), do: :visitors

  defp transform_timeseries(results) do
    Enum.map(results, fn r ->
      %{
        date: format_date(r[:date]),
        visitors: r[:visitors],
        pageviews: r[:pageviews],
        events: r[:events]
      }
    end)
  end

  defp format_date(date) when is_binary(date) do
    date
  end

  defp format_date(%Date{} = date) do
    Date.to_iso8601(date)
  end

  defp format_date(%DateTime{} = datetime) do
    DateTime.to_date(datetime) |> Date.to_iso8601()
  end

  defp format_date(other) do
    other
  end
end
