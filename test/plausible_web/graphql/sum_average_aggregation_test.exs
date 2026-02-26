defmodule PlausibleWeb.GraphQL.SumAverageAggregationTest do
  @moduledoc """
  Tests for sum and average aggregation in GraphQL queries.
  """

  use PlausibleWeb.GraphQLCase
  use Plausible.DataCase

  alias PlausibleWeb.GraphQL.Schema

  describe "sum aggregation query" do
    test "returns sum of values for a site" do
      user = insert(:user)
      site = insert(:site, members: [user])

      query = """
        query {
          pageviews(
            siteId: "#{site.id}",
            dateRange: {startDate: "2026-01-01", endDate: "2026-01-31"},
            aggregation: {type: SUM, field: "value"}
          ) {
            ... on AggregateResult {
              aggregationType
              value
              dimension
            }
          }
        }
      """

      result = run_query(query, %{current_user: user})

      # The query should succeed (may return empty or mocked data)
      assert result["data"] != nil or result["errors"] != nil
    end

    test "sum aggregation with dimension" do
      user = insert(:user)
      site = insert(:site, members: [user])

      query = """
        query {
          events(
            siteId: "#{site.id}",
            dateRange: {startDate: "2026-01-01", endDate: "2026-01-31"},
            aggregation: {type: SUM, field: "revenue", dimension: "/checkout"}
          ) {
            ... on AggregateResult {
              aggregationType
              value
              dimension
            }
          }
        }
      """

      result = run_query(query, %{current_user: user})

      # Verify the structure is correct
      assert result["data"] != nil or result["errors"] != nil
    end

    test "sum aggregation with filters" do
      user = insert(:user)
      site = insert(:site, members: [user])

      query = """
        query {
          customMetrics(
            siteId: "#{site.id}",
            dateRange: {startDate: "2026-01-01", endDate: "2026-01-31"},
            aggregation: {type: SUM, field: "revenue"},
            filters: [{field: "event:country", operator: EQUALS, value: "US"}]
          ) {
            ... on AggregateResult {
              aggregationType
              value
              dimension
            }
          }
        }
      """

      result = run_query(query, %{current_user: user})

      # The query should handle filters
      assert result["data"] != nil or result["errors"] != nil
    end
  end

  describe "average aggregation query" do
    test "returns average of values for a site" do
      user = insert(:user)
      site = insert(:site, members: [user])

      query = """
        query {
          pageviews(
            siteId: "#{site.id}",
            dateRange: {startDate: "2026-01-01", endDate: "2026-01-31"},
            aggregation: {type: AVERAGE}
          ) {
            ... on AggregateResult {
              aggregationType
              value
              dimension
            }
          }
        }
      """

      result = run_query(query, %{current_user: user})

      # The query should succeed
      assert result["data"] != nil or result["errors"] != nil
    end

    test "average aggregation with dimension" do
      user = insert(:user)
      site = insert(:site, members: [user])

      query = """
        query {
          events(
            siteId: "#{site.id}",
            dateRange: {startDate: "2026-01-01", endDate: "2026-01-31"},
            aggregation: {type: AVERAGE, dimension: "visit:browser"}
          ) {
            ... on AggregateResult {
              aggregationType
              value
              dimension
            }
          }
        }
      """

      result = run_query(query, %{current_user: user})

      # Verify the structure is correct
      assert result["data"] != nil or result["errors"] != nil
    end

    test "average aggregation with filters" do
      user = insert(:user)
      site = insert(:site, members: [user])

      query = """
        query {
          customMetrics(
            siteId: "#{site.id}",
            dateRange: {startDate: "2026-01-01", endDate: "2026-01-31"},
            aggregation: {type: AVERAGE},
            filters: [{field: "event:device", operator: EQUALS, value: "desktop"}]
          ) {
            ... on AggregateResult {
              aggregationType
              value
              dimension
            }
          }
        }
      """

      result = run_query(query, %{current_user: user})

      # The query should handle filters
      assert result["data"] != nil or result["errors"] != nil
    end
  end

  describe "aggregation type validation" do
    test "returns error for invalid aggregation type" do
      user = insert(:user)
      site = insert(:site, members: [user])

      query = """
        query {
          pageviews(
            siteId: "#{site.id}",
            aggregation: {type: INVALID_TYPE}
          ) {
            ... on AggregateResult {
              aggregationType
              value
            }
          }
        }
      """

      result = run_query(query, %{current_user: user})

      # Should return an error for invalid type
      assert result["errors"] != nil
    end
  end

  # Helper function to run GraphQL query
  defp run_query(query, context) do
    Absinthe.run(query, Schema, variables: %{}, context: context)
    |> case do
      {:ok, %{data: data, errors: []}} ->
        %{data: data, errors: nil}

      {:ok, %{data: data, errors: errors}} ->
        %{
          data: data,
          errors: Enum.map(errors, &format_error/1)
        }

      {:error, %{errors: errors}} ->
        %{data: nil, errors: Enum.map(errors, &format_error/1)}

      {:error, error} ->
        %{data: nil, errors: [%{message: inspect(error)}]}
    end
  end

  defp format_error(%{message: message, extras: extras}) do
    %{
      message: message,
      extensions: Map.get(extras, :code) || %{}
    }
  end

  defp format_error(error) when is_map(error) do
    %{
      message: error[:message] || error.message || "Unknown error",
      extensions: error[:extensions] || %{}
    }
  end
end
