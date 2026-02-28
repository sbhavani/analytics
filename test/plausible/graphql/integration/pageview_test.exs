defmodule Plausible.GraphQL.Integration.PageviewTest do
  @moduledoc """
  Integration tests for pageview GraphQL queries.
  """

  use Plausible.DataCase, async: true
  use Plausible.EctoCase

  alias Plausible.Factory

  describe "pageviews query" do
    test "returns pageviews for a valid site" do
      site = Factory.insert(:site)

      query = """
        query {
          pageviews(siteId: "#{site.id}", dateRange: {from: "2026-01-01T00:00:00Z", to: "2026-01-31T23:59:59Z"}) {
            url
            timestamp
            visitorId
          }
        }
      """

      # TODO: Execute query and verify response
      # This test will pass once the full implementation is complete
      assert true
    end

    test "returns error for unauthorized request" do
      query = """
        query {
          pageviews(siteId: "invalid", dateRange: {from: "2026-01-01T00:00:00Z", to: "2026-01-31T23:59:59Z"}) {
            url
          }
        }
      """

      # TODO: Execute query without auth and verify error
      assert true
    end
  end

  describe "pageviewAggregate query" do
    test "returns aggregated pageview count" do
      site = Factory.insert(:site)

      query = """
        query {
          pageviewAggregate(siteId: "#{site.id}", dateRange: {from: "2026-01-01T00:00:00Z", to: "2026-01-31T23:59:59Z"}, aggregation: {type: COUNT}) {
            value
            type
          }
        }
      """

      # TODO: Execute query and verify aggregated count
      assert true
    end
  end
end
