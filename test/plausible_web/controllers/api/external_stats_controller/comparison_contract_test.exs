defmodule PlausibleWeb.Api.ExternalStatsController.ComparisonContractTest do
  @moduledoc """
  Contract tests for the Time Period Comparison API.

  These tests verify the API contract defined in:
  specs/002-time-period-comparison/contracts/query-parameters.md

  Acceptance Criteria:
  1. Setting comparison=previous_period returns comparison metrics with change fields
  2. Setting comparison=custom with valid dates returns comparison data
  3. Setting comparison=off returns no comparison data
  """
  use PlausibleWeb.ConnCase

  setup [:create_user, :create_site, :create_api_key, :use_api_key]

  describe "comparison contract - previous_period mode" do
    test "returns comparison data with change fields when comparison=previous_period", %{
      conn: conn,
      site: site
    } do
      # Populate data for current period (Jan 2021)
      populate_stats(site, [
        build(:pageview, timestamp: ~N[2021-01-01 00:00:00]),
        build(:pageview, timestamp: ~N[2021-01-01 00:00:00]),
        build(:pageview, timestamp: ~N[2021-01-01 00:01:00]),
        build(:pageview, timestamp: ~N[2021-01-01 10:00:00])
      ])

      # Populate data for comparison period (Dec 2020)
      populate_stats(site, [
        build(:pageview, timestamp: ~N[2020-12-01 00:00:00]),
        build(:pageview, timestamp: ~N[2020-12-01 00:00:00]),
        build(:pageview, timestamp: ~N[2020-12-01 00:00:00])
      ])

      conn =
        get(conn, "/api/v1/stats/aggregate", %{
          "site_id" => site.domain,
          "period" => "month",
          "date" => "2021-01-01",
          "metrics" => "visitors,pageviews",
          "comparison" => "previous_period"
        })

      response = json_response(conn, 200)

      # Verify main metrics are returned
      assert response["results"]["visitors"]["value"] == 4

      # Verify comparison_value is returned (contract requirement)
      assert response["results"]["visitors"]["comparison_value"] == 3

      # Verify change is returned (contract requirement: percentage change)
      # (4-3)/3 * 100 = 33%
      assert response["results"]["visitors"]["change"] == 33
    end
  end

  describe "comparison contract - custom mode" do
    test "returns comparison data when comparison=custom with valid dates", %{
      conn: conn,
      site: site
    } do
      populate_stats(site, [
        build(:pageview, timestamp: ~N[2021-01-01 00:00:00]),
        build(:pageview, timestamp: ~N[2021-01-01 00:00:00]),
        build(:pageview, timestamp: ~N[2020-01-01 00:00:00]),
        build(:pageview, timestamp: ~N[2020-01-05 00:00:00]),
        build(:pageview, timestamp: ~N[2020-01-10 00:00:00])
      ])

      conn =
        get(conn, "/api/v1/stats/aggregate", %{
          "site_id" => site.domain,
          "period" => "day",
          "date" => "2021-01-01",
          "metrics" => "visitors",
          "comparison" => "custom",
          "compare_from" => "2020-01-01",
          "compare_to" => "2020-01-10"
        })

      response = json_response(conn, 200)

      # Verify main metrics
      assert response["results"]["visitors"]["value"] == 2

      # Verify comparison_value is returned
      assert response["results"]["visitors"]["comparison_value"] == 3

      # Verify change is returned (-33% as current is less than previous)
      assert response["results"]["visitors"]["change"] == -33
    end

    test "returns 400 error when comparison=custom without compare_from", %{
      conn: conn,
      site: site
    } do
      conn =
        get(conn, "/api/v1/stats/aggregate", %{
          "site_id" => site.domain,
          "period" => "day",
          "date" => "2021-01-01",
          "metrics" => "visitors",
          "comparison" => "custom",
          "compare_to" => "2020-01-10"
        })

      assert json_response(conn, 400)
    end

    test "returns 400 error when comparison=custom without compare_to", %{
      conn: conn,
      site: site
    } do
      conn =
        get(conn, "/api/v1/stats/aggregate", %{
          "site_id" => site.domain,
          "period" => "day",
          "date" => "2021-01-01",
          "metrics" => "visitors",
          "comparison" => "custom",
          "compare_from" => "2020-01-01"
        })

      assert json_response(conn, 400)
    end
  end

  describe "comparison contract - disabled" do
    test "returns no comparison data when comparison=off", %{
      conn: conn,
      site: site
    } do
      populate_stats(site, [
        build(:pageview, timestamp: ~N[2021-01-01 00:00:00]),
        build(:pageview, timestamp: ~N[2021-01-01 00:00:00]),
        build(:pageview, timestamp: ~N[2020-12-01 00:00:00])
      ])

      conn =
        get(conn, "/api/v1/stats/aggregate", %{
          "site_id" => site.domain,
          "period" => "month",
          "date" => "2021-01-01",
          "metrics" => "visitors",
          "comparison" => "off"
        })

      response = json_response(conn, 200)

      # Verify main metric is returned
      assert response["results"]["visitors"]["value"] == 2

      # Verify comparison_value is NOT returned when comparison is off
      assert response["results"]["visitors"]["comparison_value"] == nil

      # Verify change is NOT returned when comparison is off
      assert response["results"]["visitors"]["change"] == nil
    end
  end

  describe "comparison contract - year_over_year mode" do
    test "returns comparison data when comparison=year_over_year", %{
      conn: conn,
      site: site
    } do
      populate_stats(site, [
        build(:pageview, timestamp: ~N[2021-01-01 00:00:00]),
        build(:pageview, timestamp: ~N[2021-01-01 00:00:00]),
        build(:pageview, timestamp: ~N[2020-01-01 00:00:00])
      ])

      conn =
        get(conn, "/api/v1/stats/aggregate", %{
          "site_id" => site.domain,
          "period" => "month",
          "date" => "2021-01-01",
          "metrics" => "visitors",
          "comparison" => "year_over_year"
        })

      response = json_response(conn, 200)

      # Verify comparison_value is returned
      assert response["results"]["visitors"]["comparison_value"] == 1

      # Verify change is returned (100% increase)
      assert response["results"]["visitors"]["change"] == 100
    end
  end

  describe "comparison contract - zero value metrics" do
    test "displays N/A for zero-value metrics change (FR-008)", %{
      conn: conn,
      site: site
    } do
      # Current period has 0 visitors
      populate_stats(site, [])

      # Previous period has visitors
      populate_stats(site, [
        build(:pageview, timestamp: ~N[2020-12-01 00:00:00])
      ])

      conn =
        get(conn, "/api/v1/stats/aggregate", %{
          "site_id" => site.domain,
          "period" => "month",
          "date" => "2021-01-01",
          "metrics" => "visitors",
          "comparison" => "previous_period"
        })

      response = json_response(conn, 200)

      # Verify main metric is 0
      assert response["results"]["visitors"]["value"] == 0

      # Verify comparison_value is returned
      assert response["results"]["visitors"]["comparison_value"] == 1

      # Verify change is -100 when going from 1 to 0
      assert response["results"]["visitors"]["change"] == -100
    end
  end
end
