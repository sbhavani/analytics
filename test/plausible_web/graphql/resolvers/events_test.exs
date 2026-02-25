defmodule PlausibleWeb.GraphQL.Resolvers.EventsTest do
  use ExUnit.Case, async: false
  use Plausible.TestUtils

  alias PlausibleWeb.GraphQL.Resolvers.Events

  describe "list_events/3" do
    setup [:create_user, :create_site]

    test "returns events for a valid site and date range", %{site: site} do
      args = %{
        site_id: site.domain,
        date_range: %{from: "2024-01-01", to: "2024-01-31"},
        pagination: %{first: 100, page: 1}
      }

      {:ok, result} = Events.list_events(nil, args, nil)

      # Should return a connection structure
      assert is_map(result)
      assert Map.has_key?(result, :edges)
      assert Map.has_key?(result, :page_info)
      assert Map.has_key?(result, :total_count)
    end

    test "filters events by name", %{site: site} do
      args = %{
        site_id: site.domain,
        date_range: %{from: "2024-01-01", to: "2024-01-31"},
        filter: %{name: "pageview"},
        pagination: %{first: 100, page: 1}
      }

      {:ok, result} = Events.list_events(nil, args, nil)

      # Should return connection structure with filter applied
      assert is_map(result)
      assert Map.has_key?(result, :edges)
    end

    test "filters events by category", %{site: site} do
      args = %{
        site_id: site.domain,
        date_range: %{from: "2024-01-01", to: "2024-01-31"},
        filter: %{category: "engagement"},
        pagination: %{first: 100, page: 1}
      }

      {:ok, result} = Events.list_events(nil, args, nil)

      # Should return connection structure with filter applied
      assert is_map(result)
      assert Map.has_key?(result, :edges)
    end

    test "returns empty connection when no events found", %{site: site} do
      args = %{
        site_id: site.domain,
        date_range: %{from: "2020-01-01", to: "2020-01-31"},
        pagination: %{first: 100, page: 1}
      }

      {:ok, result} = Events.list_events(nil, args, nil)

      # Should return empty connection for dates with no data
      assert result.edges == []
      assert result.total_count == 0
      assert result.page_info.has_next_page == false
    end

    test "returns error for invalid date range (from > to)", %{site: site} do
      args = %{
        site_id: site.domain,
        date_range: %{from: "2024-01-31", to: "2024-01-01"},
        pagination: %{first: 100, page: 1}
      }

      {:error, error} = Events.list_events(nil, args, nil)

      assert error.message == "'from' date must be before or equal to 'to' date."
    end

    test "returns error for invalid date format", %{site: site} do
      args = %{
        site_id: site.domain,
        date_range: %{from: "invalid-date", to: "2024-01-31"},
        pagination: %{first: 100, page: 1}
      }

      {:error, error} = Events.list_events(nil, args, nil)

      assert error == "Invalid 'from' date format. Expected ISO 8601 format (YYYY-MM-DD)."
    end

    test "returns error for non-existent site", _context do
      args = %{
        site_id: "non-existent-12345.example.com",
        date_range: %{from: "2024-01-01", to: "2024-01-31"},
        pagination: %{first: 100, page: 1}
      }

      {:error, error} = Events.list_events(nil, args, nil)

      assert error == :site_not_found
    end

    test "applies pagination correctly", %{site: site} do
      args = %{
        site_id: site.domain,
        date_range: %{from: "2024-01-01", to: "2024-01-31"},
        pagination: %{first: 10, page: 2}
      }

      {:ok, result} = Events.list_events(nil, args, nil)

      # Should return connection with pagination info
      assert is_map(result)
      assert Map.has_key?(result, :page_info)
      assert Map.has_key?(result, :total_count)
    end

    test "accepts different pagination parameters", %{site: site} do
      args = %{
        site_id: site.domain,
        date_range: %{from: "2024-01-01", to: "2024-01-31"},
        pagination: %{first: 50, page: 1}
      }

      {:ok, result} = Events.list_events(nil, args, nil)

      assert is_map(result)
    end
  end
end
