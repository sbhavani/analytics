defmodule PlausibleWeb.GraphQL.Resolvers.Helpers.FilterParser do
  @moduledoc """
  Helper module for parsing GraphQL filter inputs into Plausible.Stats filters.
  """

  @doc """
  Parses a pageview filter input into a map compatible with Plausible.Stats.Query.
  """
  def parse_pageview_filter(filter) when is_map(filter) do
    filters = %{}

    filters =
      case Map.get(filter, :url) do
        nil -> filters
        url -> Map.put(filters, :page, url)
      end

    filters =
      case Map.get(filter, :country) do
        nil -> filters
        country -> Map.put(filters, :country, country)
      end

    filters =
      case Map.get(filter, :device) do
        nil -> filters
        device -> Map.put(filters, :device, String.upcase(to_string(device)))
      end

    filters =
      case Map.get(filter, :referrer) do
        nil -> filters
        referrer -> Map.put(filters, :referrer, referrer)
      end

    filters
  end

  @doc """
  Parses an event filter input into a map compatible with Plausible.Stats.Query.
  """
  def parse_event_filter(filter) when is_map(filter) do
    filters = %{}

    filters =
      case Map.get(filter, :event_name) do
        nil -> filters
        name -> Map.put(filters, :event_name, name)
      end

    filters =
      case Map.get(filter, :property) do
        nil -> filters
        property -> parse_property_filter(filters, property)
      end

    filters
  end

  defp parse_property_filter(filters, %{field: field, operator: operator, value: value}) do
    absinthe_op_to_stats_op = %{
      eq: "==",
      neq: "!=",
      contains: "contains",
      gt: ">",
      gte: ">=",
      lt: "<",
      lte: "<="
    }

    stats_operator = Map.get(absinthe_op_to_stats_op, operator, "==")
    Map.put(filters, "props:#{field}", "#{stats_operator}#{value}")
  end

  @doc """
  Validates that the date range does not exceed 1 year.
  """
  def validate_date_range(%{from: from, to: to}) do
    diff_days = Date.diff(to, from)

    if diff_days > 365 do
      {:error, "Invalid date range: maximum 1 year allowed"}
    else
      :ok
    end
  end

  def validate_date_range(_), do: :ok
end
