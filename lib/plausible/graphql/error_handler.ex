defmodule Plausible.GraphQL.ErrorHandler do
  @moduledoc """
  Error handling for GraphQL queries
  """
  require Logger

  def handle_error(error) do
    Logger.error("GraphQL error: #{inspect(error)}")

    case error do
      %{message: message} ->
        %{message: message}

      error when is_atom(error) ->
        %{message: format_error(error)}

      _ ->
        %{message: "An unexpected error occurred"}
    end
  end

  defp format_error(:unauthorized), do: "Unauthorized"
  defp format_error(:not_found), do: "Resource not found"
  defp format_error(:invalid_input), do: "Invalid input"
  defp format_error(error) when is_atom(error), do: "Error: #{Atom.to_string(error)}"
  defp format_error(_), do: "An unexpected error occurred"
end
