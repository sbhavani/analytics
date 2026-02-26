defmodule PlausibleWeb.GraphQL.CustomMetricsTest do
  @moduledoc """
  Integration tests for custom metrics GraphQL queries.
  """

  use Plausible.DataCase, async: true
  use PlausibleWEB.ConnCase

  alias PlausibleWeb.GraphQL.Schema

  describe "custom_metrics query" do
    test "returns custom metrics for a site" do
      query = """
      query {
        custom_metrics(site_id: "example.com") {
          name
          value
          formula
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      assert is_list(data["custom_metrics"])
    end

    test "returns custom metrics with date filter" do
      query = """
      query {
        custom_metrics(
          site_id: "example.com",
          filter: { date_range: { start_date: "2026-01-01", end_date: "2026-01-31" } }
        ) {
          name
          value
          formula
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      assert is_list(data["custom_metrics"])
    end

    test "returns custom metrics with all filters" do
      query = """
      query {
        custom_metrics(
          site_id: "example.com",
          filter: {
            date_range: { start_date: "2026-01-01", end_date: "2026-01-31" }
            device_type: MOBILE
            country: "US"
          }
        ) {
          name
          value
          formula
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      assert is_list(data["custom_metrics"])
    end
  end
end
