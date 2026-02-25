defmodule Plausible.GraphQL.Resolvers.MetricResolver do
  @moduledoc """
  Resolver for custom metric queries
  """

  alias Plausible.Stats
  alias Plausible.Repo

  def resolve_metrics(_root, %{site_id: site_id, date_range: date_range, filters: filters} = args, %{context: %{site: site}}) do
    with {:ok, start_date} <- parse_date(date_range.start_date),
         {:ok, end_date} <- parse_date(date_range.end_date),
         :ok <- validate_date_range(start_date, end_date),
         :ok <- validate_metric_name(filters.metric_name),
         {data, aggregated} <- fetch_metrics(site, start_date, end_date, filters.metric_name, args) do
      {:ok, %{
        data: data,
        pagination: build_pagination(args[:pagination], length(data)),
        aggregated: aggregated
      }}
    else
      error -> handle_error(error)
    end
  end

  def resolve_metrics(_root, _args, _context) do
    {:error, %{message: "Site context and metric name required"}}
  end

  defp parse_date(date) when is_binary(date) do
    case Date.from_iso8601(date) do
      {:ok, date} -> {:ok, date}
      _ -> {:error, :invalid_date_format}
    end
  end

  defp parse_date(date) when is_struct(date, Date) do
    {:ok, date}
  end

  defp validate_date_range(start_date, end_date) do
    days_diff = Date.diff(end_date, start_date)
    if days_diff > 366 do
      {:error, :date_range_exceeds_maximum}
    else
      :ok
    end
  end

  defp validate_metric_name(nil) do
    {:error, :metric_name_required}
  end

  defp validate_metric_name(name) when is_binary(name) and name != "" do
    :ok
  end

  defp validate_metric_name(_) do
    {:error, :metric_name_required}
  end

  defp fetch_metrics(site, start_date, end_date, metric_name, args) do
    pagination = args[:pagination] || %{limit: 100, offset: 0}
    aggregation = args[:aggregation]
    # Placeholder - actual implementation would query ClickHouse
    {[], 0.0}
  end

  defp build_pagination(nil, total) do
    %{
      limit: 100,
      offset: 0,
      has_more: false,
      total: total
    }
  end

  defp build_pagination(pagination, total) do
    limit = pagination[:limit] || 100
    offset = pagination[:offset] || 0

    %{
      limit: limit,
      offset: offset,
      has_more: offset + limit < total,
      total: total
    }
  end

  defp handle_error({:error, :invalid_date_format}) do
    {:error, %{message: "Invalid date format. Use ISO 8601 format (YYYY-MM-DD)."}}
  end

  defp handle_error({:error, :date_range_exceeds_maximum}) do
    {:error, %{message: "Date range cannot exceed 366 days."}}
  end

  defp handle_error({:error, :metric_name_required}) do
    {:error, %{message: "metric_name is required"}}
  end

  defp handle_error({:error, message}) when is_binary(message) do
    {:error, %{message: message}}
  end

  defp handle_error(error) do
    {:error, %{message: "An error occurred: #{inspect(error)}"}}
  end
end
