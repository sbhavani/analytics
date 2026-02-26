defmodule PlausibleWeb.GraphQL.Resolvers.EventsTest do
  @moduledoc """
  Unit tests for the Events resolver module.
  Tests the public interface of the Events resolver.
  """

  use ExUnit.Case, async: true

  # Import the resolver module to test
  alias PlausibleWeb.GraphQL.Resolvers.Events

  describe "events/3 - authentication" do
    test "returns authentication error when user is not authenticated" do
      args = %{
        site_id: "example.com",
        date_range: %{from: "2026-01-01", to: "2026-01-31"}
      }

      context = %{context: %{user: nil}}

      assert {:error, message: "Authentication required", code: :authentication_error} =
               Events.events(nil, args, context)
    end
  end

  describe "events/3 - authorization" do
    test "returns not found error when site does not exist" do
      # Use a dummy user for this test
      user = %Plausible.User{id: 1}

      args = %{
        site_id: "nonexistent-site-domain.com",
        date_range: %{from: "2026-01-01", to: "2026-01-31"}
      }

      context = %{context: %{user: user}}

      assert {:error, message: "Site not found", code: :not_found} =
               Events.events(nil, args, context)
    end
  end

  describe "events/3 - date validation" do
    test "returns validation error for invalid date format (from)" do
      # We'll test date validation through the Resolver module
      # which has validate_date_range function
      assert {:error, message: "Invalid date format for 'from'. Use ISO 8601 format (YYYY-MM-DD)"} =
               PlausibleWeb.GraphQL.Resolver.validate_date_range(%{
                 from: "invalid-date",
                 to: "2026-01-31"
               })
    end

    test "returns validation error for invalid date format (to)" do
      assert {:error, message: "Invalid date format for 'to'. Use ISO 8601 format (YYYY-MM-DD)"} =
               PlausibleWeb.GraphQL.Resolver.validate_date_range(%{
                 from: "2026-01-01",
                 to: "invalid-date"
               })
    end

    test "returns validation error when from is after to" do
      assert {:error, message: "Invalid date range: 'from' must be before 'to'"} =
               PlausibleWeb.GraphQL.Resolver.validate_date_range(%{
                 from: "2026-01-31",
                 to: "2026-01-01"
               })
    end

    test "returns default date range when nil is provided" do
      assert {:ok, %{from: from, to: to}} = PlausibleWeb.GraphQL.Resolver.validate_date_range(nil)
      assert Date.diff(to, from) == 30
    end

    test "accepts valid date range" do
      assert {:ok, %{from: from, to: to}} =
               PlausibleWeb.GraphQL.Resolver.validate_date_range(%{
                 from: "2026-01-01",
                 to: "2026-01-31"
               })

      assert from == ~D[2026-01-01]
      assert to == ~D[2026-01-31]
    end
  end
end
