defmodule Plausible.GraphQL.Types.Pageview do
  @moduledoc """
  Type for a single pageview record
  """
  use Absinthe.Schema.Notation

  object :pageview do
    field :url_path, :string
    field :timestamp, :datetime
    field :referrer, :string
    field :user_agent, :string
    field :country, :string
    field :device, :string
  end
end
