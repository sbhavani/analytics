defmodule PlausibleWeb.GraphQL.Types.PageviewType do
  @moduledoc """
  GraphQL types for pageview data.
  """

  use Absinthe.Schema.Notation

  enum :device_type do
    value :desktop
    value :mobile
    value :tablet
  end

  object :pageview_result do
    field :url, non_null(:string)
    field :view_count, non_null(:integer)
    field :unique_visitors, non_null(:integer)
    field :timestamp, :date_time
    field :referrer, :string
    field :country, :string
    field :device, :device_type
  end
end
