defmodule PlausibleWeb.GraphQL.Resolvers.CustomMetricsTest do
  @moduledoc """
  Unit tests for the CustomMetrics resolver.
  """

  use PlausibleWeb.ConnCase, async: true
  alias Plausible.Factory
  alias PlausibleWeb.GraphQL.Resolvers.CustomMetrics
  alias Plausible.Goal

  describe "custom_metrics/3" do
    test "returns custom metrics for authenticated user with authorized access" do
      user = Factory.insert(:user)
      site = Factory.insert(:site, members: [user])
      goal = Factory.insert(:goal, site: site, event_name: "purchase", name: "Total Purchases")

      context = %{context: %{user: user}}

      args = %{
        site_id: site.domain
      }

      {:ok, metrics} = CustomMetrics.custom_metrics(nil, args, context)

      assert is_list(metrics)
      assert length(metrics) >= 1

      # Check that the goal is included in the results
      metric_names = Enum.map(metrics, & &1.name)
      assert "Total Purchases" in metric_names
    end

    test "filters custom metrics by name" do
      user = Factory.insert(:user)
      site = Factory.insert(:site, members: [user])

      _goal1 = Factory.insert(:goal, site: site, event_name: "signup", name: "Signups")
      _goal2 = Factory.insert(:goal, site: site, event_name: "purchase", name: "Total Purchases")

      context = %{context: %{user: user}}

      args = %{
        site_id: site.domain,
        name: "purchase"
      }

      {:ok, metrics} = CustomMetrics.custom_metrics(nil, args, context)

      # All returned metrics should match the name filter
      Enum.each(metrics, fn metric ->
        assert String.contains?(String.downcase(metric.name), "purchase")
      end)
    end

    test "filters custom metrics by category" do
      user = Factory.insert(:user)
      site = Factory.insert(:site, members: [user])

      goal = Factory.insert(:goal, site: site, event_name: "signup", name: "Signups")

      context = %{context: %{user: user}}

      args = %{
        site_id: site.domain,
        category: "signup"
      }

      {:ok, metrics} = CustomMetrics.custom_metrics(nil, args, context)

      # All returned metrics should match the category filter
      Enum.each(metrics, fn metric ->
        assert metric.category == goal.event_name
      end)
    end

    test "returns empty list when no goals exist for site" do
      user = Factory.insert(:user)
      site = Factory.insert(:site, members: [user])

      context = %{context: %{user: user}}

      args = %{
        site_id: site.domain
      }

      {:ok, metrics} = CustomMetrics.custom_metrics(nil, args, context)

      assert metrics == []
    end

    test "returns authorization error when user is not a member of the site" do
      user = Factory.insert(:user)
      site = Factory.insert(:site)  # User is not a member of this site

      context = %{context: %{user: user}}

      args = %{
        site_id: site.domain
      }

      {:error, error} = CustomMetrics.custom_metrics(nil, args, context)

      assert error.message =~ "Access denied"
      assert error.code == :authorization_error
    end

    test "returns authentication error when user is nil" do
      site = Factory.insert(:site)

      context = %{context: %{user: nil}}

      args = %{
        site_id: site.domain
      }

      {:error, error} = CustomMetrics.custom_metrics(nil, args, context)

      assert error.message == "Authentication required"
      assert error.code == :authentication_error
    end

    test "returns site not found error for non-existent site" do
      user = Factory.insert(:user)

      context = %{context: %{user: user}}

      args = %{
        site_id: "nonexistent.example.com"
      }

      {:error, error} = CustomMetrics.custom_metrics(nil, args, context)

      assert error.message == "Site not found"
      assert error.code == :not_found
    end
  end

  describe "custom_metrics_time_series/3" do
    test "returns time series data for a valid metric" do
      user = Factory.insert(:user)
      site = Factory.insert(:site, members: [user])
      goal = Factory.insert(:goal, site: site, event_name: "signup", name: "Signups")

      context = %{context: %{user: user}}

      args = %{
        site_id: site.domain,
        metric_name: "Signups",
        date_range: %{from: "2026-01-01", to: "2026-01-31"},
        interval: :day
      }

      {:ok, time_series} = CustomMetrics.custom_metrics_time_series(nil, args, context)

      assert is_list(time_series)
      # Each item should have timestamp and value
      Enum.each(time_series, fn point ->
        assert Map.has_key?(point, :timestamp)
        assert Map.has_key?(point, :value)
      end)
    end

    test "returns error for non-existent metric" do
      user = Factory.insert(:user)
      site = Factory.insert(:site, members: [user])
      _goal = Factory.insert(:goal, site: site, event_name: "signup", name: "Signups")

      context = %{context: %{user: user}}

      args = %{
        site_id: site.domain,
        metric_name: "NonExistent",
        date_range: %{from: "2026-01-01", to: "2026-01-31"},
        interval: :day
      }

      {:error, error} = CustomMetrics.custom_metrics_time_series(nil, args, context)

      assert error.message =~ "not found"
      assert error.code == :not_found
    end

    test "returns authorization error when user is not a member of the site" do
      user = Factory.insert(:user)
      site = Factory.insert(:site)  # User is not a member

      context = %{context: %{user: user}}

      args = %{
        site_id: site.domain,
        metric_name: "Signups",
        date_range: %{from: "2026-01-01", to: "2026-01-31"},
        interval: :day
      }

      {:error, error} = CustomMetrics.custom_metrics_time_series(nil, args, context)

      assert error.message =~ "Access denied"
      assert error.code == :authorization_error
    end

    test "returns authentication error when user is nil" do
      site = Factory.insert(:site)

      context = %{context: %{user: nil}}

      args = %{
        site_id: site.domain,
        metric_name: "Signups",
        date_range: %{from: "2026-01-01", to: "2026-01-31"},
        interval: :day
      }

      {:error, error} = CustomMetrics.custom_metrics_time_series(nil, args, context)

      assert error.message == "Authentication required"
      assert error.code == :authentication_error
    end

    test "parses different interval formats" do
      user = Factory.insert(:user)
      site = Factory.insert(:site, members: [user])
      goal = Factory.insert(:goal, site: site, event_name: "signup", name: "Signups")

      context = %{context: %{user: user}}

      intervals = [:minute, :hour, :day, :week, :month]

      Enum.each(intervals, fn interval ->
        args = %{
          site_id: site.domain,
          metric_name: "Signups",
          date_range: %{from: "2026-01-01", to: "2026-01-31"},
          interval: interval
        }

        {:ok, _time_series} = CustomMetrics.custom_metrics_time_series(nil, args, context)
      end)
    end
  end
end
