defmodule PlausibleWeb.GraphQL.Types.Event do
  use Absinthe.Schema.Notation
  use Plausible
  use Absinthe.Relay.Schema.Notation, :modern

  @desc "Event type"
  node object :event do
    field(:name, :string)
    field(:timestamp, :datetime)
    field(:properties, :json)
    field(:session_id, :id)
    field(:user_id, :string)
  end

  @desc "Event filter input"
  input_object :event_filter do
    field(:date_range, non_null(:date_range_input))
    field(:event_name, :string)
    field(:property_name, :string)
    field(:property_value, :string)
  end

  @desc "Event connection"
  connection(:node_type, :event)
end
