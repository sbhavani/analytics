defmodule PlausibleWeb.GraphQL.Types do
  @moduledoc """
  GraphQL types for analytics data.
  """

  use Absinthe.Schema.Notation

  @desc "Device type for filtering"
  enum :device_type do
    value(:desktop, as: "Desktop")
    value(:mobile, as: "Mobile")
    value(:tablet, as: "Tablet")
  end

  @desc "Aggregation type for data aggregation"
  enum :aggregation_type do
    value(:count, as: "Count")
    value(:sum, as: "Sum")
    value(:average, as: "Average")
    value(:min, as: "Min")
    value(:max, as: "Max")
  end

  @desc "Time grouping interval"
  enum :time_grouping do
    value(:hour, as: "Hour")
    value(:day, as: "Day")
    value(:week, as: "Week")
    value(:month, as: "Month")
  end

  object :pageview_result do
    field(:url, non_null(:string))
    field(:visitor_count, non_null(:integer))
    field(:view_count, non_null(:integer))
    field(:timestamp, non_null(:datetime))
  end

  object :event_result do
    field(:name, non_null(:string))
    field(:count, non_null(:integer))
    field(:timestamp, non_null(:datetime))
    field(:properties, :json)
  end

  object :custom_metric_result do
    field(:name, non_null(:string))
    field(:value, non_null(:float))
    field(:formula, :string)
  end

  object :aggregate_result do
    field(:metric, non_null(:string))
    field(:value, non_null(:float))
  end

  object :time_series_point do
    field(:date, non_null(:datetime))
    field(:visitors, :integer)
    field(:pageviews, :integer)
    field(:events, :integer)
  end
end
