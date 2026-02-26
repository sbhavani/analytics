defmodule PlausibleWeb.GraphQL.Types.AnalyticsTypes do
  @moduledoc """
  GraphQL object types for Analytics API responses
  """

  use Absinthe.Schema.Notation

  object :aggregate_result do
    field :visitors, :integer
    field :pageviews, :integer
    field :events, :integer
    field :bounce_rate, :float
    field :visit_duration, :integer
  end

  object :time_series_point do
    field :date, :datetime
    field :visitors, :integer
    field :pageviews, :integer
    field :events, :integer
  end

  object :breakdown_result do
    field :dimension, :string
    field :visitors, :integer
    field :pageviews, :integer
    field :events, :integer
  end

  object :custom_metric do
    field :name, :string
    field :value, :float
  end

  object :site do
    field :id, :id
    field :domain, :string
    field :name, :string
  end
end
