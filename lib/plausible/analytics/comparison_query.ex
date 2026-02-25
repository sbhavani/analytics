defmodule Plausible.Analytics.ComparisonQuery do
  @moduledoc """
  Service for executing ClickHouse queries to compare metrics between two time periods.
  """

  require Logger

  alias Plausible.Analytics.PeriodComparison
  alias Plausible.Analytics.PeriodComparison.ComparisonResult
  alias Plausible.ClickhouseRepo
  alias Plausible.Site

  @metrics ["visitors", "pageviews", "views_per_visitor", "bounce_rate", "visit_duration"]

  @doc """
  Fetches comparison data for a site between two time periods.
  """
  def fetch_comparison(%Site{} = site, %PeriodComparison{} = current_period, %PeriodComparison{} = comparison_period, metrics \\ nil) do
    metrics_to_fetch = metrics || @metrics

    Logger.info("Period comparison: fetching data",
      site_id: site.id,
      current_start: current_period.start_date,
      current_end: current_period.end_date,
      comparison_start: comparison_period.start_date,
      comparison_end: comparison_period.end_date,
      metrics: metrics_to_fetch
    )

    start_time = System.monotonic_time(:millisecond)

    current_metrics = fetch_metrics_for_period(site, current_period, metrics_to_fetch)
    comparison_metrics = fetch_metrics_for_period(site, comparison_period, metrics_to_fetch)

    results = build_comparison_results(current_metrics, comparison_metrics, metrics_to_fetch)

    elapsed = System.monotonic_time(:millisecond) - start_time

    Logger.info("Period comparison: query completed",
      site_id: site.id,
      elapsed_ms: elapsed,
      metrics_count: length(results)
    )

    %{
      current_period: PeriodComparison.to_map(current_period),
      comparison_period: PeriodComparison.to_map(comparison_period),
      metrics: results
    }
  end

  defp fetch_metrics_for_period(%Site{} = site, %PeriodComparison{} = period, metrics) do
    # Build a query that aggregates all requested metrics for the period
    query = build_metrics_query(site, period, metrics)

    case ClickhouseRepo.all(query) do
      [row] -> Map.new(metrics, fn m -> {m, Map.get(row, String.to_atom(m), 0)} end)
      [] -> Map.new(metrics, fn m -> {m, 0} end)
    end
  end

  defp build_metrics_query(%Site{} = site, %PeriodComparison{} = period, metrics) do
    from(e in "events_v2",
      where: e.site_id == ^site.id,
      where: e.timestamp >= ^DateTime.new!(period.start_date, ~T[00:00:00], "Etc/UTC"),
      where: e.timestamp <= ^DateTime.new!(period.end_date, ~T[23:59:59], "Etc/UTC"),
      where: e.sign == 1,
      select: %{
        visitors: count(e.user_id, :distinct),
        pageviews: count(e.name)
      }
    )
  end

  defp build_comparison_results(current_metrics, comparison_metrics, metrics) do
    Enum.map(metrics, fn metric_name ->
      current_value = Map.get(current_metrics, metric_name, 0)
      previous_value = Map.get(comparison_metrics, metric_name, 0)

      result = PeriodComparison.calculate_comparison(current_value, previous_value, metric_name)
      PeriodComparison.to_map(result)
    end)
  end

  @doc """
  Returns list of available metrics for comparison.
  """
  def available_metrics, do: @metrics
end
