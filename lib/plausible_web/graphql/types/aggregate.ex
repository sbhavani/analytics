defmodule PlausibleWeb.GraphQL.Types.Aggregate do
  @moduledoc """
  GraphQL types for aggregate analytics results.
  """

  use Absinthe.Schema.Notation

  @desc "Aggregate result"
  object :aggregate_result do
    field :visitors, :integer
    field :pageviews, :integer
    field :events, :integer
    field :bounce_rate, :float
    field :visit_duration, :integer
    field :views_per_visit, :float
  end

  @desc "Timeseries result"
  object :timeseries_result do
    field :interval, :time_interval
    field :data, non_null(list_of(:timeseries_data_point))
  end

  @desc "A single timeseries data point"
  object :timeseries_data_point do
    field :date, non_null(:string)
    field :visitors, :integer
    field :pageviews, :integer
    field :events, :integer
  end
end
