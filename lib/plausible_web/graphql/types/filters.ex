defmodule PlausibleWeb.GraphQL.Types.Filters do
  @moduledoc """
  GraphQL input types for filtering queries.
  """

  use Absinthe.Schema.Notation

  @desc "Filter for pageview queries"
  input_object :pageview_filter do
    field :url_pattern, :string, description: "Filter by URL pattern (supports wildcards)"
    field :title, :string, description: "Filter by page title"
  end

  @desc "Filter for event queries"
  input_object :event_filter do
    field :name, :string, description: "Filter by event name"
    field :category, :string, description: "Filter by event category"
  end

  @desc "Aggregation type enum"
  enum :aggregation_type do
    value :count
    value :sum
    value :average
    value :min
    value :max
  end

  @desc "Aggregation input for analytics queries"
  input_object :aggregation_input do
    field :type, non_null(:aggregation_type), description: "Type of aggregation"
    field :metric, non_null(:string), description: "Metric to aggregate"
    field :group_by, :string, description: "Field to group by"
  end
end
