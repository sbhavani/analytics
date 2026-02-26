defmodule PlausibleWeb.GraphQL.Types.DateRange do
  use Absinthe.Schema.Notation

  @desc "Date range input"
  input_object :date_range_input do
    field(:start_date, non_null(:date))
    field(:end_date, non_null(:date))
  end
end
