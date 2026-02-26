defmodule PlausibleWeb.GraphQL.Middleware.ErrorHandler do
  @moduledoc """
  Middleware for handling and formatting GraphQL errors
  """

  alias Absinthe.Resolution

  defmodule Result do
    @moduledoc """
    Error result wrapper for consistent error handling
    """
    defstruct [:message, :code, :field, :details]

    def new(message, code \\ :validation_error, field \\ nil, details \\ nil) do
      %__MODULE__{
        message: message,
        code: code,
        field: field,
        details: details
      }
    end
  end

  @doc """
  Handle authorization errors in resolvers
  """
  def call(resolution, _opts \\ []) do
    case resolution do
      %{errors: [%{message: "unauthorized"}]} ->
        Resolution.put_result(resolution, Result.new("Unauthorized access", :unauthorized))

      %{errors: [%{message: "forbidden"}]} ->
        Resolution.put_result(resolution, Result.new("Forbidden", :forbidden))

      _ ->
        resolution
    end
  end
end

defmodule PlausibleWeb.GraphQL.Middleware.HandleErrors do
  @moduledoc """
  Middleware to catch and format errors in the GraphQL execution pipeline
  """

  alias PlausibleWeb.GraphQL.Middleware.ErrorHandler.Result
  require Logger

  def call(resolution, _opts) do
    case resolution.errors do
      [] ->
        resolution

      errors ->
        formatted_errors =
          Enum.map(errors, &format_error/1)

        %{resolution | errors: formatted_errors}
    end
  end

  defp format_error(%{message: message, code: code} = error) when is_atom(code) do
    %{
      message: message,
      code: code,
      field: Map.get(error, :field),
      details: Map.get(error, :details)
    }
  end

  defp format_error(%{message: message} = error) do
    code =
      case message do
        m when is_binary(m) ->
          cond do
            String.contains?(m, "unauthorized") -> :unauthorized
            String.contains?(m, "not found") -> :not_found
            String.contains?(m, "invalid") -> :validation_error
            true -> :validation_error
          end

        _ ->
          :validation_error
      end

    %{
      message: message,
      code: code,
      field: Map.get(error, :field),
      details: Map.get(error, :details)
    }
  end

  defp format_error(error) when is_binary(error) do
    %{message: error, code: :validation_error}
  end

  defp format_error(error) do
    Logger.warning("Unexpected error format: #{inspect(error)}")
    %{message: "An unexpected error occurred", code: :internal_error}
  end
end
