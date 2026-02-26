defmodule Plausible.Graphqla.Types.PageviewTypes do
  @moduledoc """
  GraphQL types for pageview-related queries and filters
  """
  use Absinthe.Schema.Notation

  # Pageview filter input
  input_object :pageview_filter_input do
    field :site_id, non_null(:id)
    field :date_range, :date_range_input
    field :url_pattern, :string
  end

  # Pageview object type
  object :pageview do
    field :id, non_null(:id)
    field :timestamp, non_null(:datetime)
    field :url, non_null(:string)
    field :referrer, :string
    field :browser, :string
    field :device, :string
    field :country, :string
  end
end
