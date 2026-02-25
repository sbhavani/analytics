defmodule Plausible.GraphQL.Types.CustomMetric do
  @moduledoc """
  GraphQL type for custom metrics
  """
  use Absinthe.Schema.Notation

  object :custom_metric do
    field :name, non_null(:string)
    field :value, :float
    field :formula, :string
  end
end
