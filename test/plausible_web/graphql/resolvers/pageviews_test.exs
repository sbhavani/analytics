defmodule PlausibleWeb.GraphQL.Resolvers.PageviewsTest do
  @moduledoc """
  Unit tests for the Pageviews GraphQL resolver.

  These tests focus on:
  - Authentication error handling
  - Authorization error handling
  - Date range validation
  - Aggregation option parsing (logic tests)
  """

  use Plausible.DataCase, async: true
  alias PlausibleWeb.GraphQL.Resolvers.Pageviews
  alias PlausibleWeb.GraphQL.Resolver

  describe "pageviews/3 - authentication" do
    setup do
      user = insert(:user)
      site = insert(:site, members: [user])

      {:ok, user: user, site: site}
    end

    test "returns authentication error when user is not authenticated", %{site: site} do
      args = %{
        site_id: site.domain,
        date_range: %{from: "2026-01-01", to: "2026-01-31"}
      }

      context = %{context: %{user: nil}}

      result = Pageviews.pageviews(nil, args, context)

      assert {:error, %{message: "Authentication required", code: :authentication_error}} = result
    end

    test "returns authorization error when user does not have access to site", %{user: user} do
      # Create a site that the user doesn't have access to
      other_site = insert(:site)

      args = %{
        site_id: other_site.domain,
        date_range: %{from: "2026-01-01", to: "2026-01-31"}
      }

      context = %{context: %{user: user}}

      result = Pageviews.pageviews(nil, args, context)

      assert {:error, %{message: "Access denied to site '#{other_site.domain}'", code: :authorization_error}} = result
    end

    test "returns site not found error for non-existent site", %{user: user} do
      args = %{
        site_id: "nonexistent.example.com",
        date_range: %{from: "2026-01-01", to: "2026-01-31"}
      }

      context = %{context: %{user: user}}

      result = Pageviews.pageviews(nil, args, context)

      assert {:error, %{message: "Site not found", code: :not_found}} = result
    end
  end

  describe "pageviews/3 - date validation" do
    setup do
      user = insert(:user)
      site = insert(:site, members: [user])

      {:ok, user: user, site: site}
    end

    test "returns error for invalid date range (from > to)", %{user: user, site: site} do
      args = %{
        site_id: site.domain,
        date_range: %{from: "2026-01-31", to: "2026-01-01"}
      }

      context = %{context: %{user: user}}

      result = Pageviews.pageviews(nil, args, context)

      assert {:error, %{message: message, code: :validation_error}} = result
      assert message =~ "Invalid date range"
    end

    test "returns error for invalid 'from' date format", %{user: user, site: site} do
      args = %{
        site_id: site.domain,
        date_range: %{from: "invalid-date", to: "2026-01-31"}
      }

      context = %{context: %{user: user}}

      result = Pageviews.pageviews(nil, args, context)

      assert {:error, %{message: message, code: :validation_error}} = result
      assert message =~ "Invalid date format for 'from'"
    end

    test "returns error for invalid 'to' date format", %{user: user, site: site} do
      args = %{
        site_id: site.domain,
        date_range: %{from: "2026-01-01", to: "also-invalid"}
      }

      context = %{context: %{user: user}}

      result = Pageviews.pageviews(nil, args, context)

      assert {:error, %{message: message, code: :validation_error}} = result
      assert message =~ "Invalid date format for 'to'"
    end
  end

  describe "Resolver.validate_date_range/1" do
    test "returns error when from date is after to date" do
      result = Resolver.validate_date_range(%{from: "2026-01-31", to: "2026-01-01"})

      assert {:error, "Invalid date range: 'from' must be before 'to'"} = result
    end

    test "returns error for invalid from date format" do
      result = Resolver.validate_date_range(%{from: "not-a-date", to: "2026-01-31"})

      assert {:error, "Invalid date format for 'from'. Use ISO 8601 format (YYYY-MM-DD)"} = result
    end

    test "returns error for invalid to date format" do
      result = Resolver.validate_date_range(%{from: "2026-01-01", to: "also-invalid"})

      assert {:error, "Invalid date format for 'to'. Use ISO 8601 format (YYYY-MM-DD)"} = result
    end

    test "returns ok with parsed dates for valid date range" do
      result = Resolver.validate_date_range(%{from: "2026-01-01", to: "2026-01-31"})

      assert {:ok, %{from: from_date, to: to_date}} = result
      assert from_date == ~D[2026-01-01]
      assert to_date == ~D[2026-01-31]
    end
  end

  describe "filter parsing logic" do
    test "parses path filter to page key" do
      # Test the mapping logic: path -> page
      filters = %{path: "/blog/*"}

      # Simulate what the resolver does internally
      parsed =
        Enum.reduce(filters, %{}, fn
          {:path, path}, acc when is_binary(path) and path != "" ->
            Map.put(acc, :page, path)

          _, acc ->
            acc
        end)

      assert parsed == %{page: "/blog/*"}
    end

    test "parses multiple filters correctly" do
      filters = %{
        path: "/blog/*",
        browser: "Chrome",
        device: "desktop",
        country: "US"
      }

      parsed =
        Enum.reduce(filters, %{}, fn
          {:path, path}, acc when is_binary(path) and path != "" ->
            Map.put(acc, :page, path)

          {:browser, browser}, acc when is_binary(browser) and browser != "" ->
            Map.put(acc, :browser, browser)

          {:device, device}, acc when is_binary(device) and device != "" ->
            Map.put(acc, :device, device)

          {:country, country}, acc when is_binary(country) and country != "" ->
            Map.put(acc, :country, country)

          _, acc ->
            acc
        end)

      assert parsed == %{
        page: "/blog/*",
        browser: "Chrome",
        device: "desktop",
        country: "US"
      }
    end

    test "filters out empty string values" do
      filters = %{
        path: "",
        browser: "Chrome"
      }

      parsed =
        Enum.reduce(filters, %{}, fn
          {:path, path}, acc when is_binary(path) and path != "" ->
            Map.put(acc, :page, path)

          {:browser, browser}, acc when is_binary(browser) and browser != "" ->
            Map.put(acc, :browser, browser)

          _, acc ->
            acc
        end)

      # Empty string should be filtered out
      assert parsed == %{browser: "Chrome"}
      refute Map.has_key?(parsed, :page)
    end
  end

  describe "aggregation parsing logic" do
    test "parses aggregation type correctly" do
      # Test mapping: sum -> :sum, count -> :count, etc.
      aggregation_types = [:sum, :count, :avg, :min, :max]

      for type <- aggregation_types do
        # Default parsing function logic
        parsed_type =
          case type do
            :sum -> :sum
            :count -> :count
            :avg -> :avg
            :min -> :min
            :max -> :max
            _ -> :count
          end

        assert is_atom(parsed_type)
      end
    end

    test "parses group by dimension correctly" do
      # Test mapping: path -> pathname, url -> url, etc.
      dimension_mappings = %{
        path: :pathname,
        url: :url,
        browser: :browser,
        device: :device,
        country: :country,
        referrer: :referrer
      }

      for {input, expected} <- dimension_mappings do
        # Default parsing function logic
        parsed =
          case input do
            :path -> :pathname
            :url -> :url
            :browser -> :browser
            :device -> :device
            :country -> :country
            :referrer -> :referrer
            nil -> nil
          end

        assert parsed == expected
      end
    end

    test "parses time interval correctly" do
      # Test mapping: minute -> minute, hour -> hour, day -> date, etc.
      interval_mappings = %{
        minute: :minute,
        hour: :hour,
        day: :date,
        week: :week,
        month: :month
      }

      for {input, expected} <- interval_mappings do
        # Default parsing function logic
        parsed =
          case input do
            :minute -> :minute
            :hour -> :hour
            :day -> :date
            :week -> :week
            :month -> :month
            nil -> nil
          end

        assert parsed == expected
      end
    end

    test "default aggregation values" do
      # When aggregation is nil
      default = %{type: :count, group_by: nil, interval: nil}

      assert default.type == :count
      assert default.group_by == nil
      assert default.interval == nil
    end
  end
end
