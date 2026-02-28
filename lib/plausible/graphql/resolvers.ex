defmodule Plausible.GraphQL.Resolvers do
  @moduledoc """
  GraphQL resolvers for the Plausible Analytics API.

  This module acts as a namespace for the query resolvers:
  - `Plausible.GraphQL.Resolvers.Pageview` - handles pageview queries
  - `Plausible.GraphQL.Resolvers.Event` - handles event queries
  - `Plausible.GraphQL.Resolvers.CustomMetric` - handles custom metric queries
  - `Plausible.GraphQL.Resolvers.Aggregation` - handles aggregation logic
  - `Plausible.GraphQL.Resolvers.Filter` - handles filter building

  The schema references these via the `Resolvers.*` alias.
  """

  # Sub-modules are auto-loaded via the file structure
  # Each resolver module handles specific query types
end
