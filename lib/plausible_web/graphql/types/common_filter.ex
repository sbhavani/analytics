defmodule PlausibleWeb.GraphQL.Types.CommonFilter do
  @moduledoc """
  Common filter input types for GraphQL analytics queries.

  Provides reusable filter components that can be shared across
  different query types (pageviews, events, metrics).
  """

  defstruct date_range: nil

  @type t :: %__MODULE__{
          date_range: %{from: DateTime.t(), to: DateTime.t()} | nil
        }

  @doc """
  Creates a CommonFilter struct from GraphQL input.
  """
  def from_input(nil) do
    %__MODULE__{}
  end

  def from_input(%{date_range: date_range}) when is_map(date_range) do
    %__MODULE__{
      date_range: parse_date_range(date_range)
    }
  end

  def from_input(_), do: %__MODULE__{}

  defp parse_date_range(%{from: from, to: to}) do
    %{
      from: parse_datetime(from),
      to: parse_datetime(to)
    }
  end

  defp parse_datetime(%DateTime{} = dt), do: dt
  defp parse_datetime(other), do: other

  @doc """
  Returns the default filter options.
  """
  def default do
    %__MODULE__{}
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
