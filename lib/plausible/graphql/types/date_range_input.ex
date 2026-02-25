defmodule Plausible.GraphQL.Types.DateRangeInput do
  @moduledoc """
  Input type for date range filtering
  """
  use Absinthe.Schema.Notation

  input_object :date_range_input do
    non_null(:date)
    field :start_date, non_null(:date)

    non_null(:date)
    field :end_date, non_null(:date)
  end
end
