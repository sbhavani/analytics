defmodule PlausibleWeb.GraphQL.Types.Pagination do
  @moduledoc """
  GraphQL input type for pagination support.
  """

  use Absinthe.Schema.Notation

  input_object :pagination_input do
    field :limit, :integer
    field :offset, :integer
  end

  defstruct limit: 100, offset: 0

  @max_limit 10_000

  @doc """
  Creates a Pagination struct from GraphQL input.
  """
  def from_input(nil) do
    %__MODULE__{}
  end

  def from_input(%{limit: limit, offset: offset}) do
    %__MODULE__{
      limit: min(limit || 100, @max_limit),
      offset: offset || 0
    }
  end

  def from_input(%{limit: limit}) do
    %__MODULE__{
      limit: min(limit || 100, @max_limit)
    }
  end

  def from_input(%{offset: offset}) do
    %__MODULE__{
      offset: offset || 0
    }
  end

  @doc """
  Returns the default pagination options.
  """
  def default do
    %__MODULE__{}
  end
end
