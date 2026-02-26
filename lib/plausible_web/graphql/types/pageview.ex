defmodule PlausibleWeb.GraphQL.Types.Pageview do
  use Absinthe.Schema.Notation
  use Plausible
  use Absinthe.Relay.Schema.Notation, :modern

  @desc "Pageview type"
  node object :pageview do
    field(:url, :string)
    field(:pathname, :string)
    field(:referrer, :string)
    field(:referrer_source, :string)
    field(:timestamp, :datetime)
    field(:browser, :string)
    field(:browser_version, :string)
    field(:operating_system, :string)
    field(:operating_system_version, :string)
    field(:device, :string)
    field(:country, :string)
    field(:session_id, :id)
  end

  @desc "Pageview filter input"
  input_object :pageview_filter do
    field(:date_range, non_null(:date_range_input))
    field(:url_pattern, :string)
    field(:browser, :string)
    field(:country, :string)
    field(:device, :string)
    field(:referrer_source, :string)
  end

  @desc "Pageview connection"
  connection(:node_type, :pageview)
end
