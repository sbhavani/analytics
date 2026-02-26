defmodule PlausibleWeb.GraphQL.Types.Pagination do
  use Absinthe.Schema.Notation

  @desc "Pagination input"
  input_object :pagination_input do
    field(:limit, :integer, default_value: 50)
    field(:offset, :integer, default_value: 0)
  end

  @desc "Sort input"
  input_object :sort_input do
    field(:field, :string, default_value: "timestamp")
    field(:order, :sort_order, default_value: :desc)
  end

  enum :sort_order do
    value(:asc)
    value(:desc)
  end

  enum :aggregation_type do
    value(:count)
    value(:sum)
    value(:average)
    value(:min)
    value(:max)
  end

  enum :time_grouping do
    value(:hour)
    value(:day)
    value(:week)
    value(:month)
  end
end
