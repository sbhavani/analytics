defmodule PlausibleWeb.GraphQL.Types.MetricFilter do
  @moduledoc """
  GraphQL types for metric filter input.
  """

  defstruct date_range: nil, metric_names: []

  @doc """
  Creates a MetricFilter struct from GraphQL input.
  """
  def from_input(nil) do
    %__MODULE__{}
  end

  def from_input(%{date_range: date_range, metric_names: metric_names}) do
    %__MODULE__{
      date_range: parse_date_range(date_range),
      metric_names: metric_names || []
    }
  end

  def from_input(%{date_range: date_range}) do
    %__MODULE__{
      date_range: parse_date_range(date_range)
    }
  end

  def from_input(%{metric_names: metric_names}) do
    %__MODULE__{
      metric_names: metric_names || []
    }
  end

  defp parse_date_range(%{from: from, to: to}) do
    %{from: from, to: to}
  end

  defp parse_date_range(nil), do: nil

  @doc """
  Returns the default metric filter options.
  """
  def default do
    %__MODULE__{}
  end
end
