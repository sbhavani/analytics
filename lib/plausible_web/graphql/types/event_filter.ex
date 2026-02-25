defmodule PlausibleWeb.GraphQL.Types.EventFilter do
  @moduledoc """
  GraphQL types for event filtering.
  """

  defstruct date_range: nil, event_name: nil, property: nil

  @doc """
  Creates an EventFilter struct from GraphQL input.
  """
  def from_input(nil) do
    %__MODULE__{}
  end

  def from_input(%{date_range: date_range, event_name: event_name, property: property}) do
    %__MODULE__{
      date_range: parse_date_range(date_range),
      event_name: event_name,
      property: parse_property(property)
    }
  end

  def from_input(%{date_range: date_range, event_name: event_name}) do
    %__MODULE__{
      date_range: parse_date_range(date_range),
      event_name: event_name
    }
  end

  def from_input(%{date_range: date_range, property: property}) do
    %__MODULE__{
      date_range: parse_date_range(date_range),
      property: parse_property(property)
    }
  end

  def from_input(%{date_range: date_range}) do
    %__MODULE__{
      date_range: parse_date_range(date_range)
    }
  end

  def from_input(%{event_name: event_name}) do
    %__MODULE__{
      event_name: event_name
    }
  end

  def from_input(%{property: property}) do
    %__MODULE__{
      property: parse_property(property)
    }
  end

  defp parse_date_range(nil), do: nil

  defp parse_date_range(%{from: from, to: to}) do
    %{from: from, to: to}
  end

  defp parse_date_range(_), do: nil

  defp parse_property(nil), do: nil

  defp parse_property(%{field: field, operator: operator, value: value}) do
    %{
      field: field,
      operator: operator,
      value: value
    }
  end

  defp parse_property(_), do: nil

  @doc """
  Returns the default event filter options.
  """
  def default do
    %__MODULE__{}
  end
end
