defmodule Plausible.GraphQL.Types.PageviewData do
  @moduledoc """
  GraphQL type for pageview data
  """
  use Absinthe.Schema.Notation

  object :pageview_data do
    field :visitors, :integer
    field :pageviews, :integer
    field :bounce_rate, :float
    field :visit_duration, :integer
  end
end
