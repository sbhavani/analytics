defmodule Plausible.GraphQL.Types.TimeSeriesData do
  @moduledoc """
  GraphQL type for time series data
  """
  use Absinthe.Schema.Notation

  object :time_series_data do
    field :date, :naive_datetime, non_null: true
    field :visitors, :integer
    field :pageviews, :integer
    field :events, list_of(:event_data)
  end
end
