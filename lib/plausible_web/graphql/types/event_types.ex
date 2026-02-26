defmodule PlausibleWeb.GraphQL.Types.EventTypes do
  @moduledoc """
  GraphQL types for event data.
  """

  use Absinthe.Schema.Notation

  @desc "A single custom event"
  object :event do
    field :id, non_null(:id)
    field :name, non_null(:string)
    field :timestamp, non_null(:datetime)
    field :visitor_id, non_null(:string)
    field :session_id, :string
    field :properties, :json
    field :country, :string
    field :device, :string
  end

  @desc "Edge in the event connection"
  object :event_edge do
    field :node, non_null(:event)
    field :cursor, non_null(:string)
  end

  @desc "Paginated list of events"
  object :event_connection do
    field :edges, non_null(list_of(non_null(:event_edge)))
    field :page_info, non_null(:page_info)
    field :total_count, non_null(:integer)
  end

  @desc "Result type for event queries (connection or aggregation)"
  union :event_result do
    types [:event_connection, :aggregate_result]

    resolve_type fn
      %{__struct__: PlausibleWeb.GraphQL.Resolvers.EventConnection}, _ ->
        :event_connection
      %{__struct__: PlausibleWeb.GraphQL.Resolvers.AggregateResult}, _ ->
        :aggregate_result
      %{aggregation_type: _}, _ ->
        :aggregate_result
      _, _ ->
        :event_connection
    end
  end
end
