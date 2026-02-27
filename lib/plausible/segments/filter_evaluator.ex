defmodule Plausible.Segments.FilterEvaluator do
  @moduledoc """
  Evaluates filter trees against visitor data in ClickHouse.
  """

  alias Plausible.Segments.FilterParser

  @doc """
  Evaluates a filter tree and returns a dynamic query for ClickHouse.
  """
  @spec evaluate(FilterTypes.tree()) :: [FilterTypes.condition() | {:and | :or, [any()]}]
  def evaluate(tree) do
    FilterParser.to_where_builder(tree)
  end

  @doc """
  Gets the count of visitors matching a filter.
  """
  @spec get_visitor_count(Plausible.Site.t(), FilterTypes.tree(), Date.t(), Date.t()) :: non_neg_integer()
  def get_visitor_count(site, tree, from_date, to_date) do
    filters = evaluate(tree)

    Plausible.Stats.visitor_count(site, %{
      date_range: {from_date, to_date},
      filters: filters
    })
  end

  @doc """
  Gets the count of sessions matching a filter.
  """
  @spec get_session_count(Plausible.Site.t(), FilterTypes.tree(), Date.t(), Date.t()) :: non_neg_integer()
  def get_session_count(site, tree, from_date, to_date) do
    filters = evaluate(tree)

    Plausible.Stats.session_count(site, %{
      date_range: {from_date, to_date},
      filters: filters
    })
  end
end
