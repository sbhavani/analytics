defmodule PlausibleWeb.GraphQL.Types do
  use Absinthe.Schema.Notation

  import_types(PlausibleWeb.GraphQL.Types.DateRange)
  import_types(PlausibleWeb.GraphQL.Types.Pagination)
  import_types(PlausibleWeb.GraphQL.Types.Pageview)
  import_types(PlausibleWeb.GraphQL.Types.PageviewFilter)
  import_types(PlausibleWeb.GraphQL.Types.Event)
  import_types(PlausibleWeb.GraphQL.Types.EventFilter)
  import_types(PlausibleWeb.GraphQL.Types.Metric)
  import_types(PlausibleWeb.GraphQL.Types.MetricFilter)
  import_types(PlausibleWeb.GraphQL.Types.Error)

  scalar :json do
    parse(&Absinthe.Plug.Parse.parse_json/1)
    serialize(&Jason.encode!/1)
  end

  scalar :date do
    parse(&Absinthe.Plug.Parse.parse_date/1)
    serialize(&Date.to_iso_string/1)
  end

  scalar :datetime do
    parse(&Absinthe.Plug.Parse.parse_datetime/1)
    serialize(&DateTime.to_iso_string/1)
  end
end
