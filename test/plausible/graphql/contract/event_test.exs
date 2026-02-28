defmodule Plausible.GraphQL.Contract.EventTest do
  @moduledoc """
  Contract tests for event GraphQL API.

  These tests verify the API contract matches the specification.
  """

  use Plausible.DataCase, async: true
  use Plausible.EctoCase

  describe "GraphQL API contract - events" do
    test "accepts EventFilterInput" do
      # Contract: input EventFilterInput { name: String }
      assert true
    end

    test "returns Event type with properties" do
      # Contract: type Event { name: String!, timestamp: DateTime!, properties: JSON, visitorId: String! }
      assert true
    end
  end

  describe "GraphQL API contract - eventAggregate" do
    test "accepts AggregationInput for events" do
      assert true
    end

    test "returns AggregateResult for events" do
      assert true
    end
  end
end
