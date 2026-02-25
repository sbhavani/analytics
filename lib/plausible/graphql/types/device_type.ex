defmodule Plausible.GraphQL.Types.DeviceType do
  @moduledoc """
  GraphQL enum for device types
  """
  use Absinthe.Schema.Notation

  enum :device_type do
    value :desktop
    value :mobile
    value :tablet
  end
end
