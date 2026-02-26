defmodule PlausibleWeb.GraphQL.Types.ErrorTypes do
  @moduledoc """
  GraphQL types for error handling
  """

  use Absinthe.Schema.Notation

  @desc "Error code enum for GraphQL errors"
  enum :error_code do
    value :unauthorized
    value :forbidden
    value :not_found
    value :validation_error
    value :invalid_date_range
    value :invalid_filter
    value :rate_limit_exceeded
    value :internal_error
    value :bad_request
  end

  @desc "A single error in the GraphQL response"
  object :error do
    field :message, :string, description: "Human-readable error message"
    field :code, :error_code, description: "Machine-readable error code"
    field :field, :string, description: "The field that caused the error, if applicable"
    field :details, :string, description: "Additional error details"
  end

  @desc "Error response wrapper"
  object :error_response do
    field :errors, list_of(:error)
    field :request_id, :string, description: "Unique identifier for the request"
  end
end
