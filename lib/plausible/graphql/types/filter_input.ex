defmodule Plausible.GraphQL.Types.FilterInput do
  @moduledoc """
  GraphQL input types for filtering analytics data
  """
  use Absinthe.Schema.Notation

  import_types Plausible.GraphQL.Types.DeviceType

  input_object :property_filter do
    field :key, :string
    field :value, :string
  end

  input_object :filter_input do
    field :source, :string
    field :medium, :string
    field :country, :string
    field :device, :device_type
    field :page, :string
    field :event_name, :string
    field :properties, list_of(:property_filter)
  end
end
