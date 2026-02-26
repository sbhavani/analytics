defmodule PlausibleWeb.GraphQL.Error do
  @moduledoc """
  Error utilities for consistent error handling across GraphQL resolvers
  """

  @type error_code :: :unauthorized | :forbidden | :not_found | :validation_error |
                      :invalid_date_range | :invalid_filter | :rate_limit_exceeded |
                      :internal_error | :bad_request

  @doc """
  Create an authorization error tuple
  """
  def unauthorized(message \\ "Unauthorized access") do
    {:error, %{message: message, code: :unauthorized}}
  end

  @doc """
  Create a forbidden error tuple
  """
  def forbidden(message \\ "Forbidden") do
    {:error, %{message: message, code: :forbidden}}
  end

  @doc """
  Create a not found error tuple
  """
  def not_found(message \\ "Resource not found") do
    {:error, %{message: message, code: :not_found}}
  end

  @doc """
  Create a validation error tuple
  """
  def validation(message, field \\ nil) do
    {:error, %{message: message, code: :validation_error, field: field}}
  end

  @doc """
  Create an invalid date range error tuple
  """
  def invalid_date_range(message \\ "Invalid date range") do
    {:error, %{message: message, code: :invalid_date_range}}
  end

  @doc """
  Create an invalid filter error tuple
  """
  def invalid_filter(message, field \\ nil) do
    {:error, %{message: message, code: :invalid_filter, field: field}}
  end

  @doc """
  Create a rate limit error tuple
  """
  def rate_limit_exceeded(message \\ "Rate limit exceeded") do
    {:error, %{message: message, code: :rate_limit_exceeded}}
  end

  @doc """
  Create an internal error tuple
  """
  def internal_error(message \\ "An internal error occurred") do
    {:error, %{message: message, code: :internal_error}}
  end

  @doc """
  Create a bad request error tuple
  """
  def bad_request(message \\ "Bad request") do
    {:error, %{message: message, code: :bad_request}}
  end

  @doc """
  Format an error for GraphQL response
  """
  def format_error(%{message: message, code: code} = error) do
    %{
      message: message,
      code: code,
      field: Map.get(error, :field),
      details: Map.get(error, :details)
    }
  end

  def format_error(error) when is_binary(error) do
    %{message: error, code: :validation_error}
  end

  def format_error(error) when is_atom(error) do
    %{message: Atom.to_string(error), code: :validation_error}
  end

  def format_error(_), do: %{message: "Unknown error", code: :internal_error}
end
