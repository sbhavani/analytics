defmodule PlausibleWeb.GraphQL.Types.InputTypes do
  @moduledoc """
  GraphQL input types for the Analytics API
  """

  use Absinthe.Schema.Notation

  input_object :date_range_input do
    field :start_date, non_null(:date)
    field :end_date, non_null(:date)
  end

  input_object :filter_input do
    field :country, :string
    field :region, :string
    field :city, :string
    field :referrer, :string
    field :utm_medium, :string
    field :utm_source, :string
    field :utm_campaign, :string
    field :device, :string
    field :browser, :string
    field :operating_system, :string
    field :pathname, :string
  end

  input_object :aggregate_input do
    field :metrics, non_null(list_of(non_null(:metric)))
    field :date_range, non_null(:date_range_input)
    field :filters, list_of(:filter_input)
  end

  input_object :breakdown_input do
    field :dimension, non_null(:dimension)
    field :metrics, non_null(list_of(non_null(:metric)))
    field :date_range, non_null(:date_range_input)
    field :filters, list_of(:filter_input)
    field :limit, :integer
    field :offset, :integer
    field :sort_by, :sort_by
  end

  input_object :time_series_input do
    field :metrics, non_null(list_of(non_null(:metric)))
    field :date_range, non_null(:date_range_input)
    field :filters, list_of(:filter_input)
    field :granularity, non_null(:granularity)
  end
end
