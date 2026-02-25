defmodule PlausibleWeb.GraphQL.Types.Filters do
  @moduledoc """
  GraphQL input types for filtering analytics data.
  """

  use Absinthe.Schema.Notation

  input_object :property_filter_input do
    field :field, non_null(:string)
    field :operator, non_null(:filter_operator)
    field :value, non_null(:string)
  end

  input_object :pageview_filter_input do
    field :date_range, non_null(:date_range_input)
    field :url, :string
    field :country, :string
    field :device, :device_type
    field :referrer, :string
  end

  input_object :event_filter_input do
    field :date_range, non_null(:date_range_input)
    field :event_name, :string
    field :property, :property_filter_input
  end

  input_object :metric_filter_input do
    field :date_range, non_null(:date_range_input)
    field :metric_names, list_of(:string)
  end
end
