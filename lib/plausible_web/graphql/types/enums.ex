defmodule PlausibleWeb.GraphQL.Types.Enums do
  @moduledoc """
  GraphQL enum types for the Analytics API
  """

  use Absinthe.Schema.Notation

  enum :metric do
    value :visitors
    value :pageviews
    value :events
    value :bounce_rate
    value :visit_duration
    value :custom_metric
  end

  enum :dimension do
    value :country
    value :region
    value :city
    value :referrer
    value :utm_medium
    value :utm_source
    value :utm_campaign
    value :device
    value :browser
    value :operating_system
    value :pathname
  end

  enum :granularity do
    value :hourly
    value :daily
    value :weekly
    value :monthly
  end

  enum :sort_by do
    value :visitors_desc
    value :visitors_asc
    value :pageviews_desc
    value :pageviews_asc
  end
end
