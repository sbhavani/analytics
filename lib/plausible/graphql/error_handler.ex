defmodule Plausible.GraphQL.ErrorHandler do
  @moduledoc """
  Error handling for GraphQL queries.

  Provides consistent error responses for various error types.
  """

  require Logger

  @doc """
  Handles errors from resolvers and formats them for GraphQL response.
  """
  def handle_error(resolution, error) do
    Logger.warning("GraphQL error: #{inspect(error)}")

    formatted_error = case error do
      :unauthorized ->
        %{message: "Unauthorized", code: :unauthorized}

      :not_found ->
        %{message: "Resource not found", code: :not_found}

      %{message: message, code: code} ->
        %{message: message, code: code}

      %{} = error_map when is_map(error_map) ->
        %{message: error_map[:message] || "Unknown error", code: :unknown}

      string when is_binary(string) ->
        %{message: string, code: :unknown}

      _ ->
        %{message: "An unexpected error occurred", code: :internal_error}
    end

    Absinthe.Resolution.put_result(resolution, {:error, formatted_error})
  end

  @doc """
  Handles validation errors from input types.
  """
  def handle_validation_error(field, message) do
    %{message: "Validation error: #{message}", field: field}
  end
end
