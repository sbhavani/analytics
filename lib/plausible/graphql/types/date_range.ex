defmodule Plausible.GraphQL.Types.DateRange do
  @moduledoc """
  GraphQL input type for date range
  """
  use Absinthe.Schema.Notation

  enum :period_type do
    value :hourly
    value :daily
    value :weekly
    value :monthly
  end

  input_object :date_range_input do
    field :from, :date
    field :to, :date
    field :period, :period_type
  end

  object :date_range_output do
    field :from, :date
    field :to, :date
    field :period, :period_type
  end
end
