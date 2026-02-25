defmodule PlausibleWeb.GraphQL.Types.PageviewFilter do
  @moduledoc """
  GraphQL types for pageview filter input.
  """

  defstruct date_range: nil,
            url: nil,
            country: nil,
            device: nil,
            referrer: nil

  @type t :: %__MODULE__{
          date_range: %{from: DateTime.t(), to: DateTime.t()} | nil,
          url: String.t() | nil,
          country: String.t() | nil,
          device: atom() | nil,
          referrer: String.t() | nil
        }

  @doc """
  Creates a PageviewFilter struct from GraphQL input.
  """
  def from_input(nil) do
    %__MODULE__{}
  end

  def from_input(%{date_range: date_range} = input) do
    %__MODULE__{
      date_range: parse_date_range(date_range),
      url: Map.get(input, :url),
      country: Map.get(input, :country),
      device: parse_device(Map.get(input, :device)),
      referrer: Map.get(input, :referrer)
    }
  end

  def from_input(%{} = input) do
    %__MODULE__{
      date_range: nil,
      url: Map.get(input, :url),
      country: Map.get(input, :country),
      device: parse_device(Map.get(input, :device)),
      referrer: Map.get(input, :referrer)
    }
  end

  defp parse_date_range(%{from: from, to: to}) do
    %{from: from, to: to}
  end

  defp parse_date_range(_), do: nil

  defp parse_device(nil), do: nil
  defp parse_device(device) when is_atom(device), do: device
  defp parse_device(device) when is_binary(device), do: String.to_existing_atom(device)

  @doc """
  Returns the default pageview filter options.
  """
  def default do
    %__MODULE__{}
  end

  @doc """
  Validates that the date range does not exceed 1 year.
  """
  def validate_date_range(%__MODULE__{date_range: date_range}) do
    validate_date_range(date_range)
  end

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
