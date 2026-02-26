defmodule PlausibleWeb.GraphQL.Resolvers.Aggregation do
  @moduledoc """
  Helper module for aggregation parsing and formatting.

  Provides centralized functions for parsing aggregation types, group by
  dimensions, and time intervals to reduce duplication across resolvers.
  """

  @doc """
  Parses an aggregation input map into a standardized format.

  ## Examples

      iex> parse(nil)
      %{type: :count, group_by: nil, interval: nil}

      iex> parse(%{type: :sum, group_by: :country, interval: :day})
      %{type: :sum, group_by: :country, interval: :date}
  """
  def parse(nil) do
    %{type: :count, group_by: nil, interval: nil}
  end

  def parse(%{type: type, group_by: group_by, interval: interval}) do
    %{
      type: parse_type(type),
      group_by: parse_group_by(group_by),
      interval: parse_interval(interval)
    }
  end

  def parse(%{type: type}) do
    %{
      type: parse_type(type),
      group_by: nil,
      interval: nil
    }
  end

  @doc """
  Parses an aggregation type from GraphQL enum to internal atom.

  ## Examples

      iex> parse_type(:sum)
      :sum

      iex> parse_type(:count)
      :count

      iex> parse_type(:avg)
      :avg

      iex> parse_type(:unknown)
      :count
  """
  def parse_type(:sum), do: :sum
  def parse_type(:count), do: :count
  def parse_type(:avg), do: :avg
  def parse_type(:min), do: :min
  def parse_type(:max), do: :max
  def parse_type(_), do: :count

  @doc """
  Parses a group_by dimension from GraphQL enum to internal atom.

  ## Examples

      iex> parse_group_by(:path)
      :pathname

      iex> parse_group_by(:url)
      :url

      iex> parse_group_by(:country)
      :country

      iex> parse_group_by(nil)
      nil
  """
  def parse_group_by(:path), do: :pathname
  def parse_group_by(:url), do: :url
  def parse_group_by(:browser), do: :browser
  def parse_group_by(:device), do: :device
  def parse_group_by(:country), do: :country
  def parse_group_by(:referrer), do: :referrer
  def parse_group_by(:event_name), do: :event_name
  def parse_group_by(nil), do: nil

  @doc """
  Parses a time interval from GraphQL enum to internal atom.

  ## Examples

      iex> parse_interval(:minute)
      :minute

      iex> parse_interval(:hour)
      :hour

      iex> parse_interval(:day)
      :date

      iex> parse_interval(:week)
      :week

      iex> parse_interval(:month)
      :month

      iex> parse_interval(nil)
      nil
  """
  def parse_interval(:minute), do: :minute
  def parse_interval(:hour), do: :hour
  def parse_interval(:day), do: :date
  def parse_interval(:week), do: :week
  def parse_interval(:month), do: :month
  def parse_interval(nil), do: nil

  @doc """
  Determines if the aggregation requires a time series query.

  ## Examples

      iex> requires_time_series?(%{group_by: nil, interval: nil})
      false

      iex> requires_time_series?(%{group_by: :country, interval: nil})
      true

      iex> requires_time_series?(%{group_by: nil, interval: :day})
      true
  """
  def requires_time_series?(%{group_by: group_by, interval: interval}) do
    group_by != nil or interval != nil
  end

  @doc """
  Formats a period/date value based on the interval.

  ## Examples

      iex> format_period(%{date: ~D[2026-01-15]}, :date)
      ~D[2026-01-15]

      iex> format_period(%{date: ~N[2026-01-15T10:00:00]}, :hour)
      ~N[2026-01-15T10:00:00]
  """
  def format_period(row, :minute), do: Map.get(row, :date)
  def format_period(row, :hour), do: Map.get(row, :date)
  def format_period(row, :date), do: Map.get(row, :date)
  def format_period(row, :week), do: Map.get(row, :date)
  def format_period(row, :month), do: Map.get(row, :date)
  def format_period(_, _), do: nil

  @doc """
  Formats a result row for time series response.

  ## Examples

      iex> format_time_series_row(%{count: 100, visitors: 50}, :country, :date)
      %{count: 100, visitors: 50, group: nil, period: nil}
  """
  def format_time_series_row(row, group_by, interval) do
    %{
      count: Map.get(row, :count, 0),
      visitors: Map.get(row, :visitors, 0),
      group: Map.get(row, group_by),
      period: format_period(row, interval)
    }
  end

  @doc """
  Formats a result row for aggregate response.

  ## Examples

      iex> format_aggregate_row(%{count: 100, visitors: 50})
      %{count: 100, visitors: 50, group: nil, period: nil}
  """
  def format_aggregate_row(result) do
    %{
      count: Map.get(result, :count, 0) || 0,
      visitors: Map.get(result, :visitors, 0) || 0,
      group: nil,
      period: nil
    }
  end
end
