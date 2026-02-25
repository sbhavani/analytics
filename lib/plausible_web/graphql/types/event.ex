defmodule PlausibleWeb.GraphQL.Types.Event do
  @moduledoc """
  GraphQL types for event data.
  """

  use Absinthe.Schema.Notation

  @desc "A single event record"
  object :event do
    field :name, non_null(:string)
    field :category, :string
    field :timestamp, :datetime
    field :properties, :json
    field :visitors, non_null(:integer)
    field :events, non_null(:integer)
  end

  @desc "Event edge for connection"
  object :event_edge do
    field :node, non_null(:event)
    field :cursor, non_null(:string)
  end

  @desc "Event connection for pagination"
  object :event_connection do
    field :edges, non_null(list_of(non_null(:event_edge)))
    field :page_info, non_null(:page_info)
    field :total_count, non_null(:integer)
  end
end
