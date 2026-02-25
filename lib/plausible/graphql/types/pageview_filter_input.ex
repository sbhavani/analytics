defmodule Plausible.GraphQL.Types.PageviewFilterInput do
  @moduledoc """
  Input type for filtering pageviews
  """
  use Absinthe.Schema.Notation

  input_object :pageview_filter_input do
    field :url_pattern, :string
    field :referrer, :string
    field :country, :string
    field :device, :string
  end
end
