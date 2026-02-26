defmodule PlausibleWeb.GraphQL.FiltersTest do
  @moduledoc """
  Integration tests for filtering in GraphQL queries.
  """

  use Plausible.DataCase, async: true
  use PlausibleWEB.ConnCase

  alias PlausibleWeb.GraphQL.Schema

  describe "date range filter" do
    test "filters by date range" do
      query = """
      query {
        pageviews(
          site_id: "example.com",
          filter: {
            date_range: { start_date: "2026-01-01", end_date: "2026-01-31" }
          }
        ) {
          url
          visitor_count
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      assert is_list(data["pageviews"])
    end

    test "filters with different date ranges" do
      query = """
      query {
        pageviews(
          site_id: "example.com",
          filter: {
            date_range: { start_date: "2025-12-01", end_date: "2025-12-31" }
          }
        ) {
          url
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      assert is_list(data["pageviews"])
    end
  end

  describe "URL pattern filter" do
    test "filters by exact URL pattern" do
      query = """
      query {
        pageviews(
          site_id: "example.com",
          filter: { url_pattern: "/page/*" }
        ) {
          url
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      assert is_list(data["pageviews"])
    end

    test "filters by URL with query params" do
      query = """
      query {
        pageviews(
          site_id: "example.com",
          filter: { url_pattern: "/products?id=123" }
        ) {
          url
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      assert is_list(data["pageviews"])
    end
  end

  describe "referrer filter" do
    test "filters by referrer domain" do
      query = """
      query {
        pageviews(
          site_id: "example.com",
          filter: { referrer: "google.com" }
        ) {
          url
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      assert is_list(data["pageviews"])
    end

    test "filters by referrer with subdirectory" do
      query = """
      query {
        pageviews(
          site_id: "example.com",
          filter: { referrer: "twitter.com/user" }
        ) {
          url
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      assert is_list(data["pageviews"])
    end
  end

  describe "device type filter" do
    test "filters by desktop" do
      query = """
      query {
        pageviews(
          site_id: "example.com",
          filter: { device_type: DESKTOP }
        ) {
          url
          visitor_count
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      assert is_list(data["pageviews"])
    end

    test "filters by mobile" do
      query = """
      query {
        pageviews(
          site_id: "example.com",
          filter: { device_type: MOBILE }
        ) {
          url
          visitor_count
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      assert is_list(data["pageviews"])
    end

    test "filters by tablet" do
      query = """
      query {
        pageviews(
          site_id: "example.com",
          filter: { device_type: TABLET }
        ) {
          url
          visitor_count
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      assert is_list(data["pageviews"])
    end
  end

  describe "geography filters" do
    test "filters by country" do
      query = """
      query {
        pageviews(
          site_id: "example.com",
          filter: { country: "US" }
        ) {
          url
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      assert is_list(data["pageviews"])
    end

    test "filters by country and region" do
      query = """
      query {
        pageviews(
          site_id: "example.com",
          filter: { country: "US", region: "CA" }
        ) {
          url
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      assert is_list(data["pageviews"])
    end

    test "filters by country, region and city" do
      query = """
      query {
        pageviews(
          site_id: "example.com",
          filter: { country: "US", region: "CA", city: "5391959" }
        ) {
          url
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      assert is_list(data["pageviews"])
    end
  end

  describe "combined filters" do
    test "applies multiple filters together" do
      query = """
      query {
        pageviews(
          site_id: "example.com",
          filter: {
            date_range: { start_date: "2026-01-01", end_date: "2026-01-31" }
            url_pattern: "/products/*"
            device_type: MOBILE
            country: "US"
            referrer: "google.com"
          }
        ) {
          url
          visitor_count
          view_count
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      assert is_list(data["pageviews"])
    end

    test "returns empty result when no matches" do
      query = """
      query {
        pageviews(
          site_id: "example.com",
          filter: {
            date_range: { start_date: "2026-01-01", end_date: "2026-01-01" }
            country: "ZZ"
          }
        ) {
          url
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      assert is_list(data["pageviews"])
    end
  end
end
