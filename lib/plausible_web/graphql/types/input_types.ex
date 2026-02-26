defmodule PlausibleWeb.GraphQL.Types.InputTypes do
  @moduledoc """
  GraphQL input types for the Analytics API.
  """

  use Absinthe.Schema.Notation

  @desc "Date range for filtering analytics data"
  input_object :date_range_input do
    field :start_date, non_null(:date)
    field :end_date, non_null(:date)
  end

  @desc "Filter criteria for queries"
  input_object :filter_input do
    field :field, non_null(:string)
    field :operator, non_null(:filter_operator)
    field :value, non_null(:string)
  end

  @desc "Supported filter operators"
  enum :filter_operator do
    value :equals
    value :not_equals
    value :contains
    value :not_contains
    value :matches
    value :greater_than
    value :less_than
    value :is_set
    value :is_not_set
  end

  @desc "Pagination parameters"
  input_object :pagination_input do
    field :first, :integer
    field :after, :string
    field :last, :integer
    field :before, :string
  end

  @desc "Aggregation parameters"
  input_object :aggregation_input do
    field :type, non_null(:aggregation_type)
    field :field, :string
    field :dimension, :string
  end

  @desc "Aggregation types"
  enum :aggregation_type do
    value :count
    value :sum
    value :average
  end
end
