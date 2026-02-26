defmodule PlausibleWeb.GraphQL.Resolver do
  @moduledoc """
  Base resolver module with common utilities.
  """

  alias PlausibleWeb.GraphQL.Context

  @doc """
  Authorize site access for a GraphQL resolution.
  """
  def authorize_site!(%{context: %{user: user}}, site_id) do
    case Context.authorize_site(%{user: user}, site_id) do
      {:ok, site} -> site
      {:error, :site_not_found} -> raise Absinthe.Error, message: "Site not found"
      {:error, :unauthorized} -> raise Absinthe.Error, message: "Access denied to site '#{site_id}'"
      {:error, :invalid_site_id} -> raise Absinthe.Error, message: "Invalid site ID"
    end
  end

  def authorize_site!(_, _) do
    raise Absinthe.Error, message: "Authentication required"
  end

  @doc """
  Validate date range input.
  """
  def validate_date_range(%{from: from, to: to}) do
    case {parse_date(from), parse_date(to)} do
      {{:ok, from_date}, {:ok, to_date}} ->
        if Date.compare(from_date, to_date) == :gt do
          {:error, "Invalid date range: 'from' must be before 'to'"}
        else
          {:ok, %{from: from_date, to: to_date}}
        end

      {{:error, _}, _} ->
        {:error, "Invalid date format for 'from'. Use ISO 8601 format (YYYY-MM-DD)"}

      {_, {:error, _}} ->
        {:error, "Invalid date format for 'to'. Use ISO 8601 format (YYYY-MM-DD)"}
    end
  end

  def validate_date_range(nil) do
    today = Date.utc_today()
    thirty_days_ago = Date.add(today, -30)
    {:ok, %{from: thirty_days_ago, to: today}}
  end

  defp parse_date(date_string) when is_binary(date_string) do
    Date.from_iso8601(date_string)
  end

  defp parse_date(_), do: {:error, :invalid_date}

  @doc """
  Default date range (last 30 days).
  """
  def default_date_range do
    today = Date.utc_today()
    thirty_days_ago = Date.add(today, -30)
    %{from: thirty_days_ago, to: today}
  end
end
