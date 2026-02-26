defmodule PlausibleWeb.GraphQLCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the GraphQL schema and testing utilities.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Plausible.Factory
    end
  end
end
