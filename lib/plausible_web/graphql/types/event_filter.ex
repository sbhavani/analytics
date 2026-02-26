defmodule PlausibleWeb.GraphQL.Types.EventFilter do
  use Absinthe.Schema.Notation

  @desc "Event filter input"
  input_object :event_filter do
    field(:date_range, :date_range_input)
    field(:event_name, :string)
    field(:property_name, :string)
    field(:property_value, :string)
  end
end
