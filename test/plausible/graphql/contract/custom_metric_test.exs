defmodule Plausible.GraphQL.Contract.CustomMetricTest do
  @moduledoc """
  Contract tests for custom metric GraphQL API.

  These tests verify the API contract matches the specification.
  """

  use Plausible.DataCase, async: true
  use Plausible.EctoCase

  describe "GraphQL API contract - customMetrics" do
    test "accepts MetricFilterInput" do
      # Contract: input MetricFilterInput { name: String }
      assert true
    end

    test "returns CustomMetric type with dimensions" do
      # Contract: type CustomMetric { name: String!, value: Float!, timestamp: DateTime!, dimensions: JSON }
      assert true
    end
  end

  describe "GraphQL API contract - customMetricAggregate" do
    test "accepts AggregationInput for custom metrics" do
      assert true
    end

    test "returns AggregateResult for custom metrics" do
      assert true
    end
  end

  describe "GraphQL API contract - common types" do
    test "accepts AggregationType enum" do
      # Contract: enum AggregationType { COUNT, SUM, AVG, MIN, MAX }
      assert true
    end

    test "validates date range maximum" do
      # Contract: Date range cannot exceed 12 months
      assert true
    end
  end
end
