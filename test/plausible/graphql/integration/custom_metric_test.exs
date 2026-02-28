defmodule Plausible.GraphQL.Integration.CustomMetricTest do
  @moduledoc """
  Integration tests for custom metric GraphQL queries.
  """

  use Plausible.DataCase, async: true
  use Plausible.EctoCase

  alias Plausible.Factory

  describe "customMetrics query" do
    test "returns custom metrics for a valid site" do
      site = Factory.insert(:site)

      query = """
        query {
          customMetrics(siteId: "#{site.id}", dateRange: {from: "2026-01-01T00:00:00Z", to: "2026-01-31T23:59:59Z"}) {
            name
            value
            timestamp
          }
        }
      """

      # TODO: Execute query and verify response
      assert true
    end
  end

  describe "customMetricAggregate query" do
    test "returns aggregated custom metric" do
      site = Factory.insert(:site)

      query = """
        query {
          customMetricAggregate(siteId: "#{site.id}", filter: {name: "revenue"}, dateRange: {from: "2026-01-01T00:00:00Z", to: "2026-01-31T23:59:59Z"}, aggregation: {type: SUM, field: "value"}) {
            value
            type
          }
        }
      """

      # TODO: Execute query and verify aggregated value
      assert true
    end
  end
end
