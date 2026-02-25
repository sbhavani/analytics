defmodule Plausible.GraphQL.Types.Site do
  @moduledoc """
  GraphQL type for Site entity
  """
  use Absinthe.Schema.Notation

  object :site do
    field :id, :id
    field :domain, :string
    field :name, :string
  end
end
