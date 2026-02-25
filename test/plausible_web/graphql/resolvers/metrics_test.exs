defmodule PlausibleWeb.GraphQL.Resolvers.MetricsTest do
  use PlausibleWeb.ConnCase, async: false
  use Plausible.Repo

  alias PlausibleWeb.GraphQL.Resolvers.Metrics

  describe "list_custom_metrics/3" do
    test "returns empty list when site has no custom metrics" do
      site = insert(:site)

      result = Metrics.list_custom_metrics(nil, %{site_id: site.id}, nil)

      assert {:ok, []} = result
    end

    test "returns error when site is not found" do
      result = Metrics.list_custom_metrics(nil, %{site_id: "non-existent-site"}, nil)

      assert {:error, :site_not_found} = result
    end

    test "accepts date range in args" do
      site = insert(:site)

      args = %{
        site_id: site.id,
        date_range: %{
          from: "2024-01-01",
          to: "2024-01-31"
        }
      }

      result = Metrics.list_custom_metrics(nil, args, nil)

      assert {:ok, []} = result
    end

    test "handles nil date_range gracefully" do
      site = insert(:site)

      args = %{site_id: site.id, date_range: nil}

      result = Metrics.list_custom_metrics(nil, args, nil)

      assert {:ok, []} = result
    end

    test "handles missing date_range gracefully" do
      site = insert(:site)

      args = %{site_id: site.id}

      result = Metrics.list_custom_metrics(nil, args, nil)

      assert {:ok, []} = result
    end
  end
end
