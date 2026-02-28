defmodule Plausible.GraphQL.Resolvers.Filter do
  @moduledoc """
  Handles filter building for GraphQL queries.
  """

  @doc """
  Builds a filter map from GraphQL filter input.
  """
  def build_filters(nil), do: %{}

  def build_filters(%{} = filter_input) do
    filter_input
    |> Map.to_list()
    |> Enum.reject(fn {_key, value} -> value == nil end)
    |> Map.new()
  end

  @doc """
  Validates that filters can be applied together.
  """
  def validate_filters(filters) when is_map(filters) do
    # Add any filter validation logic here
    {:ok, filters}
  end

  def validate_filters(_), do: {:error, :invalid_filters}
end
