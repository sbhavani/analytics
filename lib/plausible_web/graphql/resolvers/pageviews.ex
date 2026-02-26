defmodule PlausibleWeb.GraphQL.Resolvers.Pageviews do
  @moduledoc """
  Resolver for pageview queries
  """
  use Plausible
  alias PlausibleWeb.GraphQL.Errors

  def pageviews(_parent, %{filter: filter, pagination: pagination, sort: sort}, %{context: %{current_user: _current_user}}) do
    # TODO: Implement actual ClickHouse query
    # 1. Parse filter to Query struct
    # 2. Call existing stats functions
    # 3. Transform results to GraphQL types
    {:ok, %{edges: [], page_info: %{has_next_page: false, has_previous_page: false, start_cursor: nil, end_cursor: nil, total_count: 0}}}
  end

  def pageviews(_parent, _args, _resolution) do
    {:error, Errors.unauthenticated()}
  end
end
