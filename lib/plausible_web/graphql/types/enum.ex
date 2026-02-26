defmodule PlausibleWeb.GraphQL.Types.Enum do
  @moduledoc """
  GraphQL enum types for the Analytics API.
  """

  use Absinthe.Schema.Notation

  @desc "Aggregation type"
  enum :aggregation_type do
    value :sum, description: "Sum aggregation"
    value :count, description: "Count aggregation"
    value :avg, description: "Average aggregation"
    value :min, description: "Minimum aggregation"
    value :max, description: "Maximum aggregation"
  end

  @desc "Group by dimension"
  enum :group_by_dimension do
    value :path, description: "Group by URL path"
    value :url, description: "Group by full URL"
    value :browser, description: "Group by browser"
    value :device, description: "Group by device type"
    value :country, description: "Group by country"
    value :referrer, description: "Group by referrer"
  end

  @desc "Time interval"
  enum :time_interval do
    value :minute, description: "Minute interval"
    value :hour, description: "Hour interval"
    value :day, description: "Day interval"
    value :week, description: "Week interval"
    value :month, description: "Month interval"
  end
end
