defmodule PlausibleWeb.GraphQLCase do
  @moduledoc """
  Test case helper for GraphQL schema tests.
  """
  use ExUnit.CaseTemplate

  alias Plausible.Factory

  setup do
    user = Factory.insert(:user)
    site = Factory.insert(:site, members: [user])

    {:ok, user: user, site: site}
  end

  def run_query(query, schema, user \\ nil) do
    Absinthe.run(query, schema, context: %{user: user})
  end
end
