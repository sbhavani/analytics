defmodule PlausibleWeb.GraphQL.Resolvers.Helpers do
  @moduledoc """
  Helper utilities for GraphQL resolvers.
  """

  require Logger

  @doc """
  Parses a date range from the input map.
  """
  def parse_date_range(%{from: from, to: to}) do
    case {Date.from_iso8601(from), Date.from_iso8601(to)} do
      {{:ok, from_date}, {:ok, to_date}} ->
        {:ok, %{from: from_date, to: to_date}}

      {{:error, _}, _} ->
        {:error, "Invalid 'from' date format. Expected ISO 8601 format (YYYY-MM-DD)."}

      {_, {:error, _}} ->
        {:error, "Invalid 'to' date format. Expected ISO 8601 format (YYYY-MM-DD)."}
    end
  end

  def parse_date_range(nil), do: {:ok, nil}

  @doc """
  Validates date range (from <= to).
  """
  def validate_date_range(%{from: from, to: to}) do
    if Date.compare(from, to) == :gt do
      {:error, "'from' date must be before or equal to 'to' date."}
    else
      {:ok, :valid}
    end
  end

  def validate_date_range(_), do: {:ok, :valid}

  @doc """
  Gets a site by domain/site_id.
  """
  def get_site(site_id) do
    case Plausible.Site.get_by_domain_or_id(site_id) do
      nil -> {:error, :site_not_found}
      site -> {:ok, site}
    end
  end

  @doc """
  Builds a query from the given params.
  """
  def build_query(site, date_range, filter \\ %{}) do
    Plausible.Stats.Query.from(site, %{
      "from" => Date.to_iso8601(date_range.from),
      "to" => Date.to_iso8601(date_range.to)
    })
  end

  @doc """
  Handles stats results and converts to GraphQL format.
  """
  def handle_stats_result({:error, :site_not_found}) do
    {:error, message: "Site not found", code: :not_found}
  end

  def handle_stats_result({:error, %Ecto.Query.CompileError{} = error}) do
    Logger.error("Query compilation error: #{inspect(error)}")
    {:error, message: "Invalid query parameters", code: :bad_request}
  end

  def handle_stats_result({:error, error}) when is_atom(error) do
    Logger.error("Stats error: #{inspect(error)}")
    {:error, message: "Internal error", code: :internal_error}
  end

  def handle_stats_result({:ok, data}), do: {:ok, data}

  @doc """
  Returns an empty connection for GraphQL.
  """
  def empty_connection do
    %{
      edges: [],
      page_info: %{
        has_next_page: false,
        has_previous_page: false,
        start_cursor: nil,
        end_cursor: nil
      },
      total_count: 0
    }
  end

  @doc """
  Logs GraphQL operation.
  """
  def log_operation(operation, site_id, duration_ms) do
    Logger.info(
      "GraphQL operation: #{operation}, site_id: #{site_id}, duration_ms: #{duration_ms}"
    )
  end
end
