defmodule Plausible.Graphqla.Types.Connection do
  @moduledoc """
  Connection types for cursor-based pagination.

  This module defines the edge types used by the GraphQL connections
  for paginated queries. The connection types themselves are generated
  automatically in the schema using Absinthe's `connection` macro.

  ## Connection Types

  The following connection types are available:

  - `pageview_connection` - for paginated pageview queries
  - `event_connection` - for paginated event queries
  - `custom_metric_connection` - for paginated custom metric queries

  ## Edge Structure

  Each connection includes:

  - `edges` - A list of edge objects containing the actual data
  - `pageInfo` - Pagination information

  Each edge contains:

  - `node` - The actual data object (pageview, event, or custom_metric)
  - `cursor` - An opaque cursor for pagination

  ## Usage

  When querying paginated data, use the connection pattern:

  ```graphql
  query {
    pageviews(filter: $filter, pagination: $pagination) {
      edges {
        node {
          id
          url
          timestamp
        }
        cursor
      }
      pageInfo {
        hasNextPage
        hasPreviousPage
        startCursor
        endCursor
      }
    }
  }
  ```

  ## Pagination Arguments

  Each connection query accepts a `pagination` argument with:

  - `limit` - Maximum number of items to return (default: 100, max: 1000)
  - `offset` - Number of items to skip (default: 0)

  Example:

  ```graphql
  query {
    pageviews(
      filter: { site_id: "123", date_range: { from: "2024-01-01", to: "2024-01-31" } }
      pagination: { limit: 50, offset: 0 }
    ) {
      edges {
        node {
          id
          url
          timestamp
        }
      }
    }
  }
  ```
  """

  # Connection types are defined in Plausible.Graphqla.Schema
  # using the connection macro: connection node_type: :pageview
  #
  # This module serves as documentation for the connection pattern
  # used in this GraphQL API.
end
