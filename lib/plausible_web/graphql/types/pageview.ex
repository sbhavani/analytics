defmodule PlausibleWeb.GraphQL.Types.Pageview do
  @moduledoc """
  GraphQL types for pageview data.
  """

  use Absinthe.Schema.Notation

  @desc "A single pageview record"
  object :pageview do
    field :url, non_null(:string)
    field :title, :string
    field :visitors, non_null(:integer)
    field :views_per_visit, :float
    field :bounce_rate, :float
    field :timestamp, :datetime
  end

  @desc "Pageview edge for connection"
  object :pageview_edge do
    field :node, non_null(:pageview)
    field :cursor, non_null(:string)
  end

  @desc "Pageview connection for pagination"
  object :pageview_connection do
    field :edges, non_null(list_of(non_null(:pageview_edge)))
    field :page_info, non_null(:page_info)
    field :total_count, non_null(:integer)
  end
end
