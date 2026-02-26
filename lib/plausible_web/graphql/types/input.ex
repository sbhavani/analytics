defmodule PlausibleWeb.GraphQL.Types.Input do
  @moduledoc """
  GraphQL input types for the Analytics API.
  """

  use Absinthe.Schema.Notation

  @desc "Date range input"
  input_object :date_range_input do
    field :from, non_null(:string), description: "Start date (ISO 8601)"
    field :to, non_null(:string), description: "End date (ISO 8601)"
  end

  @desc "Pageview filters input"
  input_object :pageview_filters_input do
    field :path, :string, description: "Filter by URL path (supports wildcards)"
    field :referrer, :string, description: "Filter by referrer domain"
    field :browser, :string, description: "Filter by browser"
    field :device, :string, description: "Filter by device type"
    field :country, :string, description: "Filter by country code"
  end

  @desc "Event filters input"
  input_object :event_filters_input do
    field :event_name, :string, description: "Filter by event name"
    field :url, :string, description: "Filter by URL"
    field :property, :string, description: "Filter by property (key=value)"
  end

  @desc "Aggregation input"
  input_object :aggregation_input do
    field :type, non_null(:aggregation_type), description: "Aggregation type"
    field :group_by, :group_by_dimension, description: "Group by dimension"
    field :interval, :time_interval, description: "Time interval for grouping"
  end
end
