defmodule PlausibleWeb.GraphQL.AggregationTest do
  @moduledoc """
  Tests for GraphQL aggregation functionality.
  """

  use ExUnit.Case, async: true

  alias PlausibleWeb.GraphQL.Helpers.AggregationHelper

  describe "parse_aggregation/1" do
    test "returns nil when aggregation is not provided" do
      assert AggregationHelper.parse_aggregation(nil) == {:ok, nil}
    end

    test "parses count aggregation type" do
      result = AggregationHelper.parse_aggregation(%{type: :count})
      assert {:ok, %{metrics: [:visitors], aggregation: :sum}} = result
    end

    test "parses sum aggregation type" do
      result = AggregationHelper.parse_aggregation(%{type: :sum, field: "value"})
      assert {:ok, %{metrics: [:sum_values], aggregation: :sum}} = result
    end

    test "parses average aggregation type" do
      result = AggregationHelper.parse_aggregation(%{type: :average})
      assert {:ok, %{metrics: [:average], aggregation: :avg}} = result
    end

    test "returns error for unknown aggregation type" do
      result = AggregationHelper.parse_aggregation(%{type: :unknown})
      assert {:error, "Unknown aggregation type: unknown"} = result
    end
  end

  describe "should_aggregate?/1" do
    test "returns false when aggregation is nil" do
      refute AggregationHelper.should_aggregate?(nil)
    end

    test "returns true when aggregation is provided" do
      assert AggregationHelper.should_aggregate?(%{type: :count})
    end

    test "returns true for empty map" do
      assert AggregationHelper.should_aggregate?(%{})
    end
  end

  describe "format_aggregate_result/3" do
    test "formats count aggregation result" do
      results = %{visitors: 1500}
      result = AggregationHelper.format_aggregate_result(results, :count)

      assert {:ok, %{
        aggregation_type: :count,
        value: 1500.0,
        dimension: nil
      }} = result
    end

    test "formats sum aggregation result" do
      results = %{sum_values: 2500.75}
      result = AggregationHelper.format_aggregate_result(results, :sum)

      assert {:ok, %{
        aggregation_type: :sum,
        value: 2500.75,
        dimension: nil
      }} = result
    end

    test "formats average aggregation result" do
      results = %{average: 45.5}
      result = AggregationHelper.format_aggregate_result(results, :average)

      assert {:ok, %{
        aggregation_type: :average,
        value: 45.5,
        dimension: nil
      }} = result
    end

    test "includes dimension when provided" do
      results = %{visitors: 100}
      result = AggregationHelper.format_aggregate_result(results, :count, "/blog")

      assert {:ok, %{
        aggregation_type: :count,
        value: 100.0,
        dimension: "/blog"
      }} = result
    end

    test "handles missing metrics gracefully" do
      results = %{}
      result = AggregationHelper.format_aggregate_result(results, :count)

      assert {:ok, %{
        aggregation_type: :count,
        value: 0.0,
        dimension: nil
      }} = result
    end

    test "rounds float values to 2 decimal places" do
      results = %{visitors: 1234.56789}
      result = AggregationHelper.format_aggregate_result(results, :count)

      assert {:ok, %{value: 1234.57}} = result
    end
  end
end
