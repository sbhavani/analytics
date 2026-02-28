defmodule Plausible.GraphQL.Types do
  @moduledoc """
  Central module for importing all GraphQL types.

  This module serves as the main entry point for GraphQL types in the
  Plausible Analytics API. It provides re-exports of all types from
  sub-modules for convenient access.

  The actual type definitions are organized in sub-modules:
  - PageviewTypes: Types for pageview data
  - EventTypes: Types for event data
  - CustomMetricTypes: Types for custom metrics
  - CommonTypes: Shared types like enums and inputs
  """

  use Absinthe.Schema.Notation

  # Re-export aggregate result type
  # Note: aggregation_type enum is defined in CommonTypes
  @desc "Represents an aggregated metric result"
  object :aggregate_result do
    field :value, :float, description: "The aggregated value"
    field :type, :aggregation_type, description: "The type of aggregation performed"
  end

  @desc "Connection for cursor-based pagination"
  object :page_info do
    field :has_next_page, non_null(:boolean)
    field :has_previous_page, non_null(:boolean)
    field :start_cursor, :string
    field :end_cursor, :string
  end

  # Convenience function to list all available types
  @doc """
  Returns a list of all defined GraphQL types in this module.
  """
  def types do
    [:aggregate_result, :page_info]
  end
end
