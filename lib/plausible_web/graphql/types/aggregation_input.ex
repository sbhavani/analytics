defmodule PlausibleWeb.GraphQL.Types.AggregationInput do
  @moduledoc """
  GraphQL input type for aggregation operations.
  """

  use Absinthe.Schema.Notation

  input_object :aggregation_input do
    field :type, non_null(:aggregation_type)
    field :field, :string
  end

  @aggregation_types [:count, :sum, :avg, :min, :max]

  defstruct type: :count, field: nil

  @doc """
  Creates an AggregationInput struct from GraphQL input.
  """
  def from_input(nil) do
    %__MODULE__{}
  end

  def from_input(%{type: type, field: field}) do
    %__MODULE__{
      type: normalize_type(type),
      field: field
    }
  end

  def from_input(%{type: type}) do
    %__MODULE__{
      type: normalize_type(type)
    }
  end

  defp normalize_type(nil), do: :count

  defp normalize_type(type) when is_atom(type) do
    if type in @aggregation_types, do: type, else: :count
  end

  defp normalize_type(type) when is_binary(type) do
    String.to_existing_atom(type)
    |> normalize_type()
  rescue
    ArgumentError -> :count
  end

  @doc """
  Returns the default aggregation options.
  """
  def default do
    %__MODULE__{}
  end

  @doc """
  Returns the list of valid aggregation types.
  """
  def valid_types do
    @aggregation_types
  end
end
