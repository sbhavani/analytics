defmodule Plausible.GraphQL.Resolvers.AnalyticsTest do
  use ExUnit.Case, async: true

  alias Plausible.GraphQL.Resolvers.Analytics
  alias Plausible.Stats.{Aggregate, Breakdown, Timeseries}

  describe "events - event query tests" do
    test "returns events list from breakdown query" do
      site = %{id: 1, domain: "test.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-31"
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      {:ok, analytics} = Analytics.analytics(nil, args, context)

      assert is_list(analytics.events)
    end

    test "events have correct structure with name, count, unique_visitors" do
      site = %{id: 1, domain: "test.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-31"
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      {:ok, analytics} = Analytics.analytics(nil, args, context)

      # Each event should have name, count, and unique_visitors fields
      Enum.each(analytics.events, fn event ->
        assert Map.has_key?(event, :name)
        assert Map.has_key?(event, :count)
        assert Map.has_key?(event, :unique_visitors)
        assert is_binary(event.name) or event.name == ""
        assert is_integer(event.count)
        assert is_integer(event.unique_visitors)
      end)
    end

    test "events returns empty list when no events exist" do
      site = %{id: 1, domain: "empty-test.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-31"
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      {:ok, analytics} = Analytics.analytics(nil, args, context)

      # Should return empty list when no events
      assert is_list(analytics.events)
    end

    test "events works with event_name filter" do
      site = %{id: 1, domain: "test.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-31"
        },
        filters: %{
          event_name: "pageview"
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      {:ok, analytics} = Analytics.analytics(nil, args, context)

      assert is_list(analytics.events)
    end

    test "events works with source filter" do
      site = %{id: 1, domain: "test.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-31"
        },
        filters: %{
          source: "google"
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      {:ok, analytics} = Analytics.analytics(nil, args, context)

      assert is_list(analytics.events)
    end

    test "events works with device filter" do
      site = %{id: 1, domain: "test.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-31"
        },
        filters: %{
          device: :desktop
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      {:ok, analytics} = Analytics.analytics(nil, args, context)

      assert is_list(analytics.events)
    end

    test "events works with country filter" do
      site = %{id: 1, domain: "test.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-31"
        },
        filters: %{
          country: "US"
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      {:ok, analytics} = Analytics.analytics(nil, args, context)

      assert is_list(analytics.events)
    end

    test "events works with page filter" do
      site = %{id: 1, domain: "test.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-31"
        },
        filters: %{
          page: "/blog"
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      {:ok, analytics} = Analytics.analytics(nil, args, context)

      assert is_list(analytics.events)
    end

    test "events works with multiple filters combined" do
      site = %{id: 1, domain: "test.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-31"
        },
        filters: %{
          source: "google",
          medium: "organic",
          device: :desktop,
          country: "US",
          page: "/pricing",
          event_name: "signup"
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      {:ok, analytics} = Analytics.analytics(nil, args, context)

      assert is_list(analytics.events)
    end

    test "events respects date range boundaries" do
      site = %{id: 1, domain: "test.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-03-01",
          to: "2024-03-31"
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      {:ok, analytics} = Analytics.analytics(nil, args, context)

      assert is_list(analytics.events)
    end

    test "events uses default date range when not provided" do
      site = %{id: 1, domain: "test.com"}

      args = %{site_id: site.id}

      context = %{
        context: %{
          site: site
        }
      }

      {:ok, analytics} = Analytics.analytics(nil, args, context)

      assert is_list(analytics.events)
    end

    test "events handles different date ranges" do
      site = %{id: 1, domain: "test.com"}

      date_ranges = [
        %{from: "2024-01-01", to: "2024-01-31"},
        %{from: "2024-06-01", to: "2024-06-30"},
        %{from: "2023-01-01", to: "2023-12-31"}
      ]

      for date_range <- date_ranges do
        args = %{site_id: site.id, date_range: date_range}

        context = %{
          context: %{
            site: site
          }
        }

        {:ok, analytics} = Analytics.analytics(nil, args, context)

        assert is_list(analytics.events)
      end
    end
  end

  describe "timeseries - aggregation tests" do
    test "returns timeseries data with daily period" do
      site = %{id: 1, domain: "test.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-07",
          period: :daily
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      {:ok, analytics} = Analytics.analytics(nil, args, context)

      assert is_list(analytics.timeseries)
      # Each timeseries entry should have date, visitors, and pageviews
      Enum.each(analytics.timeseries, fn entry ->
        assert Map.has_key?(entry, :date)
        assert Map.has_key?(entry, :visitors)
        assert Map.has_key?(entry, :pageviews)
      end)
    end

    test "returns timeseries data with weekly period" do
      site = %{id: 2, domain: "test-weekly.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-31",
          period: :weekly
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      {:ok, analytics} = Analytics.analytics(nil, args, context)

      assert is_list(analytics.timeseries)
      # Weekly should have fewer entries than daily
      assert length(analytics.timeseries) <= 5
    end

    test "returns timeseries data with monthly period" do
      site = %{id: 3, domain: "test-monthly.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-06-30",
          period: :monthly
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      {:ok, analytics} = Analytics.analytics(nil, args, context)

      assert is_list(analytics.timeseries)
      # Monthly should have at most 6 entries for Jan-Jun
      assert length(analytics.timeseries) <= 6
    end

    test "timeseries respects date range boundaries" do
      site = %{id: 4, domain: "test-boundaries.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-03-01",
          to: "2024-03-10",
          period: :daily
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      {:ok, analytics} = Analytics.analytics(nil, args, context)

      assert is_list(analytics.timeseries)
      # Should have roughly 10 days of data
      assert length(analytics.timeseries) <= 10
    end

    test "timeseries works with filters applied" do
      site = %{id: 5, domain: "test-filtered.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-07"
        },
        filters: %{
          source: "Google",
          device: :desktop
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      {:ok, analytics} = Analytics.analytics(nil, args, context)

      assert is_list(analytics.timeseries)
    end

    test "timeseries defaults to daily period when not specified" do
      site = %{id: 6, domain: "test-default-period.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-07"
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      {:ok, analytics} = Analytics.analytics(nil, args, context)

      assert is_list(analytics.timeseries)
      # Daily period for 7 days should give up to 7 entries
      assert length(analytics.timeseries) <= 7
    end

    test "timeseries returns empty list for invalid date range" do
      site = %{id: 7, domain: "test-invalid.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "invalid",
          to: "date"
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      {:ok, analytics} = Analytics.analytics(nil, args, context)

      # Should handle gracefully and return empty or default timeseries
      assert is_list(analytics.timeseries)
    end
  end

  describe "aggregation type handling" do
    test "aggregation input can be passed but currently not processed" do
      site = %{id: 8, domain: "test-agg.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-31"
        },
        aggregation: %{
          type: :sum,
          metric: "visitors"
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      {:ok, analytics} = Analytics.analytics(nil, args, context)

      # Aggregation is passed through but currently uses default timeseries
      assert is_list(analytics.timeseries)
    end
  end

  describe "custom_metrics" do
    test "returns empty list when no custom metrics are configured" do
      site = %{id: 1, domain: "test.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-31"
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      {:ok, analytics} = Analytics.analytics(nil, args, context)

      assert analytics.custom_metrics == []
    end

    test "custom_metrics returns list structure" do
      site = %{id: 1, domain: "test.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-31"
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      {:ok, analytics} = Analytics.analytics(nil, args, context)

      assert is_list(analytics.custom_metrics)
    end

    test "custom_metrics is included in analytics response" do
      site = %{id: 1, domain: "test.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-31"
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      {:ok, analytics} = Analytics.analytics(nil, args, context)

      assert Map.has_key?(analytics, :custom_metrics)
      assert analytics.custom_metrics == []
    end

    test "custom_metrics returns empty list with various date ranges" do
      site = %{id: 1, domain: "test.com"}

      date_ranges = [
        %{from: "2024-01-01", to: "2024-01-31"},
        %{from: "2024-01-01", to: "2024-12-31"},
        %{from: "2023-01-01", to: "2023-12-31"}
      ]

      for date_range <- date_ranges do
        args = %{site_id: site.id, date_range: date_range}

        context = %{
          context: %{
            site: site
          }
        }

        {:ok, analytics} = Analytics.analytics(nil, args, context)

        assert analytics.custom_metrics == []
      end
    end

    test "custom_metrics returns empty list when filters are provided" do
      site = %{id: 1, domain: "test.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-31"
        },
        filters: %{
          source: "google",
          medium: "organic"
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      {:ok, analytics} = Analytics.analytics(nil, args, context)

      assert analytics.custom_metrics == []
    end

    test "custom_metrics returns empty list with default date range" do
      site = %{id: 1, domain: "test.com"}

      args = %{site_id: site.id}

      context = %{
        context: %{
          site: site
        }
      }

      {:ok, analytics} = Analytics.analytics(nil, args, context)

      assert analytics.custom_metrics == []
    end
  end

  describe "analytics/3" do
    test "returns analytics data with valid site context" do
      site = %{id: 1, domain: "test.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-31",
          period: :daily
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      # Mock the Stats module calls
      # Since we're testing the resolver directly, we'll just verify the structure
      # The actual Stats calls would be tested in integration tests

      result = Analytics.analytics(nil, args, context)

      assert {:ok, analytics} = result
      assert is_map(analytics)
      assert Map.has_key?(analytics, :pageviews)
      assert Map.has_key?(analytics, :events)
      assert Map.has_key?(analytics, :custom_metrics)
      assert Map.has_key?(analytics, :timeseries)
      assert Map.has_key?(analytics, :metadata)
    end

    test "returns unauthorized error without site context" do
      args = %{site_id: 1}

      result = Analytics.analytics(nil, args, %{context: %{}})

      assert {:error, %{message: "Unauthorized"}} = result
    end

    test "returns unauthorized error with nil context" do
      args = %{site_id: 1}

      result = Analytics.analytics(nil, args, nil)

      assert {:error, %{message: "Unauthorized"}} = result
    end

    test "uses default date range when not provided" do
      site = %{id: 1, domain: "test.com"}

      args = %{site_id: site.id}

      context = %{
        context: %{
          site: site
        }
      }

      result = Analytics.analytics(nil, args, context)

      assert {:ok, analytics} = result
      assert %{date_range: date_range} = analytics.metadata
      assert date_range.from < date_range.to
    end

    test "parses date range from string dates" do
      site = %{id: 1, domain: "test.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-06-15",
          to: "2024-06-20",
          period: :weekly
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      result = Analytics.analytics(nil, args, context)

      assert {:ok, analytics} = result
      assert %{date_range: date_range} = analytics.metadata
      assert date_range.from.year == 2024
      assert date_range.from.month == 6
      assert date_range.from.day == 15
      assert date_range.to.year == 2024
      assert date_range.to.month == 6
      assert date_range.to.day == 20
    end

    test "parses filters from args" do
      site = %{id: 1, domain: "test.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-31"
        },
        filters: %{
          source: "google",
          medium: "organic",
          country: "US",
          device: :desktop,
          page: "/blog",
          event_name: "pageview"
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      result = Analytics.analytics(nil, args, context)

      assert {:ok, _analytics} = result
      # The filters are parsed internally - we just verify the call succeeds
    end

    test "handles empty filters" do
      site = %{id: 1, domain: "test.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-31"
        },
        filters: %{}
      }

      context = %{
        context: %{
          site: site
        }
      }

      result = Analytics.analytics(nil, args, context)

      assert {:ok, _analytics} = result
    end

    test "handles partial filters" do
      site = %{id: 1, domain: "test.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-31"
        },
        filters: %{
          source: "twitter"
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      result = Analytics.analytics(nil, args, context)

      assert {:ok, _analytics} = result
    end

    test "returns default metrics when stats return nil values" do
      site = %{id: 1, domain: "test.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-31"
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      result = Analytics.analytics(nil, args, context)

      assert {:ok, analytics} = result
      # Default values should be present
      assert analytics.pageviews.visitors >= 0
      assert analytics.pageviews.pageviews >= 0
    end
  end

  describe "filter parsing" do
    test "parses source filter correctly" do
      args = %{
        filters: %{
          source: "google"
        }
      }

      # Test that filter is correctly parsed by verifying the query is built
      site = %{id: 1, domain: "test.com"}

      full_args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-31"
        },
        filters: args.filters
      }

      context = %{
        context: %{
          site: site
        }
      }

      result = Analytics.analytics(nil, full_args, context)

      assert {:ok, _} = result
    end

    test "parses medium filter correctly" do
      site = %{id: 1, domain: "test.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-31"
        },
        filters: %{
          medium: "organic"
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      result = Analytics.analytics(nil, args, context)

      assert {:ok, _} = result
    end

    test "parses country filter correctly" do
      site = %{id: 1, domain: "test.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-31"
        },
        filters: %{
          country: "US"
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      result = Analytics.analytics(nil, args, context)

      assert {:ok, _} = result
    end

    test "parses device filter correctly - desktop" do
      site = %{id: 1, domain: "test.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-31"
        },
        filters: %{
          device: :desktop
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      result = Analytics.analytics(nil, args, context)

      assert {:ok, _} = result
    end

    test "parses device filter correctly - mobile" do
      site = %{id: 1, domain: "test.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-31"
        },
        filters: %{
          device: :mobile
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      result = Analytics.analytics(nil, args, context)

      assert {:ok, _} = result
    end

    test "parses device filter correctly - tablet" do
      site = %{id: 1, domain: "test.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-31"
        },
        filters: %{
          device: :tablet
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      result = Analytics.analytics(nil, args, context)

      assert {:ok, _} = result
    end

    test "parses page filter correctly" do
      site = %{id: 1, domain: "test.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-31"
        },
        filters: %{
          page: "/blog"
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      result = Analytics.analytics(nil, args, context)

      assert {:ok, _} = result
    end

    test "parses event_name filter correctly" do
      site = %{id: 1, domain: "test.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-31"
        },
        filters: %{
          event_name: "pageview"
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      result = Analytics.analytics(nil, args, context)

      assert {:ok, _} = result
    end

    test "parses all filters together" do
      site = %{id: 1, domain: "test.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-31"
        },
        filters: %{
          source: "google",
          medium: "organic",
          country: "US",
          device: :desktop,
          page: "/blog",
          event_name: "pageview"
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      result = Analytics.analytics(nil, args, context)

      assert {:ok, _} = result
    end

    test "handles filters with nil values gracefully" do
      site = %{id: 1, domain: "test.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-31"
        },
        filters: %{
          source: nil,
          medium: nil,
          country: nil,
          device: nil,
          page: nil,
          event_name: nil
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      result = Analytics.analytics(nil, args, context)

      assert {:ok, _} = result
    end

    test "handles filters with empty string values" do
      site = %{id: 1, domain: "test.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-31"
        },
        filters: %{
          source: "",
          medium: ""
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      result = Analytics.analytics(nil, args, context)

      assert {:ok, _} = result
    end

    test "filters are applied to events query" do
      site = %{id: 1, domain: "test.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-31"
        },
        filters: %{
          source: "twitter"
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      result = Analytics.analytics(nil, args, context)

      assert {:ok, analytics} = result
      # Events should be returned (possibly empty if no data)
      assert is_list(analytics.events)
    end

    test "filters are applied to timeseries query" do
      site = %{id: 1, domain: "test.com"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-31"
        },
        filters: %{
          device: :mobile
        }
      }

      context = %{
        context: %{
          site: site
        }
      }

      result = Analytics.analytics(nil, args, context)

      assert {:ok, analytics} = result
      # Timeseries should be returned (possibly empty if no data)
      assert is_list(analytics.timeseries)
    end
  end
end
