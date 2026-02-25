defmodule Plausible.GraphQL.MetricResolverTest do
  use Plausible.DataCase, async: true

  alias Plausible.GraphQL.Resolvers.MetricResolver

  describe "resolve_metrics/3" do
    test "returns metric data with valid arguments" do
      site = insert(:site, domain: "test.com")

      args = %{
        site_id: site.domain,
        date_range: %{
          start_date: "2026-01-01",
          end_date: "2026-01-31"
        },
        filters: %{
          metric_name: "revenue"
        }
      }

      context = %{site: site}

      result = MetricResolver.resolve_metrics(nil, args, context)

      assert {:ok, response} = result
      assert is_map(response)
      assert Map.has_key?(response, :data)
      assert Map.has_key?(response, :pagination)
      assert Map.has_key?(response, :aggregated)
    end

    test "returns error when site context is missing" do
      args = %{
        site_id: "test.com",
        date_range: %{
          start_date: "2026-01-01",
          end_date: "2026-01-31"
        },
        filters: %{
          metric_name: "revenue"
        }
      }

      result = MetricResolver.resolve_metrics(nil, args, %{})

      assert {:error, %{message: "Site context and metric name required"}} = result
    end

    test "returns error when metric_name is missing" do
      site = insert(:site, domain: "test.com")

      args = %{
        site_id: site.domain,
        date_range: %{
          start_date: "2026-01-01",
          end_date: "2026-01-31"
        },
        filters: %{}
      }

      context = %{site: site}

      result = MetricResolver.resolve_metrics(nil, args, context)

      assert {:error, %{message: "metric_name is required"}} = result
    end

    test "validates date range does not exceed 366 days" do
      site = insert(:site, domain: "test.com")

      args = %{
        site_id: site.domain,
        date_range: %{
          start_date: "2025-01-01",
          end_date: "2026-01-31"
        },
        filters: %{
          metric_name: "revenue"
        }
      }

      context = %{site: site}

      result = MetricResolver.resolve_metrics(nil, args, context)

      assert {:error, %{message: "Date range cannot exceed 366 days."}} = result
    end

    test "accepts aggregation arguments" do
      site = insert(:site, domain: "test.com")

      args = %{
        site_id: site.domain,
        date_range: %{
          start_date: "2026-01-01",
          end_date: "2026-01-31"
        },
        filters: %{
          metric_name: "revenue"
        },
        aggregation: %{
          function: :sum,
          granularity: :day
        }
      }

      context = %{site: site}

      result = MetricResolver.resolve_metrics(nil, args, context)

      assert {:ok, _response} = result
    end
  end
end
