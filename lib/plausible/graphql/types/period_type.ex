defmodule Plausible.GraphQL.Types.PeriodType do
  @moduledoc """
  GraphQL enum type for time period aggregation
  """
  use Absinthe.Schema.Notation

  enum :period_type do
    value :hourly
    value :daily
    value :weekly
    value :monthly
  end
end
