defmodule PlausibleWeb.GraphQL.Logger do
  @moduledoc """
  Structured logging utilities for GraphQL operations.

  Provides consistent logging across all GraphQL resolvers with:
  - Operation names
  - User context (sanitized)
  - Site IDs being queried
  - Query parameters (sanitized)
  - Duration metrics
  - Result status
  """

  require Logger

  @doc """
  Log the start of a GraphQL resolver operation with context.
  """
  def log_operation_start(operation, args, context) do
    Logger.info(
      "GraphQL operation started",
      operation: operation,
      site_id: sanitize_site_id(args[:site_id]),
      user_id: get_user_id(context),
      has_filters: has_filters?(args),
      has_aggregation: has_aggregation?(args),
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    )
  end

  @doc """
  Log the successful completion of a GraphQL resolver operation.
  """
  def log_operation_success(operation, args, context, result_count, duration_ms) do
    Logger.info(
      "GraphQL operation completed",
      operation: operation,
      site_id: sanitize_site_id(args[:site_id]),
      user_id: get_user_id(context),
      result_count: result_count,
      duration_ms: duration_ms,
      status: :success,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    )
  end

  @doc """
  Log a failed GraphQL resolver operation.
  """
  def log_operation_error(operation, args, context, error, duration_ms) do
    Logger.warning(
      "GraphQL operation failed",
      operation: operation,
      site_id: sanitize_site_id(args[:site_id]),
      user_id: get_user_id(context),
      error_type: error_type(error),
      error_message: error_message(error),
      duration_ms: duration_ms,
      status: :error,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    )
  end

  @doc """
  Log GraphQL context building (authentication).
  """
  def log_context_build(context, auth_method) do
    Logger.info(
      "GraphQL context built",
      user_id: get_user_id(context),
      auth_method: auth_method,
      authenticated: context[:user] != nil,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    )
  end

  @doc """
  Log authorization result.
  """
  def log_authorization(user_id, site_id, authorized) do
    Logger.info(
      "GraphQL authorization",
      user_id: user_id,
      site_id: sanitize_site_id(site_id),
      authorized: authorized,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    )
  end

  # Helper functions

  defp get_user_id(%{user: user}) when user != nil do
    Map.get(user, :id) || Map.get(user, :email) || "api_key"
  end

  defp get_user_id(_), do: nil

  defp sanitize_site_id(nil), do: nil
  defp sanitize_site_id(site_id) when is_binary(site_id) do
    # Site IDs are typically domains, so we log them as-is
    # If sensitive, could hash or mask them
    site_id
  end
  defp sanitize_site_id(_), do: nil

  defp has_filters?(args) do
    filters = args[:filters]
    filters != nil and filters != %{} and filters != []
  end

  defp has_aggregation?(args) do
    args[:aggregation] != nil
  end

  defp error_type({:error, %{code: code}}), do: code
  defp error_type({:error, error}) when is_atom(error), do: error
  defp error_type({:error, _}), do: :unknown
  defp error_type(err) when is_atom(err), do: err
  defp error_type(_), do: :unknown

  defp error_message(%{message: message}), do: message
  defp error_message(err) when is_atom(err), do: Atom.to_string(err)
  defp error_message(err), do: inspect(err)
end
