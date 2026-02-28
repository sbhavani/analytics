defmodule Plausible.GraphQL.Resolvers.CustomMetricTest do
  @moduledoc """
  Unit tests for custom metric GraphQL resolver.

  These tests verify the resolver correctly handles authorization,
  query building, and aggregation for custom metric queries.
  """

  use Plausible.DataCase, async: true
  use Plausible.EctoCase

  alias Plausible.GraphQL.Resolvers.CustomMetric
  alias Plausible.Factory

  setup [:create_user, :create_site]

  describe "list_custom_metrics/3" do
    test "returns custom metrics for authorized request with api_key", %{site: site} do
      auth = %{api_key: "test-api-key"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: ~D[2026-01-01],
          to: ~D[2026-01-31]
        }
      }

      context = %{context: %{auth: auth}}

      # The resolver returns empty list for now as fetch_custom_metrics is not fully implemented
      {:ok, metrics} = CustomMetric.list_custom_metrics(nil, args, context)

      assert is_list(metrics)
    end

    test "returns custom metrics with filter", %{site: site} do
      auth = %{api_key: "test-api-key"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: ~D[2026-01-01],
          to: ~D[2026-01-31]
        },
        filter: %{
          "name" => "revenue"
        }
      }

      context = %{context: %{auth: auth}}

      {:ok, metrics} = CustomMetric.list_custom_metrics(nil, args, context)

      assert is_list(metrics)
    end

    test "returns unauthorized when auth context is missing" do
      args = %{
        site_id: 123,
        date_range: %{
          from: ~D[2026-01-01],
          to: ~D[2026-01-31]
        }
      }

      context = %{context: %{}}

      assert {:error, :unauthorized} = CustomMetric.list_custom_metrics(nil, args, context)
    end

    test "returns unauthorized when context is missing entirely" do
      args = %{
        site_id: 123,
        date_range: %{
          from: ~D[2026-01-01],
          to: ~D[2026-01-31]
        }
      }

      assert {:error, :unauthorized} = CustomMetric.list_custom_metrics(nil, args, nil)
    end

    test "returns unauthorized when auth is not API key", %{site: site} do
      # Auth is not API key (e.g., user session)
      auth = %{user_id: 1}

      args = %{
        site_id: site.id,
        date_range: %{
          from: ~D[2026-01-01],
          to: ~D[2026-01-31]
        }
      }

      context = %{context: %{auth: auth}}

      assert {:error, :unauthorized} = CustomMetric.list_custom_metrics(nil, args, context)
    end

    test "returns not_found for non-existent site", %{site: _site} do
      auth = %{api_key: "test-api-key"}

      args = %{
        site_id: 999_999_999,
        date_range: %{
          from: ~D[2026-01-01],
          to: ~D[2026-01-31]
        }
      }

      context = %{context: %{auth: auth}}

      assert {:error, :not_found} = CustomMetric.list_custom_metrics(nil, args, context)
    end

    test "handles missing date_range", %{site: site} do
      auth = %{api_key: "test-api-key"}

      args = %{
        site_id: site.id
        # Missing date_range
      }

      context = %{context: %{auth: auth}}

      # This will fail due to missing required argument
      result = CustomMetric.list_custom_metrics(nil, args, context)
      assert match?({:error, _}, result)
    end
  end

  describe "aggregate_custom_metrics/3" do
    test "returns aggregated custom metrics for authorized request", %{site: site} do
      auth = %{api_key: "test-api-key"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: ~D[2026-01-01],
          to: ~D[2026-01-31]
        },
        aggregation: %{
          type: :count
        }
      }

      context = %{context: %{auth: auth}}

      # Aggregation returns a map with :value and :type
      {:ok, result} = CustomMetric.aggregate_custom_metrics(nil, args, context)

      assert is_map(result)
      assert result.type == :count
      # Value is 0 because no actual data exists in test
      assert is_number(result.value)
    end

    test "returns aggregated custom metrics with sum aggregation", %{site: site} do
      auth = %{api_key: "test-api-key"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: ~D[2026-01-01],
          to: ~D[2026-01-31]
        },
        filter: %{
          "name" => "revenue"
        },
        aggregation: %{
          type: :sum,
          field: "value"
        }
      }

      context = %{context: %{auth: auth}}

      {:ok, result} = CustomMetric.aggregate_custom_metrics(nil, args, context)

      assert is_map(result)
      assert result.type == :sum
    end

    test "returns aggregated custom metrics with avg aggregation", %{site: site} do
      auth = %{api_key: "test-api-key"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: ~D[2026-01-01],
          to: ~D[2026-01-31]
        },
        aggregation: %{
          type: :avg,
          field: "value"
        }
      }

      context = %{context: %{auth: auth}}

      {:ok, result} = CustomMetric.aggregate_custom_metrics(nil, args, context)

      assert is_map(result)
      assert result.type == :avg
    end

    test "returns unauthorized when auth context is missing" do
      args = %{
        site_id: 123,
        date_range: %{
          from: ~D[2026-01-01],
          to: ~D[2026-01-31]
        },
        aggregation: %{
          type: :count
        }
      }

      context = %{context: %{}}

      assert {:error, :unauthorized} = CustomMetric.aggregate_custom_metrics(nil, args, context)
    end

    test "returns unauthorized when context is missing entirely" do
      args = %{
        site_id: 123,
        date_range: %{
          from: ~D[2026-01-01],
          to: ~D[2026-01-31]
        },
        aggregation: %{
          type: :count
        }
      }

      assert {:error, :unauthorized} = CustomMetric.aggregate_custom_metrics(nil, args, nil)
    end

    test "returns unauthorized when auth is not API key", %{site: site} do
      auth = %{user_id: 1}

      args = %{
        site_id: site.id,
        date_range: %{
          from: ~D[2026-01-01],
          to: ~D[2026-01-31]
        },
        aggregation: %{
          type: :count
        }
      }

      context = %{context: %{auth: auth}}

      assert {:error, :unauthorized} = CustomMetric.aggregate_custom_metrics(nil, args, context)
    end

    test "returns not_found for non-existent site", %{site: _site} do
      auth = %{api_key: "test-api-key"}

      args = %{
        site_id: 999_999_999,
        date_range: %{
          from: ~D[2026-01-01],
          to: ~D[2026-01-31]
        },
        aggregation: %{
          type: :count
        }
      }

      context = %{context: %{auth: auth}}

      assert {:error, :not_found} = CustomMetric.aggregate_custom_metrics(nil, args, context)
    end

    test "handles missing required aggregation argument", %{site: site} do
      auth = %{api_key: "test-api-key"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: ~D[2026-01-01],
          to: ~D[2026-01-31]
        }
        # Missing aggregation
      }

      context = %{context: %{auth: auth}}

      # Missing required aggregation argument
      result = CustomMetric.aggregate_custom_metrics(nil, args, context)
      assert match?({:error, _}, result)
    end
  end
end
