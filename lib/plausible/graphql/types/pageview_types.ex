defmodule Plausible.GraphQL.Types.PageviewTypes do
  @moduledoc """
  GraphQL types for pageview data.
  """

  use Absinthe.Schema.Notation

  @desc "A pageview represents a single view of a web page"
  object :pageview do
    field :url, :string, description: "Full URL of the page viewed"
    field :timestamp, :datetime, description: "When the pageview occurred"
    field :referrer, :string, description: "Traffic source (may be empty)"
    field :visitor_id, :string, description: "Anonymous visitor identifier"
  end

  @desc "Input filter for pageview queries"
  input_object :pageview_filter_input do
    field :url, :string, description: "Exact URL to filter by"
    field :url_pattern, :string, description: "URL pattern to match (supports wildcards)"
    field :referrer, :string, description: "Referrer to filter by"
  end
end
