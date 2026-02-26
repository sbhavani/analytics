defmodule PlausibleWeb.GraphQL.Types.PageviewFilter do
  use Absinthe.Schema.Notation

  @desc "Pageview filter input"
  input_object :pageview_filter do
    field(:date_range, :date_range_input)
    field(:url_pattern, :string)
    field(:browser, :string)
    field(:country, :string)
    field(:device, :string)
    field(:referrer_source, :string)
  end
end
