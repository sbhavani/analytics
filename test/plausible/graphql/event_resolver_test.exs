defmodule Plausible.GraphQL.EventResolverTest do
  use Plausible.DataCase, async: true

  alias Plausible.GraphQL.Resolvers.EventResolver

  describe "resolve_events/3" do
    test "returns event data with valid arguments" do
      site = insert(:site, domain: "test.com")

      args = %{
        site_id: site.domain,
        date_range: %{
          start_date: "2026-01-01",
          end_date: "2026-01-31"
        }
      }

      context = %{site: site}

      result = EventResolver.resolve_events(nil, args, context)

      assert {:ok, response} = result
      assert is_map(response)
      assert Map.has_key?(response, :data)
      assert Map.has_key?(response, :pagination)
      assert Map.has_key?(response, :total)
    end

    test "returns error when site context is missing" do
      args = %{
        site_id: "test.com",
        date_range: %{
          start_date: "2026-01-01",
          end_date: "2026-01-31"
        }
      }

      result = EventResolver.resolve_events(nil, args, %{})

      assert {:error, %{message: "Site context required"}} = result
    end

    test "validates date range does not exceed 366 days" do
      site = insert(:site, domain: "test.com")

      args = %{
        site_id: site.domain,
        date_range: %{
          start_date: "2025-01-01",
          end_date: "2026-01-31"
        }
      }

      context = %{site: site}

      result = EventResolver.resolve_events(nil, args, context)

      assert {:error, %{message: "Date range cannot exceed 366 days."}} = result
    end

    test "accepts event name filter" do
      site = insert(:site, domain: "test.com")

      args = %{
        site_id: site.domain,
        date_range: %{
          start_date: "2026-01-01",
          end_date: "2026-01-31"
        },
        filters: %{
          event_name: "signup"
        }
      }

      context = %{site: site}

      result = EventResolver.resolve_events(nil, args, context)

      assert {:ok, _response} = result
    end

    test "accepts event properties filter" do
      site = insert(:site, domain: "test.com")

      args = %{
        site_id: site.domain,
        date_range: %{
          start_date: "2026-01-01",
          end_date: "2026-01-31"
        },
        filters: %{
          event_name: "cta_click",
          properties: %{"button_id" => "signup"}
        }
      }

      context = %{site: site}

      result = EventResolver.resolve_events(nil, args, context)

      assert {:ok, _response} = result
    end
  end
end
