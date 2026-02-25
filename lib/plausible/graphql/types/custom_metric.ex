defmodule Plausible.GraphQL.Types.CustomMetric do
  @moduledoc """
  Type for a single custom metric record
  """
  use Absinthe.Schema.Notation

  object :custom_metric do
    field :name, :string
    field :value, :float
    field :timestamp, :datetime
    field :metadata, :json
  end
end
