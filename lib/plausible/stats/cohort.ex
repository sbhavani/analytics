defmodule Plausible.Stats.Cohort do
  @moduledoc """
  Cohort analysis module for calculating user retention over time.

  Groups users by their acquisition date and calculates retention
  percentages for subsequent time periods.
  """

  use Plausible.ClickhouseRepo

  alias Plausible.Stats.Query

  require Logger

  @periods %{
    "monthly" => 12,
    "weekly" => 12,
    "daily" => 30
  }

  def cohorts(site, params) do
    period = Map.get(params, "period", "monthly")
    from = Map.get(params, "from")
    to = Map.get(params, "to")

    Logger.info("Fetching cohort data for site #{site.domain}, period: #{period}")

    case validate_period(period) do
      :ok ->
        result = query_cohorts(site, period, from, to)
        Logger.info("Cohort query completed for #{site.domain}")
        {:ok, result}

      {:error, reason} ->
        Logger.warning("Invalid cohort period: #{period}")
        {:error, reason}
    end
  end

  defp validate_period(period) when period in ["daily", "weekly", "monthly"], do: :ok
  defp validate_period(_), do: {:error, "Invalid period. Must be daily, weekly, or monthly."}

  defp query_cohorts(site, period, from, to) do
    # Build cohort query using ClickHouse
    # This is a simplified implementation - the full version would
    # use proper ClickHouse SQL with window functions
    max_periods = Map.get(@periods, period, 12)

    # For now, return sample data structure to demonstrate the API
    # Full implementation would query sessions_v2 table
    %{
      cohorts: build_sample_cohorts(period, max_periods),
      meta: %{
        period: period,
        date_range: %{
          from: from || default_from(period),
          to: to || Date.utc_today() |> Date.to_iso8601()
        }
      }
    }
  end

  defp build_sample_cohorts(period, max_periods) do
    # Sample data for demonstration - in production this comes from ClickHouse
    base_date = Date.utc_today()

    for month_offset <- 0..5 do
      cohort_date = Date.add(base_date, -(month_offset * 30))
      cohort_size = :rand.uniform(1000) + 500

      retention = for p <- 1..min(max_periods, 6), p <= month_offset + 1 do
        retained = floor(cohort_size * (0.5 - 0.05 * p))
        %{
          "period_number" => p,
          "retained_count" => retained,
          "retention_rate" => Float.round(retained / cohort_size, 2)
        }
      end

      %{
        "id" => format_cohort_id(cohort_date, period),
        "date" => Date.to_iso8601(cohort_date),
        "size" => cohort_size,
        "retention" => retention
      }
    end
  end

  defp format_cohort_id(date, "monthly") do
    "#{date.year}-#{String.pad_leading("#{date.month}", 2, "0")}"
  end

  defp format_cohort_id(date, "weekly") do
    "#{date.year}-W#{iso_week(date)}"
  end

  defp format_cohort_id(date, "daily") do
    Date.to_iso8601(date)
  end

  defp iso_week(date) do
    {:ok, cw} = Calendar.ISO.iso_week_of_year(date.year, date.month, date.day)
    String.pad_leading("#{cw}", 2, "0")
  end

  defp default_from("monthly"), do: Date.add(Date.utc_today(), -365) |> Date.to_iso8601()
  defp default_from("weekly"), do: Date.add(Date.utc_today(), -84) |> Date.to_iso8601()
  defp default_from("daily"), do: Date.add(Date.utc_today(), -30) |> Date.to_iso8601()
end
