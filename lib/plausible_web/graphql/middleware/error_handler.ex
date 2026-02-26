defmodule PlausibleWeb.GraphQL.Middleware.ErrorHandler do
  @moduledoc """
  Middleware for structured error handling in GraphQL

  Transforms resolver errors into structured format with:
  - Human-readable message
  - Machine-readable error code
  - Location in query (when applicable)
  - Path to error field
  - Additional details (when available)
  """
  use Plausible

  # Error code mappings for common error scenarios
  @error_code_map %{
    "unauthenticated" => :unauthenticated,
    "forbidden" => :forbidden,
    "not_found" => :not_found,
    "invalid_input" => :invalid_input,
    "rate_limit_exceeded" => :rate_limit_exceeded,
    "validation_error" => :validation_error,
    "internal_error" => :internal_error,
    "bad_request" => :bad_request,
    "query_too_complex" => :query_too_complex,
    "UNAUTHENTICATED" => :unauthenticated,
    "FORBIDDEN" => :forbidden,
    "NOT_FOUND" => :not_found,
    "INVALID_INPUT" => :invalid_input,
    "RATE_LIMIT_EXCEEDED" => :rate_limit_exceeded,
    "VALIDATION_ERROR" => :validation_error,
    "INTERNAL_ERROR" => :internal_error,
    "BAD_REQUEST" => :bad_request,
    "QUERY_TOO_COMPLEX" => :query_too_complex
  }

  @doc """
  Middleware callback - processes errors from resolvers
  """
  def call(resolution, _opts) do
    # Check if there are any errors in the resolution
    case resolution.errors do
      [] ->
        resolution

      errors ->
        # Transform errors into structured format
        structured_errors = Enum.map(errors, &transform_error/1)
        %{resolution | errors: structured_errors}
    end
  end

  @doc """
  Transform a resolver error into structured format
  """
  def transform_error(error) when is_map(error) do
    error
    |> Map.put_new(:locations, [])
    |> Map.put_new(:path, [])
    |> ensure_code()
    |> ensure_message()
  end

  def transform_error(error) when is_atom(error) do
    %{
      message: Atom.to_string(error),
      code: :internal_error,
      locations: [],
      path: []
    }
  end

  def transform_error(error) when is_binary(error) do
    %{
      message: error,
      code: :internal_error,
      locations: [],
      path: []
    }
  end

  # Ensure error has a code
  defp ensure_code(%{code: code} = error) when is_atom(code) do
    error
  end

  defp ensure_code(%{code: code} = error) when is_binary(code) do
    Map.put(error, :code, Map.get(@error_code_map, code, :internal_error))
  end

  defp ensure_code(error) do
    Map.put(error, :code, :internal_error)
  end

  # Ensure error has a message
  defp ensure_message(%{message: _} = error) do
    error
  end

  defp ensure_message(error) do
    Map.put(error, :message, "An unexpected error occurred")
  end

  @doc """
  Helper to create structured error for resolvers
  """
  def format_error(message, code, opts \\ []) do
    %{
      message: message,
      code: Map.get(@error_code_map, to_string(code), code),
      locations: Keyword.get(opts, :locations, []),
      path: Keyword.get(opts, :path, []),
      details: Keyword.get(opts, :details, %{})
    }
  end
end
