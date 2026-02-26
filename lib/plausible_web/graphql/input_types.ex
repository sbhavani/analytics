defmodule PlausibleWeb.GraphQL.InputTypes do
  @moduledoc """
  GraphQL input types for query filters and aggregation.
  """

  use Absinthe.Schema.Notation

  input_object :date_range_input do
    field(:start_date, non_null(:date))
    field(:end_date, non_null(:date))
  end

  input_object :filter_input do
    field(:date_range, :date_range_input)
    field(:url_pattern, :string)
    field(:referrer, :string)
    field(:device_type, :device_type)
    field(:country, :string)
    field(:region, :string)
    field(:city, :string)
  end

  input_object :aggregation_input do
    field(:type, non_null(:aggregation_type))
    field(:metric, non_null(:string))
    field(:group_by, :string)
  end
end
