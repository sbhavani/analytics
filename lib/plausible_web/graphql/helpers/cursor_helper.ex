defmodule PlausibleWeb.GraphQL.Helpers.CursorHelper do
  @moduledoc """
  Helper module for cursor-based pagination.
  """

  @doc """
  Encode a cursor from a pageview/timestamp.
  """
  def encode_cursor(%{timestamp: timestamp, id: id}) do
    cursor_string = "#{timestamp}|#{id}"
    Base.encode64(cursor_string)
  end

  @doc """
  Encode a cursor from raw values.
  """
  def encode_cursor(timestamp, id) when is_binary(id) do
    cursor_string = "#{timestamp}|#{id}"
    Base.encode64(cursor_string)
  end

  def encode_cursor(timestamp, id) do
    cursor_string = "#{timestamp}|#{id}"
    Base.encode64(cursor_string)
  end

  @doc """
  Decode a cursor to get timestamp and id.
  """
  def decode_cursor(nil), do: nil

  def decode_cursor(cursor) do
    case Base.decode64(cursor) do
      {:ok, decoded} ->
        case String.split(decoded, "|", parts: 2) do
          [timestamp, id] ->
            {:ok, %{timestamp: timestamp, id: id}}

          _ ->
            {:error, "Invalid cursor format"}
        end

      :error ->
        {:error, "Invalid cursor encoding"}
    end
  end

  @doc """
  Calculate pagination metadata.
  """
  def calculate_page_info(items, limit, cursor) do
    has_more = length(items) > limit
    display_items = Enum.take(items, limit)

    %{
      has_next_page: has_more,
      has_previous_page: cursor != nil,
      start_cursor: get_first_cursor(display_items),
      end_cursor: get_last_cursor(display_items)
    }
  end

  defp get_first_cursor([]), do: nil
  defp get_first_cursor([first | _]), do: encode_cursor(first)

  defp get_last_cursor([]), do: nil
  defp get_last_cursor(items), do: items |> List.last() |> encode_cursor()
end
