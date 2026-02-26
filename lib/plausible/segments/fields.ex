defmodule Plausible.Segments.Fields do
  @moduledoc """
  Module defining available filter fields for the advanced filter builder.
  """

  @type filter_field() :: %{
    name: String.t(),
    display_name: String.t(),
    data_type: :string | :number | :date,
    operators: [String.t()],
    options: [String.t()] | nil
  }

  @fields [
    %{
      name: "country",
      display_name: "Country",
      data_type: :string,
      operators: ["equals", "not_equals", "contains", "is_empty", "is_not_empty"],
      options: country_options()
    },
    %{
      name: "pages_visited",
      display_name: "Pages Visited",
      data_type: :number,
      operators: ["equals", "not_equals", "greater_than", "less_than"]
    },
    %{
      name: "session_duration",
      display_name: "Session Duration (seconds)",
      data_type: :number,
      operators: ["equals", "not_equals", "greater_than", "less_than"]
    },
    %{
      name: "total_spent",
      display_name: "Total Spent",
      data_type: :number,
      operators: ["equals", "not_equals", "greater_than", "less_than"]
    },
    %{
      name: "device_type",
      display_name: "Device Type",
      data_type: :string,
      operators: ["equals", "not_equals", "is_empty", "is_not_empty"],
      options: ["Desktop", "Mobile", "Tablet"]
    },
    %{
      name: "referrer_source",
      display_name: "Referrer Source",
      data_type: :string,
      operators: ["equals", "not_equals", "contains", "is_empty", "is_not_empty"]
    }
  ]

  @doc """
  Returns all available filter fields.
  """
  def all, do: @fields

  @doc """
  Returns a specific field by name.
  """
  def get(name) do
    Enum.find(@fields, fn f -> f.name == name end)
  end

  @doc """
  Returns all field names.
  """
  def field_names do
    Enum.map(@fields, & &1.name)
  end

  @doc """
  Returns operators for a specific field.
  """
  def operators_for_field(name) do
    case get(name) do
      nil -> []
      field -> field.operators
    end
  end

  @doc """
  Returns options for a specific field (if available).
  """
  def options_for_field(name) do
    case get(name) do
      nil -> nil
      field -> field.options
    end
  end

  # Private functions

  defp country_options do
    [
      "United States", "United Kingdom", "Germany", "France", "Canada",
      "Australia", "Japan", "Brazil", "India", "Spain", "Italy",
      "Netherlands", "Sweden", "Norway", "Denmark", "Finland",
      "Belgium", "Switzerland", "Austria", "Ireland", "Poland"
    ]
  end
end
