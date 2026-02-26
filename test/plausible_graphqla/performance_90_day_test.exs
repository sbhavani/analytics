defmodule Plausible.Graphqla.Performance90DayTest do
  @moduledoc """
  Performance tests for 90-day range queries.

  Performance targets:
  - Query response within 5 seconds for 90-day ranges
  - Aggregation within 10 seconds

  These tests verify that GraphQL queries meet performance SLAs
  for large date range queries.
  """
  use Plausible.DataCase, async: false

  alias Plausible.Graphqla.Resolvers.PageviewResolver
  alias Plausible.Graphqla.Resolvers.AggregationResolver

  # Performance thresholds from plan.md
  @query_timeout_ms 5_000
  @aggregation_timeout_ms 10_000
  @test_days 90

  describe "90-day range query performance" do
    setup [:create_site_with_data]

    test "pageview list query completes within 5 seconds for 90-day range", %{
      site: site,
      events: _events
    } do
      date_from = Date.utc_today() |> Date.add(-@test_days)
      date_to = Date.utc_today()

      filter = %{
        site_id: site.id,
        date_range: %{from: date_from, to: date_to}
      }

      pagination = %{limit: 100, offset: 0}

      {execution_time_ms, result} =
        :timer.tc(fn ->
          PageviewResolver.list_pageviews(%{}, %{filter: filter, pagination: pagination})
        end)

      # Verify query succeeded
      assert {:ok, _} = result

      # Log performance metrics
      IO.puts("Pageview list query (#{@test_days}-day range): #{execution_time_ms / 1000}s")

      # Assert performance threshold
      assert execution_time_ms < @query_timeout_ms,
             "Pageview query took #{execution_time_ms / 1000}s, exceeds #{@query_timeout_ms / 1000}s threshold"
    end

    test "pageview aggregation by day completes within 10 seconds for 90-day range", %{
      site: site
    } do
      date_from = Date.utc_today() |> Date.add(-@test_days)
      date_to = Date.utc_today()

      filter = %{
        site_id: site.id,
        date_range: %{from: date_from, to: date_to}
      }

      {execution_time_ms, result} =
        :timer.tc(fn ->
          AggregationResolver.pageview_aggregations(%{}, %{
            filter: filter,
            granularity: :day
          })
        end)

      # Verify query succeeded
      assert {:ok, aggregations} = result
      assert is_list(aggregations)

      # Log performance metrics
      IO.puts(
        "Pageview aggregation (day granularity, #{@test_days}-day range): #{execution_time_ms / 1000}s"
      )

      # Assert performance threshold
      assert execution_time_ms < @aggregation_timeout_ms,
             "Pageview aggregation took #{execution_time_ms / 1000}s, exceeds #{
               @aggregation_timeout_ms / 1000}s threshold"
    end

    test "pageview aggregation by month completes within 10 seconds for 90-day range", %{
      site: site
    } do
      date_from = Date.utc_today() |> Date.add(-@test_days)
      date_to = Date.utc_today()

      filter = %{
        site_id: site.id,
        date_range: %{from: date_from, to: date_to}
      }

      {execution_time_ms, result} =
        :timer.tc(fn ->
          AggregationResolver.pageview_aggregations(%{}, %{
            filter: filter,
            granularity: :month
          })
        end)

      # Verify query succeeded
      assert {:ok, aggregations} = result
      assert is_list(aggregations)

      # Log performance metrics
      IO.puts(
        "Pageview aggregation (month granularity, #{@test_days}-day range): #{execution_time_ms / 1000}s"
      )

      # Assert performance threshold
      assert execution_time_ms < @aggregation_timeout_ms,
             "Pageview aggregation took #{execution_time_ms / 1000}s, exceeds #{
               @aggregation_timeout_ms / 1000}s threshold"
    end

    test "event aggregation completes within 10 seconds for 90-day range", %{site: site} do
      date_from = Date.utc_today() |> Date.add(-@test_days)
      date_to = Date.utc_today()

      filter = %{
        site_id: site.id,
        date_range: %{from: date_from, to: date_to}
      }

      {execution_time_ms, result} =
        :timer.tc(fn ->
          AggregationResolver.event_aggregations(%{}, %{
            filter: filter,
            group_by: "name"
          })
        end)

      # Verify query succeeded
      assert {:ok, aggregations} = result
      assert is_list(aggregations)

      # Log performance metrics
      IO.puts("Event aggregation (#{@test_days}-day range): #{execution_time_ms / 1000}s")

      # Assert performance threshold
      assert execution_time_ms < @aggregation_timeout_ms,
             "Event aggregation took #{execution_time_ms / 1000}s, exceeds #{
               @aggregation_timeout_ms / 1000}s threshold"
    end

    test "custom metric aggregation completes within 10 seconds for 90-day range", %{
      site: site
    } do
      date_from = Date.utc_today() |> Date.add(-@test_days)
      date_to = Date.utc_today()

      filter = %{
        site_id: site.id,
        date_range: %{from: date_from, to: date_to},
        metric_name: "test_metric"
      }

      {execution_time_ms, result} =
        :timer.tc(fn ->
          AggregationResolver.custom_metric_aggregations(%{}, %{filter: filter})
        end)

      # Verify query succeeded
      assert {:ok, aggregations} = result
      assert is_list(aggregations)

      # Log performance metrics
      IO.puts(
        "Custom metric aggregation (#{@test_days}-day range): #{execution_time_ms / 1000}s"
      )

      # Assert performance threshold
      assert execution_time_ms < @aggregation_timeout_ms,
             "Custom metric aggregation took #{execution_time_ms / 1000}s, exceeds #{
               @aggregation_timeout_ms / 1000}s threshold"
    end
  end

  defp create_site_with_data(_) do
    site = insert(:site)

    # Generate events spread across 90 days
    # This simulates a realistic data distribution
    events =
      Enum.map(0..89, fn day_offset ->
        date = Date.utc_today() |> Date.add(-day_offset)

        # Multiple events per day to simulate realistic traffic
        Enum.map(1..10, fn _ ->
          build(:pageview, site_id: site.id, timestamp: date |> NaiveDateTime.new!(~T[12:00:00]))
        end)
      end)
      |> List.flatten()

    populate_stats(site, events)

    {:ok, site: site, events: events}
  end
end
