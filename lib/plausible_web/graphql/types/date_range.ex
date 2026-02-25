defmodule PlausibleWeb.GraphQL.Types.DateRange do
  @moduledoc """
  GraphQL input type for date range filtering.
  """

  use Absinthe.Schema.Notation

  input_object :date_range_input do
    field :from, non_null(:date_time)
    field :to, non_null(:date_time)
  end
end
