defmodule PlausibleWeb.GraphQL.Types.Pageview do
  @moduledoc """
  GraphQL types for pageview data.
  """

  use Absinthe.Schema.Notation

  @desc "Pageview aggregate data"
  object :pageview_aggregate do
    field :count, :integer, description: "Total count of pageviews"
    field :visitors, :integer, description: "Unique visitors"
    field :group, :string, description: "Page paths grouped by this aggregation"
    field :period, :string, description: "Time period for this data point"
  end
end
