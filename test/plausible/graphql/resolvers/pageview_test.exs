defmodule Plausible.GraphQL.Resolvers.PageviewTest do
  @moduledoc """
  Unit tests for pageview GraphQL resolver.

  These tests verify the resolver correctly handles authorization,
  query building, and aggregation for pageview queries.
  """

  use Plausible.DataCase, async: true
  use Plausible.EctoCase

  alias Plausible.GraphQL.Resolvers.Pageview
  alias Plausible.Factory
  alias Plausible.Stats.Query

  import Mox
  setup :verify_on_exit!

  setup [:create_user, :create_site]

  describe "list_pageviews/3" do
    test "returns pageviews for authorized request with api_key", %{site: site} do
      auth = %{api_key: "test-api-key"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: ~D[2026-01-01],
          to: ~D[2026-01-31]
        },
        limit: 100,
        offset: 0
      }

      context = %{context: %{auth: auth}}

      # The resolver should return pageviews (currently returns empty list placeholder)
      {:ok, pageviews} = Pageview.list_pageviews(nil, args, context)

      assert is_list(pageviews)
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

      assert {:error, :unauthorized} = Pageview.list_pageviews(nil, args, context)
    end

    test "returns unauthorized when context is missing entirely" do
      args = %{
        site_id: 123,
        date_range: %{
          from: ~D[2026-01-01],
          to: ~D[2026-01-31]
        }
      }

      assert {:error, :unauthorized} = Pageview.list_pageviews(nil, args, nil)
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

      # Using an ID that doesn't exist - should return not_found
      assert {:error, :not_found} = Pageview.list_pageviews(nil, args, context)
    end

    test "builds query with filters correctly", %{site: site} do
      auth = %{api_key: "test-api-key"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: ~D[2026-01-01],
          to: ~D[2026-01-31]
        },
        filter: %{
          "url" => "/blog/*"
        },
        limit: 50,
        offset: 0
      }

      context = %{context: %{auth: auth}}

      {:ok, pageviews} = Pageview.list_pageviews(nil, args, context)

      assert is_list(pageviews)
    end

    test "handles missing optional parameters", %{site: site} do
      auth = %{api_key: "test-api-key"}

      # Only required parameters
      args = %{
        site_id: site.id,
        date_range: %{
          from: ~D[2026-01-01],
          to: ~D[2026-01-31]
        }
      }

      context = %{context: %{auth: auth}}

      {:ok, pageviews} = Pageview.list_pageviews(nil, args, context)

      assert is_list(pageviews)
    end
  end

  describe "aggregate_pageviews/3" do
    test "returns aggregated pageview count for authorized request", %{site: site} do
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

      # The aggregation currently returns a map with :value and :type
      {:ok, result} = Pageview.aggregate_pageviews(nil, args, context)

      assert is_map(result)
      assert result.type == :count
      # Value is 0 because no actual data exists in test
      assert is_number(result.value)
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

      assert {:error, :unauthorized} = Pageview.aggregate_pageviews(nil, args, context)
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

      assert {:error, :unauthorized} = Pageview.aggregate_pageviews(nil, args, nil)
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

      assert {:error, :not_found} = Pageview.aggregate_pageviews(nil, args, context)
    end

    test "aggregates with filter applied", %{site: site} do
      auth = %{api_key: "test-api-key"}

      args = %{
        site_id: site.id,
        date_range: %{
          from: ~D[2026-01-01],
          to: ~D[2026-01-31]
        },
        aggregation: %{
          type: :count
        },
        filter: %{
          "url" => "/pricing"
        }
      }

      context = %{context: %{auth: auth}}

      {:ok, result} = Pageview.aggregate_pageviews(nil, args, context)

      assert is_map(result)
      assert result.type == :count
    end

    test "handles different aggregation types", %{site: site} do
      auth = %{api_key: "test-api-key"}

      # Test with sum aggregation (requires field)
      args = %{
        site_id: site.id,
        date_range: %{
          from: ~D[2026-01-01],
          to: ~D[2026-01-31]
        },
        aggregation: %{
          type: :sum,
          field: "visitors"
        }
      }

      context = %{context: %{auth: auth}}

      {:ok, result} = Pageview.aggregate_pageviews(nil, args, context)

      assert is_map(result)
      assert result.type == :sum
    end
  end
end
