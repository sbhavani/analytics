defmodule Plausible.GraphQL.Types.Event do
  @moduledoc """
  Type for a single event record
  """
  use Absinthe.Schema.Notation

  object :event do
    field :name, :string
    field :timestamp, :datetime
    field :url_path, :string
    field :properties, :json
    field :country, :string
    field :device, :string
  end
end
