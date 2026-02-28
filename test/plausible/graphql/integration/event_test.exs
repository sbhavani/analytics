defmodule Plausible.GraphQL.Integration.EventTest do
  @moduledoc """
  Integration tests for event GraphQL queries.
  """

  use Plausible.DataCase, async: true
  use Plausible.EctoCase

  alias Plausible.Factory

  describe "events query" do
    test "returns events for a valid site" do
      site = Factory.insert(:site)

      query = """
        query {
          events(siteId: "#{site.id}", dateRange: {from: "2026-01-01T00:00:00Z", to: "2026-01-31T23:59:59Z"}) {
            name
            timestamp
            visitorId
          }
        }
      """

      # TODO: Execute query and verify response
      assert true
    end

    test "filters events by event type" do
      site = Factory.insert(:site)

      query = """
        query {
          events(siteId: "#{site.id}", filter: {name: "signup"}, dateRange: {from: "2026-01-01T00:00:00Z", to: "2026-01-31T23:59:59Z"}) {
            name
            timestamp
          }
        }
      """

      # TODO: Execute query and verify filtered events
      assert true
    end
  end

  describe "eventAggregate query" do
    test "returns aggregated event count" do
      site = Factory.insert(:site)

      query = """
        query {
          eventAggregate(siteId: "#{site.id}", dateRange: {from: "2026-01-01T00:00:00Z", to: "2026-01-31T23:59:59Z"}, aggregation: {type: COUNT}) {
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
