defmodule PlausibleWeb.GraphQL.Resolvers.Metric do
  @moduledoc """
  Resolver for custom metric GraphQL queries.
  """

  alias Plausible.Stats
  alias PlausibleWeb.GraphQL.Resolvers.Helpers.FilterParser

  def list_metrics(_root, %{site_id: _site_id} = args, %{context: %{site: site}}) do
    filter = Map.get(args, :filter)
    time_series = Map.get(args, :time_series, false)
    interval = Map.get(args, :interval)

    with :ok <- FilterParser.validate_date_range(filter) do
      metric_names = Map.get(filter, :metric_names, [])

      results =
        if time_series do
          get_time_series_metrics(site, filter, metric_names, interval)
        else
          get_current_metrics(site, filter, metric_names)
        end

      {:ok, results}
    else
      {:error, message} -> {:error, message}
    end
  end

  def list_metrics(_root, _args, _context) do
    {:error, "Authentication required"}
  end

  defp get_current_metrics(site, filter, metric_names) do
    date_range = %{
      from: Map.get(filter, :from),
      to: Map.get(filter, :to)
    }

    # Get current values for each metric
    # In production, this would query from goals/revenue metrics
    case metric_names do
      [] ->
        # Return all available custom metrics
        []

      names ->
        Enum.map(names, fn name ->
          # Query metric value
          result = Stats.aggregate(site, date_range, ["visitors"], filters: %{})

          %{
            name: name,
            value: get_metric_value(name, result),
            historical: []
          }
        end)
    end
  end

  defp get_time_series_metrics(site, filter, metric_names, interval) do
    date_range = %{
      from: Map.get(filter, :from),
      to: Map.get(filter, :to)
    }

    interval_str = convert_interval(interval)

    # Get time series data for each metric
    case metric_names do
      [] ->
        []

      names ->
        Enum.map(names, fn name ->
          # Query time series for the metric
          timeseries_result =
            Stats.timeseries(site, date_range, ["visitors"], interval: interval_str, filters: %{})

          historical =
            Enum.map(timeseries_result, fn point ->
              %{
                timestamp: Map.get(point, :date) || Map.get(point, :timestamp),
                value: get_metric_value(name, point)
              }
            end)

          current_value =
            case List.last(timeseries_result) do
              nil -> 0
              point -> get_metric_value(name, point)
            end

          %{
            name: name,
            value: current_value,
            historical: historical
          }
        end)
    end
  end

  defp convert_interval(nil), do: "date"

  defp convert_interval(:minute), do: "minute"
  defp convert_interval(:hour), do: "hour"
  defp convert_interval(:day), do: "date"
  defp convert_interval(:week), do: "week"
  defp convert_interval(:month), do: "month"

  defp get_metric_value("revenue", result) do
    # For revenue metrics, would need to use the revenue module
    Map.get(result, :revenue) || 0.0
  end

  defp get_metric_value(_name, result) do
    Map.get(result, :visitors) || Map.get(result, :events) || 0
  end
end
