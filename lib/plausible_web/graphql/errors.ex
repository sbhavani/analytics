defmodule PlausibleWeb.GraphQL.Errors do
  @moduledoc """
  Helper functions for creating structured errors in GraphQL resolvers

  Provides consistent error formatting across all resolvers with
  standardized error codes and messages.
  """
  use Plausible

  @error_codes [
    :unauthenticated,
    :forbidden,
    :not_found,
    :invalid_input,
    :rate_limit_exceeded,
    :validation_error,
    :internal_error,
    :bad_request,
    :query_too_complex
  ]

  @doc """
  Returns list of valid error codes
  """
  def error_codes, do: @error_codes

  @doc """
  Create an unauthenticated error
  """
  def unauthenticated(details \\ %{}) do
    build_error("Authentication required", :unauthenticated, details)
  end

  @doc """
  Create a forbidden error
  """
  def forbidden(message \\ "Access forbidden", details \\ %{}) do
    build_error(message, :forbidden, details)
  end

  @doc """
  Create a not found error
  """
  def not_found(message \\ "Resource not found", details \\ %{}) do
    build_error(message, :not_found, details)
  end

  @doc """
  Create an invalid input error
  """
  def invalid_input(message \\ "Invalid input provided", details \\ %{}) do
    build_error(message, :invalid_input, details)
  end

  @doc """
  Create a validation error
  """
  def validation_error(message, details \\ %{}) do
    build_error(message, :validation_error, details)
  end

  @doc """
  Create a rate limit error
  """
  def rate_limit_exceeded(details \\ %{}) do
    build_error("Rate limit exceeded", :rate_limit_exceeded, details)
  end

  @doc """
  Create an internal error
  """
  def internal_error(message \\ "An unexpected error occurred", details \\ %{}) do
    build_error(message, :internal_error, details)
  end

  @doc """
  Create a bad request error
  """
  def bad_request(message \\ "Bad request", details \\ %{}) do
    build_error(message, :bad_request, details)
  end

  @doc """
  Create a query too complex error
  """
  def query_too_complex(details \\ %{}) do
    build_error("Query complexity exceeded limit", :query_too_complex, details)
  end

  @doc """
  Build a structured error map
  """
  def build_error(message, code, details) when is_atom(code) do
    %{
      message: message,
      code: code,
      details: details,
      locations: [],
      path: []
    }
  end

  def build_error(message, code, details) when is_binary(code) do
    code_atom = String.to_existing_atom(":" <> code)
    build_error(message, code_atom, details)
  rescue
    ArgumentError ->
      build_error(message, :internal_error, details)
  end

  @doc """
  Wrap a resolver result with optional error
  """
  def wrap({:ok, data}, nil), do: {:ok, data}
  def wrap({:ok, data}, error) when is_map(error), do: {:ok, data, error}
  def wrap({:error, _} = error, _), do: error
end
