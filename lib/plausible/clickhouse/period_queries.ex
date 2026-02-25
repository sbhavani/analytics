defmodule Plausible.Clickhouse.PeriodQueries do
  @moduledoc """
  ClickHouse query helpers for period-based aggregations.

  Provides functions to build optimized queries for fetching metrics
  within a specific time period from the events_v2 and sessions_v2 tables.
  """

  use Plausible.ClickhouseRepo

  import Ecto.Query

  alias Plausible.Analytics.PeriodComparison
  alias Plausible.Site

  @events_table "events_v2"
  @sessions_table "sessions_v2"

  @metrics [:visitors, :pageviews, :views_per_visitor, :bounce_rate, :visit_duration]

  @doc """
  Returns the list of supported metrics for period queries.
  """
  def supported_metrics, do: @metrics

  @doc """
  Builds a base query for fetching metrics within a time period.

  ## Options
    - `:include_sessions` - Whether to join with sessions table for session-based metrics (default: false)

  ## Examples
      iex> PeriodQueries.build_period_query(site, period)
      #Ecto.Query<>

      iex> PeriodQueries.build_period_query(site, period, include_sessions: true)
      #Ecto.Query<>
  """
  def build_period_query(%Site{} = site, %PeriodComparison{} = period, opts \\ []) do
    include_sessions = Keyword.get(opts, :include_sessions, false)

    date_start = DateTime.new!(period.start_date, ~T[00:00:00], "Etc/UTC")
    date_end = DateTime.new!(period.end_date, ~T[23:59:59], "Etc/UTC")

    query =
      from(e in @events_table,
        where: e.site_id == ^site.id,
        where: e.timestamp >= ^date_start,
        where: e.timestamp <= ^date_end,
        where: e.sign == 1
      )

    if include_sessions do
      join_sessions(query, site, period)
    else
      query
    end
  end

  @doc """
  Builds a query that aggregates basic event metrics for a period.

  Returns a query that selects:
  - visitors: distinct count of user_id
  - pageviews: count of all events
  """
  def build_basic_metrics_query(%Site{} = site, %PeriodComparison{} = period) do
    base_query = build_period_query(site, period)

    from(e in base_query,
      select: %{
        visitors: count(e.user_id, :distinct),
        pageviews: count(e.name)
      }
    )
  end

  @doc """
  Builds a query that aggregates session-based metrics for a period.

  Returns a query that selects:
  - bounce_rate: percentage of sessions with 0 pageviews after the first event
  - visit_duration: average time between first and last event in a session
  """
  def build_session_metrics_query(%Site{} = site, %PeriodComparison{} = period) do
    base_query = build_period_query(site, period, include_sessions: true)

    from(e in base_query,
      select: %{
        bounce_rate: fragment("quantile(0.5)(if(empty?(refine(granularity), toIntervalSecond(0))), NULL, 1))"),
        visit_duration: fragment("quantile(0.5)(if(empty?(refine(granularity)), NULL, visit_duration))")
      }
    )
  end

  @doc """
  Builds a complete metrics query that includes both event and session metrics.

  This is a more comprehensive query that fetches all supported metrics.
  """
  def build_complete_metrics_query(%Site{} = site, %PeriodComparison{} = period) do
    base_query = build_period_query(site, period, include_sessions: true)

    from(e in base_query,
      select: %{
        visitors: count(e.user_id, :distinct),
        pageviews: count(e.name),
        views_per_visitor: fragment("count(e.name) / count(distinct e.user_id)"),
        bounce_rate: fragment("avg(if(e.exit_page == '', 1, 0)) * 100"),
        visit_duration: fragment("avg(e.time_on_page)")
      }
    )
  end

  @doc """
  Executes a metrics query for a given period and returns the results.

  Returns a map with metric atoms as keys and their values.
  """
  def fetch_metrics_for_period(%Site{} = site, %PeriodComparison{} = period, metrics \\ nil) do
    metrics_to_fetch = metrics || @metrics

    query =
      if metrics_to_fetch == @metrics do
        build_complete_metrics_query(site, period)
      else
        build_basic_metrics_query(site, period)
      end

    case ClickhouseRepo.all(query) do
      [row] ->
        Enum.map(metrics_to_fetch, fn metric ->
          {metric, Map.get(row, metric, 0)}
        end)
        |> Map.new()

      [] ->
        Enum.map(metrics_to_fetch, fn _ -> {nil, 0} end)
        |> Map.new()
    end
  end

  @doc """
  Builds a union query to fetch metrics for two periods in a single query.

  This can be more efficient than making two separate queries when network
  latency is a concern.
  """
  def build_comparison_query(%Site{} = site, %PeriodComparison{} = current_period, %PeriodComparison{} = comparison_period) do
    current_query = build_period_query_with_label(site, current_period, "current")
    comparison_query = build_period_query_with_label(site, comparison_period, "comparison")

    from(e in current_query,
      union: ^comparison_query
    )
  end

  defp build_period_query_with_label(%Site{} = site, %PeriodComparison{} = period, label) do
    date_start = DateTime.new!(period.start_date, ~T[00:00:00], "Etc/UTC")
    date_end = DateTime.new!(period.end_date, ~T[23:59:59], "Etc/UTC")

    from(e in @events_table,
      where: e.site_id == ^site.id,
      where: e.timestamp >= ^date_start,
      where: e.timestamp <= ^date_end,
      where: e.sign == 1,
      select: %{
        period_label: ^label,
        visitors: count(e.user_id, :distinct),
        pageviews: count(e.name)
      }
    )
  end

  defp join_sessions(query, %Site{} = site, %PeriodComparison{} = period) do
    date_start = DateTime.new!(period.start_date, ~T[00:00:00], "Etc/UTC")
    date_end = DateTime.new!(period.end_date, ~T[23:59:59], "Etc/UTC")

    sessions_subquery =
      from(s in @sessions_table,
        where: s.site_id == ^site.id,
        where: s.start >= ^date_start,
        where: s.start <= ^date_end,
        where: s.sign == 1,
        select: %{
          session_id: s.session_id,
          user_id: s.user_id,
          exit_page: s.exit_page,
          time_on_page: s.time_on_page
        }
      )

    from(e in query,
      join: s in subquery(sessions_subquery),
      on: e.session_id == s.session_id,
      as: :session
    )
  end

  @doc """
  Returns the SQL string representation of a period query for debugging.
  """
  def to_sql(%Site{} = site, %PeriodComparison{} = period) do
    query = build_period_query(site, period)
    {:ok, sql, _} = ClickhouseRepo.to_sql(query)
    sql
  end
end
