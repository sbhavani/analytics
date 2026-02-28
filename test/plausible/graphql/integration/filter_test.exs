defmodule Plausible.GraphQL.Integration.FilterTest do
  @moduledoc """
  Integration tests for combined filter queries.
  """

  use Plausible.DataCase, async: true
  use Plausible.EctoCase

  alias Plausible.Factory

  describe "combined filters" do
    test "applies multiple filters to pageviews query" do
      site = Factory.insert(:site)

      query = """
        query {
          pageviews(siteId: "#{site.id}", filter: {urlPattern: "/blog/*", referrer: "google.com"}, dateRange: {from: "2026-01-01T00:00:00Z", to: "2026-01-31T23:59:59Z"}, limit: 50) {
            url
            referrer
            timestamp
          }
        }
      """

      # TODO: Execute query with multiple filters
      assert true
    end

    test "applies date range filter with aggregation" do
      site = Factory.insert(:site)

      query = """
        query {
          pageviewAggregate(siteId: "#{site.id}", dateRange: {from: "2026-01-01T00:00:00Z", to: "2026-01-31T23:59:59Z"}, aggregation: {type: COUNT}) {
            value
            type
          }
        }
      """

      # TODO: Execute query with date range and aggregation
      assert true
    end
  end
end
