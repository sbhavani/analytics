defmodule Plausible.GraphQL.Resolvers.EventTest do
  @moduledoc """
  Unit tests for event resolver.
  """

  use Plausible.DataCase, async: true
  use Plausible.EctoCase

  alias Plausible.GraphQL.Resolvers.Event
  alias Plausible.Factory

  describe "list_events/3" do
    test "returns events with valid site_id, date_range and auth" do
      site = Factory.insert(:site)

      args = %{
        site_id: site.id,
        date_range: %{from: ~D[2026-01-01], to: ~D[2026-01-31]},
        limit: 100,
        offset: 0
      }

      context = %{context: %{auth: %{api_key: "test-key"}}}

      result = Event.list_events(nil, args, context)

      assert {:ok, events} = result
      assert is_list(events)
    end

    test "returns events with filter" do
      site = Factory.insert(:site)

      args = %{
        site_id: site.id,
        date_range: %{from: ~D[2026-01-01], to: ~D[2026-01-31]},
        filter: %{name: "pageview"},
        limit: 100,
        offset: 0
      }

      context = %{context: %{auth: %{api_key: "test-key"}}}

      result = Event.list_events(nil, args, context)

      assert {:ok, events} = result
      assert is_list(events)
    end

    test "returns unauthorized without auth context" do
      site = Factory.insert(:site)

      args = %{
        site_id: site.id,
        date_range: %{from: ~D[2026-01-01], to: ~D[2026-01-31]},
        limit: 100,
        offset: 0
      }

      result = Event.list_events(nil, args, %{context: %{}})

      assert {:error, :unauthorized} = result
    end

    test "returns unauthorized with invalid auth" do
      site = Factory.insert(:site)

      args = %{
        site_id: site.id,
        date_range: %{from: ~D[2026-01-01], to: ~D[2026-01-31]},
        limit: 100,
        offset: 0
      }

      # Auth is not api_key or user
      context = %{context: %{auth: %{some_other_field: "value"}}}

      result = Event.list_events(nil, args, context)

      assert {:error, :unauthorized} = result
    end

    test "returns not_found for non-existent site" do
      args = %{
        site_id: "non-existent-id",
        date_range: %{from: ~D[2026-01-01], to: ~D[2026-01-31]},
        limit: 100,
        offset: 0
      }

      context = %{context: %{auth: %{api_key: "test-key"}}}

      result = Event.list_events(nil, args, context)

      assert {:error, :not_found} = result
    end
  end

  describe "aggregate_events/3" do
    test "returns aggregated events with valid params and auth" do
      site = Factory.insert(:site)

      args = %{
        site_id: site.id,
        date_range: %{from: ~D[2026-01-01], to: ~D[2026-01-31]},
        aggregation: :count
      }

      context = %{context: %{auth: %{api_key: "test-key"}}}

      result = Event.aggregate_events(nil, args, context)

      assert {:ok, _result} = result
    end

    test "returns aggregated events with filter" do
      site = Factory.insert(:site)

      args = %{
        site_id: site.id,
        date_range: %{from: ~D[2026-01-01], to: ~D[2026-01-31]},
        filter: %{name: "event"},
        aggregation: :count
      }

      context = %{context: %{auth: %{api_key: "test-key"}}}

      result = Event.aggregate_events(nil, args, context)

      assert {:ok, _result} = result
    end

    test "returns unauthorized without auth context" do
      site = Factory.insert(:site)

      args = %{
        site_id: site.id,
        date_range: %{from: ~D[2026-01-01], to: ~D[2026-01-31]},
        aggregation: :count
      }

      result = Event.aggregate_events(nil, args, %{context: %{}})

      assert {:error, :unauthorized} = result
    end

    test "returns unauthorized with invalid auth" do
      site = Factory.insert(:site)

      args = %{
        site_id: site.id,
        date_range: %{from: ~D[2026-01-01], to: ~D[2026-01-31]},
        aggregation: :count
      }

      context = %{context: %{auth: %{user_id: 123}}}

      result = Event.aggregate_events(nil, args, context)

      assert {:error, :unauthorized} = result
    end

    test "returns not_found for non-existent site" do
      args = %{
        site_id: "non-existent-id",
        date_range: %{from: ~D[2026-01-01], to: ~D[2026-01-31]},
        aggregation: :count
      }

      context = %{context: %{auth: %{api_key: "test-key"}}}

      result = Event.aggregate_events(nil, args, context)

      assert {:error, :not_found} = result
    end
  end
end
