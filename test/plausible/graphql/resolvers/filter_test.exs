defmodule Plausible.GraphQL.Resolvers.FilterTest do
  @moduledoc """
  Unit tests for filter input handling in GraphQL resolvers.

  These tests verify that filter inputs are properly handled,
  transformed, and validated.
  """

  use ExUnit.Case, async: true

  alias Plausible.GraphQL.Resolvers.Filter

  describe "build_filters/1" do
    test "returns empty map when given nil" do
      assert Filter.build_filters(nil) == %{}
    end

    test "returns empty map when given empty map" do
      assert Filter.build_filters(%{}) == %{}
    end

    test "builds filter map from filter input" do
      filter_input = %{
        "url" => "/blog/*",
        "referrer" => "google.com"
      }

      assert Filter.build_filters(filter_input) == %{
        "url" => "/blog/*",
        "referrer" => "google.com"
      }
    end

    test "filters out nil values from filter input" do
      filter_input = %{
        "url" => "/blog/*",
        "referrer" => nil,
        "browser" => "Chrome"
      }

      assert Filter.build_filters(filter_input) == %{
        "url" => "/blog/*",
        "browser" => "Chrome"
      }
    end

    test "filters out all nil values when all are nil" do
      filter_input = %{
        "url" => nil,
        "referrer" => nil
      }

      assert Filter.build_filters(filter_input) == %{}
    end

    test "preserves atom keys when using atoms" do
      filter_input = %{
        url: "/blog/*",
        referrer: "google.com"
      }

      result = Filter.build_filters(filter_input)

      assert result[:url] == "/blog/*"
      assert result[:referrer] == "google.com"
    end
  end

  describe "validate_filters/1" do
    test "returns ok with empty map" do
      assert Filter.validate_filters(%{}) == {:ok, %{}}
    end

    test "returns ok with valid filters" do
      filters = %{
        "url" => "/blog/*",
        "referrer" => "google.com"
      }

      assert Filter.validate_filters(filters) == {:ok, filters}
    end

    test "returns error for non-map input" do
      assert Filter.validate_filters("invalid") == {:error, :invalid_filters}
      assert Filter.validate_filters([1, 2, 3]) == {:error, :invalid_filters}
    end
  end
end
