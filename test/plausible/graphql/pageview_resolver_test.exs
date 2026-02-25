defmodule Plausible.GraphQL.PageviewResolverTest do
  use Plausible.DataCase, async: true

  alias Plausible.GraphQL.Resolvers.PageviewResolver

  describe "resolve_pageviews/3" do
    test "returns pageview data with valid arguments" do
      site = insert(:site, domain: "test.com")

      args = %{
        site_id: site.domain,
        date_range: %{
          start_date: "2026-01-01",
          end_date: "2026-01-31"
        }
      }

      context = %{site: site}

      result = PageviewResolver.resolve_pageviews(nil, args, context)

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

      result = PageviewResolver.resolve_pageviews(nil, args, %{})

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

      result = PageviewResolver.resolve_pageviews(nil, args, context)

      assert {:error, %{message: "Date range cannot exceed 366 days."}} = result
    end

    test "accepts pagination arguments" do
      site = insert(:site, domain: "test.com")

      args = %{
        site_id: site.domain,
        date_range: %{
          start_date: "2026-01-01",
          end_date: "2026-01-31"
        },
        pagination: %{
          limit: 50,
          offset: 10
        }
      }

      context = %{site: site}

      result = PageviewResolver.resolve_pageviews(nil, args, context)

      assert {:ok, response} = result
      assert response.pagination.limit == 50
      assert response.pagination.offset == 10
    end

    test "accepts filter arguments" do
      site = insert(:site, domain: "test.com")

      args = %{
        site_id: site.domain,
        date_range: %{
          start_date: "2026-01-01",
          end_date: "2026-01-31"
        },
        filters: %{
          url_pattern: "/page/*",
          device: "mobile"
        }
      }

      context = %{site: site}

      result = PageviewResolver.resolve_pageviews(nil, args, context)

      assert {:ok, _response} = result
    end
  end
end
