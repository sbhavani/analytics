defmodule PlausibleWeb.GraphQL.PageviewQueryTest do
  use PlausibleWeb.ConnCase, async: true

  alias PlausibleWeb.GraphQL.Resolvers.Pageview
  alias PlausibleWeb.GraphQL.Resolvers.Helpers.{FilterParser, Aggregation}
  alias PlausibleWeb.GraphQL.Types.Pagination

  describe "PageviewResolver.list_pageviews/3" do
    setup [:create_user, :create_site]

    test "returns error when authentication is missing", %{site: site} do
      args = %{site_id: site.id}

      result = Pageview.list_pageviews(nil, args, %{context: %{}})

      assert {:error, "Authentication required"} = result
    end

    test "returns error when site is missing from context", %{site: site} do
      args = %{site_id: site.id}

      result = Pageview.list_pageviews(nil, args, %{context: %{site: nil}})

      assert {:error, "Authentication required"} = result
    end

    test "validates date range - returns error for range exceeding 1 year", %{site: site} do
      args = %{
        site_id: site.id,
        filter: %{
          from: ~U[2024-01-01 00:00:00Z],
          to: ~U[2026-01-01 00:00:00Z]
        }
      }

      result = Pageview.list_pageviews(nil, args, %{context: %{site: site}})

      assert {:error, "Invalid date range: maximum 1 year allowed"} = result
    end

    test "accepts valid date range within 1 year", %{site: site} do
      args = %{
        site_id: site.id,
        filter: %{
          from: ~U[2026-01-01 00:00:00Z],
          to: ~U[2026-01-31 00:00:00Z]
        }
      }

      result = Pageview.list_pageviews(nil, args, %{context: %{site: site}})

      assert {:ok, _results} = result
    end

    test "handles filter with url", %{site: site} do
      args = %{
        site_id: site.id,
        filter: %{
          from: ~U[2026-01-01 00:00:00Z],
          to: ~U[2026-01-31 00:00:00Z],
          url: "/test-page"
        }
      }

      result = Pageview.list_pageviews(nil, args, %{context: %{site: site}})

      assert {:ok, _results} = result
    end

    test "handles filter with country", %{site: site} do
      args = %{
        site_id: site.id,
        filter: %{
          from: ~U[2026-01-01 00:00:00Z],
          to: ~U[2026-01-31 00:00:00Z],
          country: "US"
        }
      }

      result = Pageview.list_pageviews(nil, args, %{context: %{site: site}})

      assert {:ok, _results} = result
    end

    test "handles filter with device", %{site: site} do
      args = %{
        site_id: site.id,
        filter: %{
          from: ~U[2026-01-01 00:00:00Z],
          to: ~U[2026-01-31 00:00:00Z],
          device: :mobile
        }
      }

      result = Pageview.list_pageviews(nil, args, %{context: %{site: site}})

      assert {:ok, _results} = result
    end

    test "handles pagination input", %{site: site} do
      args = %{
        site_id: site.id,
        filter: %{
          from: ~U[2026-01-01 00:00:00Z],
          to: ~U[2026-01-31 00:00:00Z]
        },
        pagination: %{
          limit: 10,
          offset: 0
        }
      }

      result = Pageview.list_pageviews(nil, args, %{context: %{site: site}})

      assert {:ok, _results} = result
    end

    test "handles aggregation input", %{site: site} do
      args = %{
        site_id: site.id,
        filter: %{
          from: ~U[2026-01-01 00:00:00Z],
          to: ~U[2026-01-31 00:00:00Z]
        },
        aggregation: %{
          type: :count
        }
      }

      result = Pageview.list_pageviews(nil, args, %{context: %{site: site}})

      assert {:ok, _results} = result
    end

    test "handles all filters combined", %{site: site} do
      args = %{
        site_id: site.id,
        filter: %{
          from: ~U[2026-01-01 00:00:00Z],
          to: ~U[2026-01-31 00:00:00Z],
          url: "/test-page",
          country: "US",
          device: :desktop,
          referrer: "https://example.com"
        },
        pagination: %{
          limit: 50,
          offset: 10
        },
        aggregation: %{
          type: :sum,
          field: "pageviews"
        }
      }

      result = Pageview.list_pageviews(nil, args, %{context: %{site: site}})

      assert {:ok, _results} = result
    end
  end

  describe "FilterParser.parse_pageview_filter/1" do
    test "parses empty filter" do
      result = FilterParser.parse_pageview_filter(%{})

      assert result == %{}
    end

    test "parses url filter" do
      result = FilterParser.parse_pageview_filter(%{url: "/test-page"})

      assert result == %{page: "/test-page"}
    end

    test "parses country filter" do
      result = FilterParser.parse_pageview_filter(%{country: "US"})

      assert result == %{country: "US"}
    end

    test "parses device filter and uppercases it" do
      result = FilterParser.parse_pageview_filter(%{device: :mobile})

      assert result == %{device: "MOBILE"}
    end

    test "parses referrer filter" do
      result = FilterParser.parse_pageview_filter(%{referrer: "https://example.com"})

      assert result == %{referrer: "https://example.com"}
    end

    test "parses multiple filters together" do
      result = FilterParser.parse_pageview_filter(%{
        url: "/test-page",
        country: "US",
        device: :desktop,
        referrer: "https://example.com"
      })

      assert result == %{
        page: "/test-page",
        country: "US",
        device: "DESKTOP",
        referrer: "https://example.com"
      }
    end
  end

  describe "FilterParser.validate_date_range/1" do
    test "accepts date range within 1 year" do
      result = FilterParser.validate_date_range(%{
        from: ~D[2026-01-01],
        to: ~D[2026-01-31]
      })

      assert result == :ok
    end

    test "accepts date range exactly 1 year" do
      result = FilterParser.validate_date_range(%{
        from: ~D[2025-01-01],
        to: ~D[2026-01-01]
      })

      assert result == :ok
    end

    test "rejects date range exceeding 1 year" do
      result = FilterParser.validate_date_range(%{
        from: ~D[2024-01-01],
        to: ~D[2026-01-01]
      })

      assert result == {:error, "Invalid date range: maximum 1 year allowed"}
    end

    test "handles missing date range gracefully" do
      result = FilterParser.validate_date_range(%{})

      assert result == :ok
    end

    test "handles nil input" do
      result = FilterParser.validate_date_range(nil)

      assert result == :ok
    end
  end

  describe "Pagination.from_input/1" do
    test "returns default for nil input" do
      result = Pagination.from_input(nil)

      assert result.limit == 100
      assert result.offset == 0
    end

    test "parses limit and offset" do
      result = Pagination.from_input(%{limit: 50, offset: 10})

      assert result.limit == 50
      assert result.offset == 10
    end

    test "enforces max limit" do
      result = Pagination.from_input(%{limit: 20_000})

      assert result.limit == 10_000
    end

    test "handles only limit" do
      result = Pagination.from_input(%{limit: 25})

      assert result.limit == 25
      assert result.offset == 0
    end

    test "handles only offset" do
      result = Pagination.from_input(%{offset: 50})

      assert result.limit == 100
      assert result.offset == 50
    end
  end

  describe "Aggregation.to_stats_metrics/1" do
    test "returns empty list for nil" do
      result = Aggregation.to_stats_metrics(nil)

      assert result == []
    end

    test "converts count aggregation" do
      result = Aggregation.to_stats_metrics(%{type: :count})

      assert result == ["visitors"]
    end

    test "converts sum aggregation with field" do
      result = Aggregation.to_stats_metrics(%{type: :sum, field: "pageviews"})

      assert result == ["sum:pageviews"]
    end

    test "converts avg aggregation with field" do
      result = Aggregation.to_stats_metrics(%{type: :avg, field: "time_on_page"})

      assert result == ["avg:time_on_page"]
    end

    test "defaults to visitors when field is nil" do
      result = Aggregation.to_stats_metrics(%{type: :sum, field: nil})

      assert result == ["visitors"]
    end

    test "handles min and max aggregations" do
      assert Aggregation.to_stats_metrics(%{type: :min, field: "time_on_page"}) == ["min:time_on_page"]
      assert Aggregation.to_stats_metrics(%{type: :max, field: "time_on_page"}) == ["max:time_on_page"]
    end
  end

  describe "Aggregation.apply_aggregation/2" do
    test "counts list items" do
      results = [%{a: 1}, %{a: 2}, %{a: 3}]
      aggregation = %{type: :count}

      result = Aggregation.apply_aggregation(results, aggregation)

      assert result == %{count: 3}
    end

    test "sums numeric values" do
      results = [%{view_count: 10}, %{view_count: 20}, %{view_count: 30}]
      aggregation = %{type: :sum}

      result = Aggregation.apply_aggregation(results, aggregation)

      assert result == %{value: 60}
    end

    test "averages numeric values" do
      results = [%{view_count: 10}, %{view_count: 20}]
      aggregation = %{type: :avg}

      result = Aggregation.apply_aggregation(results, aggregation)

      assert result == %{value: 15.0}
    end

    test "finds minimum value" do
      results = [%{view_count: 10}, %{view_count: 5}, %{view_count: 20}]
      aggregation = %{type: :min}

      result = Aggregation.apply_aggregation(results, aggregation)

      assert result == %{value: 5}
    end

    test "finds maximum value" do
      results = [%{view_count: 10}, %{view_count: 5}, %{view_count: 20}]
      aggregation = %{type: :max}

      result = Aggregation.apply_aggregation(results, aggregation)

      assert result == %{value: 20}
    end

    test "handles empty results" do
      results = []
      aggregation = %{type: :count}

      result = Aggregation.apply_aggregation(results, aggregation)

      assert result == %{count: 0}
    end

    test "handles results with no numeric values" do
      results = [%{url: "/a"}, %{url: "/b"}]
      aggregation = %{type: :sum}

      result = Aggregation.apply_aggregation(results, aggregation)

      assert result == %{value: 0}
    end
  end
end
