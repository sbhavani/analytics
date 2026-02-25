defmodule PlausibleWeb.GraphQL.AggregationTest do
  use PlausibleWeb.ConnCase, async: true

  alias PlausibleWeb.GraphQL.Resolvers.Helpers.Aggregation

  describe "Aggregation.to_stats_metrics/1" do
    test "returns empty list for nil input" do
      assert Aggregation.to_stats_metrics(nil) == []
    end

    test "converts COUNT type to visitors metric" do
      input = %{type: :count}
      assert Aggregation.to_stats_metrics(input) == ["visitors"]
    end

    test "converts SUM type with field to sum:field metric" do
      input = %{type: :sum, field: "value"}
      assert Aggregation.to_stats_metrics(input) == ["sum:value"]
    end

    test "converts AVG type with field to avg:field metric" do
      input = %{type: :avg, field: "time_on_page"}
      assert Aggregation.to_stats_metrics(input) == ["avg:time_on_page"]
    end

    test "converts MIN type with field to min:field metric" do
      input = %{type: :min, field: "pageviews"}
      assert Aggregation.to_stats_metrics(input) == ["min:pageviews"]
    end

    test "converts MAX type with field to max:field metric" do
      input = %{type: :max, field: "revenue"}
      assert Aggregation.to_stats_metrics(input) == ["max:revenue"]
    end

    test "returns visitors for unknown aggregation type" do
      input = %{type: :unknown}
      assert Aggregation.to_stats_metrics(input) == ["visitors"]
    end

    test "handles nil field by returning visitors metric" do
      input = %{type: :sum, field: nil}
      assert Aggregation.to_stats_metrics(input) == ["visitors"]
    end
  end

  describe "Aggregation.apply_aggregation/2" do
    test "returns count when type is COUNT" do
      results = [%{url: "/page1"}, %{url: "/page2"}, %{url: "/page3"}]
      aggregation = %{type: :count}

      assert Aggregation.apply_aggregation(results, aggregation) == %{count: 3}
    end

    test "returns original results when no aggregation specified" do
      results = [%{url: "/page1"}, %{url: "/page2"}]

      assert Aggregation.apply_aggregation(results, nil) == results
      assert Aggregation.apply_aggregation(results, %{}) == results
    end

    test "applies SUM aggregation on view_count field" do
      results = [%{view_count: 10}, %{view_count: 20}, %{view_count: 30}]
      aggregation = %{type: :sum}

      assert Aggregation.apply_aggregation(results, aggregation) == %{value: 60}
    end

    test "applies SUM aggregation on count field" do
      results = [%{count: 5}, %{count: 15}, %{count: 10}]
      aggregation = %{type: :sum}

      assert Aggregation.apply_aggregation(results, aggregation) == %{value: 30}
    end

    test "applies SUM aggregation on unique_visitors field" do
      results = [%{unique_visitors: 100}, %{unique_visitors: 200}]
      aggregation = %{type: :sum}

      assert Aggregation.apply_aggregation(results, aggregation) == %{value: 300}
    end

    test "applies SUM aggregation on value field" do
      results = [%{value: 1.5}, %{value: 2.5}, %{value: 3.0}]
      aggregation = %{type: :sum}

      assert Aggregation.apply_aggregation(results, aggregation) == %{value: 7.0}
    end

    test "applies AVG aggregation" do
      results = [%{value: 10}, %{value: 20}, %{value: 30}]
      aggregation = %{type: :avg}

      assert Aggregation.apply_aggregation(results, aggregation) == %{value: 20.0}
    end

    test "applies MIN aggregation" do
      results = [%{value: 50}, %{value: 20}, %{value: 30}]
      aggregation = %{type: :min}

      assert Aggregation.apply_aggregation(results, aggregation) == %{value: 20}
    end

    test "applies MAX aggregation" do
      results = [%{value: 50}, %{value: 20}, %{value: 30}]
      aggregation = %{type: :max}

      assert Aggregation.apply_aggregation(results, aggregation) == %{value: 50}
    end

    test "handles empty results list" do
      results = []
      aggregation = %{type: :sum}

      assert Aggregation.apply_aggregation(results, aggregation) == %{value: 0}
    end

    test "handles results with nil values" do
      results = [%{value: 10}, %{value: nil}, %{value: 20}]
      aggregation = %{type: :sum}

      assert Aggregation.apply_aggregation(results, aggregation) == %{value: 30}
    end

    test "handles results with missing numeric fields" do
      results = [%{url: "/page1"}, %{url: "/page2"}]
      aggregation = %{type: :sum}

      assert Aggregation.apply_aggregation(results, aggregation) == %{value: 0}
    end

    test "applies count for unknown aggregation type" do
      results = [%{url: "/page1"}, %{url: "/page2"}]
      aggregation = %{type: :unknown}

      assert Aggregation.apply_aggregation(results, aggregation) == %{count: 2}
    end
  end

  describe "Aggregation integration - end-to-end scenarios" do
    test "COUNT aggregation returns correct count for mixed results" do
      results = [
        %{url: "/page1", view_count: 100},
        %{url: "/page2", view_count: 200},
        %{url: "/page3", view_count: 300}
      ]

      aggregation = %{type: :count}
      assert Aggregation.apply_aggregation(results, aggregation) == %{count: 3}
    end

    test "SUM on multiple numeric fields prefers available fields" do
      results = [%{view_count: 10, count: 5}]

      aggregation = %{type: :sum}
      assert Aggregation.apply_aggregation(results, aggregation) == %{value: 10}
    end

    test "AVG with float values" do
      results = [%{value: 1.5}, %{value: 2.5}]
      aggregation = %{type: :avg}

      assert Aggregation.apply_aggregation(results, aggregation) == %{value: 2.0}
    end

    test "multiple aggregations on same data produce consistent results" do
      results = [%{value: 10}, %{value: 20}, %{value: 30}, %{value: 40}]

      assert Aggregation.apply_aggregation(results, %{type: :sum}) == %{value: 100}
      assert Aggregation.apply_aggregation(results, %{type: :avg}) == %{value: 25.0}
      assert Aggregation.apply_aggregation(results, %{type: :min}) == %{value: 10}
      assert Aggregation.apply_aggregation(results, %{type: :max}) == %{value: 40}
      assert Aggregation.apply_aggregation(results, %{type: :count}) == %{count: 4}
    end
  end
end
