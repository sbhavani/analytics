defmodule Plausible.GraphQL.Helpers do
  @moduledoc """
  Helper functions for GraphQL resolvers
  """

  defmacro __using__(_opts) do
    quote do
      alias Plausible.Stats
      alias Plausible.Stats.{Aggregate, Breakdown, Timeseries}
    end
  end
end
