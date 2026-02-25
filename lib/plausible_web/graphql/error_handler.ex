defmodule PlausibleWeb.GraphQL.ErrorHandler do
  @moduledoc """
  Handles GraphQL errors and formats them for consistent API responses.
  """

  @doc """
  Formats a list of Absinthe errors into a consistent structure.
  """
  def format_errors(errors) when is_list(errors) do
    Enum.map(errors, &format_error/1)
  end

  defp format_error(%{message: message, locations: locations, path: path}) do
    %{
      message: message,
      locations: format_locations(locations),
      path: format_path(path)
    }
  end

  defp format_error(%{message: message}) do
    %{message: message}
  end

  defp format_error(error) when is_binary(error) do
    %{message: error}
  end

  defp format_error(error) do
    %{message: inspect(error)}
  end

  defp format_locations(nil), do: []
  defp format_locations(locations) do
    Enum.map(locations, fn %{line: line, column: column} ->
      %{line: line, column: column}
    end)
  end

  defp format_path(nil), do: []
  defp format_path(path) do
    Enum.map(path, &to_string/1)
  end
end
