defmodule PlausibleWeb.GraphQL.Types.PageviewTypes do
  @moduledoc """
  GraphQL types for pageview data.
  """

  use Absinthe.Schema.Notation

  @desc "A single pageview event"
  object :pageview do
    field :id, non_null(:id)
    field :url, non_null(:string)
    field :pathname, non_null(:string)
    field :timestamp, non_null(:datetime)
    field :visitor_id, non_null(:string)
    field :referrer, :string
    field :session_id, :string
    field :country, :string
    field :device, :string
    field :browser, :string
    field :operating_system, :string
  end

  @desc "Edge in the pageview connection"
  object :pageview_edge do
    field :node, non_null(:pageview)
    field :cursor, non_null(:string)
  end

  @desc "Paginated list of pageviews"
  object :pageview_connection do
    field :edges, non_null(list_of(non_null(:pageview_edge)))
    field :page_info, non_null(:page_info)
    field :total_count, non_null(:integer)
  end

  @desc "Result type for pageview queries (connection or aggregation)"
  union :pageview_result do
    types [:pageview_connection, :aggregate_result]

    resolve_type fn
      %{__struct__: PlausibleWeb.GraphQL.Resolvers.PageviewConnection}, _ ->
        :pageview_connection
      %{__struct__: PlausibleWeb.GraphQL.Resolvers.AggregateResult}, _ ->
        :aggregate_result
      %{aggregation_type: _}, _ ->
        :aggregate_result
      _, _ ->
        :pageview_connection
    end
  end
end
