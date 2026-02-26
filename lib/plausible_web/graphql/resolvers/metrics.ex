defmodule PlausibleWeb.GraphQL.Resolvers.Metrics do
  @moduledoc """
  Resolver for metrics queries
  """
  use Plausible
  alias PlausibleWeb.GraphQL.Errors

  def metrics(_parent, %{filter: filter, aggregation_type: aggregation_type, time_grouping: time_grouping, pagination: pagination}, %{context: %{current_user: _current_user}}) do
    # TODO: Implement actual ClickHouse aggregation query
    # 1. Parse filter to Query struct
    # 2. Call existing aggregation functions
    # 3. Apply time grouping
    # 4. Transform results to GraphQL types
    {:ok, %{edges: [], page_info: %{has_next_page: false, has_previous_page: false, start_cursor: nil, end_cursor: nil, total_count: 0}}}
  end

  def metrics(_parent, _args, _resolution) do
    {:error, Errors.unauthenticated()}
  end
end
