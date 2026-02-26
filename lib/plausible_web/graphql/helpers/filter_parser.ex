defmodule PlausibleWeb.GraphQL.Helpers.FilterParser do
  @moduledoc """
  Helper module for parsing GraphQL filters into stats query filters.
  """

  @doc """
  Parse GraphQL filter input into stats-compatible filter format.

  ## Examples

      iex> parse_filters([%{field: "pathname", operator: "contains", value: "/blog"}])
      {:ok, [[:page, :pathname, :contains, "/blog"]]}
  """
  def parse_filters(nil), do: {:ok, []}

  def parse_filters(filters) when is_list(filters) do
    results =
      Enum.map(filters, &parse_filter/1)

    if Enum.all?(results, &match?({:ok, _}, &1)) do
      {:ok, Enum.map(results, fn {:ok, filter} -> filter end)}
    else
      errors = Enum.filter(results, &match?({:error, _}, &1))
      {:error, Enum.map(errors, fn {:error, msg} -> msg end)}
    end
  end

  def parse_filter(%{field: field, operator: operator, value: value}) do
    with {:ok, parsed_field} <- parse_field(field),
         {:ok, parsed_operator} <- parse_operator(operator) do
      # Determine the event type based on the field
      event_type = get_event_type(field)

      {:ok, [event_type, parsed_field, parsed_operator, value]}
    end
  end

  defp parse_field("url"), do: {:ok, :pathname}
  defp parse_field("pathname"), do: {:ok, :pathname}
  defp parse_field("referrer"), do: {:ok, :referrer}
  defp parse_field("country"), do: {:ok, :country}
  defp parse_field("device"), do: {:ok, :device}
  defp parse_field("browser"), do: {:ok, :browser}
  defp parse_field("operating_system"), do: {:ok, :os}
  defp parse_field("name"), do: {:ok, :event_name}
  defp parse_field("event_name"), do: {:ok, :event_name}
  defp parse_field(field), do: {:ok, String.to_atom(field)}

  defp parse_operator("equals"), do: {:ok, :exact}
  defp parse_operator("not_equals"), do: {:ok, :does_not_equal}
  defp parse_operator("contains"), do: {:ok, :contains}
  defp parse_operator("not_contains"), do: {:ok, :does_not_contain}
  defp parse_operator("matches"), do: {:ok, :matches}
  defp parse_operator("greater_than"), do: {:ok, :greater}
  defp parse_operator("less_than"), do: {:ok, :less}
  defp parse_operator("is_set"), do: {:ok, :is_not_null}
  defp parse_operator("is_not_set"), do: {:ok, :is_null}
  defp parse_operator(op), do: {:error, "Unknown operator: #{op}"}

  defp get_event_type("name"), do: :event
  defp get_event_type("event_name"), do: :event
  defp get_event_type("properties"), do: :event
  defp get_event_type(_), do: :page
  end
