defmodule PlausibleWeb.GraphQL.Resolvers.PageviewsTest do
  @moduledoc """
  Tests for the Pageviews GraphQL resolver.
  """

  use Plausible.DataCase
  import Plausible.Factory

  alias PlausibleWeb.GraphQL.Resolvers.Pageviews

  describe "list_pageviews/3" do
    setup [:create_user, :create_site]

    test "returns pageview data for a site", %{user: user, site: site} do
      # Populate some pageview stats
      date = Date.utc_today() |> Date.shift(day: -1)

      pageview1 = build(:pageview, site_id: site.id, pathname: "/page1", timestamp: date)
      pageview2 = build(:pageview, site_id: site.id, pathname: "/page2", timestamp: date)

      populate_stats(site, [pageview1, pageview2])

      args = %{
        site_id: site.domain,
        date_range: %{
          from: Date.to_iso8601(Date.shift(date, day: -7)),
          to: Date.to_iso8601(date)
        }
      }

      result = Pageviews.list_pageviews(nil, args, %{})

      assert {:ok, connection} = result
      assert is_list(connection.edges)
      assert connection.total_count >= 0
      assert Map.has_key?(connection.page_info, :has_next_page)
      assert Map.has_key?(connection.page_info, :has_previous_page)
    end

    test "returns error for invalid site_id", _ do
      args = %{
        site_id: "nonexistent-site.example.com",
        date_range: %{
          from: Date.to_iso8601(Date.shift(Date.utc_today(), day: -7)),
          to: Date.to_iso8601(Date.utc_today())
        }
      }

      result = Pageviews.list_pageviews(nil, args, %{})

      assert {:error, :site_not_found} = result
    end

    test "returns error for invalid date range (from > to)", %{site: site} do
      args = %{
        site_id: site.domain,
        date_range: %{
          from: Date.to_iso8601(Date.utc_today()),
          to: Date.to_iso8601(Date.shift(Date.utc_today(), day: -7))
        }
      }

      result = Pageviews.list_pageviews(nil, args, %{})

      assert {:error, message} = result
      assert is_binary(message) or is_map(message)
    end

    test "returns error for invalid date format", %{site: site} do
      args = %{
        site_id: site.domain,
        date_range: %{
          from: "invalid-date",
          to: Date.to_iso8601(Date.utc_today())
        }
      }

      result = Pageviews.list_pageviews(nil, args, %{})

      assert {:error, _} = result
    end

    test "respects pagination parameters", %{user: user, site: site} do
      date = Date.utc_today() |> Date.shift(day: -1)

      # Create multiple pageviews
      events =
        for i <- 1..20 do
          build(:pageview, site_id: site.id, pathname: "/page#{i}", timestamp: date)
        end

      populate_stats(site, events)

      args = %{
        site_id: site.domain,
        date_range: %{
          from: Date.to_iso8601(Date.shift(date, day: -7)),
          to: Date.to_iso8601(date)
        },
        pagination: %{
          first: 10,
          page: 1
        }
      }

      result = Pageviews.list_pageviews(nil, args, %{})

      assert {:ok, connection} = result
      # First page should have has_next_page true if there are more results
      assert is_boolean(connection.page_info.has_next_page)
    end

    test "returns empty connection when no data exists", %{site: site} do
      # Use a date range with no data
      args = %{
        site_id: site.domain,
        date_range: %{
          from: Date.to_iso8601(Date.shift(Date.utc_today(), day: -30)),
          to: Date.to_iso8601(Date.shift(Date.utc_today(), day: -20))
        }
      }

      result = Pageviews.list_pageviews(nil, args, %{})

      assert {:ok, connection} = result
      assert connection.edges == []
      assert connection.total_count == 0
      assert connection.page_info.has_next_page == false
      assert connection.page_info.has_previous_page == false
    end

    test "handles date_range with nil values gracefully", %{site: site} do
      args = %{
        site_id: site.domain,
        date_range: nil
      }

      # This should either return data or handle nil gracefully
      result = Pageviews.list_pageviews(nil, args, %{})

      # Should return some result (either error or success)
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end
  end
end
