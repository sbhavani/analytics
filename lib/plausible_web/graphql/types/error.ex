defmodule PlausibleWeb.GraphQL.Types.Error do
  @moduledoc """
  GraphQL error types and error codes for structured error handling
  """
  use Absinthe.Schema.Notation
  use Plausible

  @desc "Error code enumeration"
  enum :error_code do
    value(:unauthenticated, description: "Authentication required")
    value(:forbidden, description: "Access forbidden")
    value(:not_found, description: "Resource not found")
    value(:invalid_input, description: "Invalid input provided")
    value(:rate_limit_exceeded, description: "Rate limit exceeded")
    value(:validation_error, description: "Validation error")
    value(:internal_error, description: "Internal server error")
    value(:bad_request, description: "Bad request")
    value(:query_too_complex, description: "Query complexity exceeded")
  end

  @desc "Error location in GraphQL document"
  object :error_location do
    field(:line, :integer)
    field(:column, :integer)
  end

  @desc "Structured error type for GraphQL responses"
  object :error do
    field(:message, :string, description: "Human-readable error message")
    field(:code, :error_code, description: "Machine-readable error code")
    field(:locations, list_of(:error_location), description: "Location in GraphQL document")
    field(:path, list_of(:string), description: "Path to the error field")
    field(:details, :json, description: "Additional error details")
  end

  @desc "Input validation error for form/API inputs"
  input_object :validation_error do
    field(:field, :string, description: "Field that failed validation")
    field(:message, :string, description: "Validation error message")
  end

  @desc "Error response wrapper"
  object :error_response do
    field(:errors, list_of(:error), description: "List of errors")
    field(:request_id, :string, description: "Request ID for tracking")
  end
end
