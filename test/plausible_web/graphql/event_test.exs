defmodule PlausibleWeb.GraphQL.EventTest do
  @moduledoc """
  Tests for the GraphQL events query.
  """

  use PlausibleWeb.GraphQLCase
  use Plausible.DataCase

  alias PlausibleWeb.GraphQL.Schema

  describe "events query" do
    test "returns unauthorized when not authenticated" do
      query = """
        query {
          events(siteId: "123") {
            ... on EventConnection {
              edges {
                node {
                  id
                  name
                }
              }
              totalCount
            }
          }
        }
      """

      result = run_query(query, nil)

      assert result["errors"] != nil
      assert [%{"message" => "Authentication required"}] = result["errors"]
    end

    test "returns site not found for invalid site ID" do
      user = insert(:user)

      query = """
        query {
          events(siteId: "999999") {
            ... on EventConnection {
              edges {
                node {
                  id
                  name
                }
              }
              totalCount
            }
          }
        }
      """

      result = run_query(query, %{current_user: user})

      assert result["errors"] != nil

      assert [%{"message" => "Site not found", "extensions" => %{"code" => "NOT_FOUND"}}] =
               result["errors"]
    end

    test "returns events for valid site with date range" do
      user = insert(:user)
      site = insert(:site, members: [user])

      query = """
        query {
          events(siteId: "#{site.id}", dateRange: {startDate: "2026-01-01", endDate: "2026-01-31"}) {
            ... on EventConnection {
              edges {
                node {
                  id
                  name
                  timestamp
                  visitorId
                }
                cursor
              }
              pageInfo {
                hasNextPage
                endCursor
              }
              totalCount
            }
          }
        }
      """

      result = run_query(query, %{current_user: user})

      # The resolver uses Stats.breakdown which returns data
      # Test verifies the query structure is correct
      assert result["data"] != nil
    end

    test "returns events with pagination" do
      user = insert(:user)
      site = insert(:site, members: [user])

      query = """
        query {
          events(
            siteId: "#{site.id}",
            dateRange: {startDate: "2026-01-01", endDate: "2026-01-31"},
            pagination: {first: 10, after: nil}
          ) {
            ... on EventConnection {
              edges {
                node {
                  id
                  name
                }
              }
              pageInfo {
                hasNextPage
                endCursor
              }
              totalCount
            }
          }
        }
      """

      result = run_query(query, %{current_user: user})

      assert result["data"] != nil
    end

    test "returns events with filters" do
      user = insert(:user)
      site = insert(:site, members: [user])

      query = """
        query {
          events(
            siteId: "#{site.id}",
            dateRange: {startDate: "2026-01-01", endDate: "2026-01-31"},
            filters: [{field: "name", operator: EQUALS, value: "signup"}]
          ) {
            ... on EventConnection {
              edges {
                node {
                  id
                  name
                }
              }
              totalCount
            }
          }
        }
      """

      result = run_query(query, %{current_user: user})

      assert result["data"] != nil
    end

    test "returns aggregated events with aggregation input" do
      user = insert(:user)
      site = insert(:site, members: [user])

      query = """
        query {
          events(
            siteId: "#{site.id}",
            dateRange: {startDate: "2026-01-01", endDate: "2026-01-31"},
            aggregation: {type: COUNT}
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

      assert result["data"] != nil
    end

    test "returns aggregated events with dimension" do
      user = insert(:user)
      site = insert(:site, members: [user])

      query = """
        query {
          events(
            siteId: "#{site.id}",
            dateRange: {startDate: "2026-01-01", endDate: "2026-01-31"},
            aggregation: {type: COUNT, dimension: "event_name"}
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

      assert result["data"] != nil
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
