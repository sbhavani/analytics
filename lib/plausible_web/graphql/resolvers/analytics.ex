defmodule PlausibleWeb.GraphQL.Resolvers.Analytics do
  @moduledoc """
  GraphQL resolvers for analytics queries
  """

  alias Plausible.Stats
  alias PlausibleWeb.GraphQL.Resolvers.FilterParser
  alias PlausibleWeb.GraphQL.Error

  def aggregate(_parent, %{site_id: _site_id, input: input}, %{context: %{site: site}}) do
    # Validate date range (max 1 year)
    with :ok <- validate_date_range(input.date_range) do
      query = build_query(input, site)

      case Stats.aggregate(site, query, input.metrics) do
        {:ok, results} ->
          {:ok, %{
            visitors: Map.get(results, :visitors),
            pageviews: Map.get(results, :pageviews),
            events: Map.get(results, :events),
            bounce_rate: Map.get(results, :bounce_rate),
            visit_duration: Map.get(results, :visit_duration)
          }}

        {:error, reason} ->
          Error.internal_error("Failed to fetch aggregate data: #{inspect(reason)}")
      end
    end
  end

  def aggregate(_parent, _args, _context) do
    Error.unauthorized()
  end

  def breakdown(_parent, %{site_id: _site_id, input: input}, %{context: %{site: site}}) do
    with :ok <- validate_date_range(input.date_range),
         :ok <- validate_breakdown_limit(input.limit) do
      query = build_query(input, site)
      # Add pagination support via offset
      query = Map.put(query, :offset, input.offset || 0)

      case Stats.breakdown(site, query, input.dimension, input.metrics, input.limit || 100) do
        {:ok, results} ->
          formatted_results = Enum.map(results, fn row ->
            %{
              dimension: Map.get(row, :dimension) || Map.get(row, :value),
              visitors: Map.get(row, :visitors),
              pageviews: Map.get(row, :pageviews),
              events: Map.get(row, :events)
            }
          end)
          {:ok, formatted_results}

        {:error, reason} ->
          Error.internal_error("Failed to fetch breakdown data: #{inspect(reason)}")
      end
    end
  end

  def breakdown(_parent, _args, _context) do
    Error.unauthorized()
  end

  def timeseries(_parent, %{site_id: _site_id, input: input}, %{context: %{site: site}}) do
    with :ok <- validate_date_range(input.date_range) do
      query = build_query(input, site)
      granularity = parse_granularity(input.granularity)

      case Stats.timeseries(site, query, input.metrics, granularity) do
        {:ok, results} ->
          formatted_results = Enum.map(results, fn row ->
            %{
              date: Map.get(row, :date),
              visitors: Map.get(row, :visitors),
              pageviews: Map.get(row, :pageviews),
              events: Map.get(row, :events)
            }
          end)
          {:ok, formatted_results}

        {:error, reason} ->
          Error.internal_error("Failed to fetch timeseries data: #{inspect(reason)}")
      end
    end
  end

  def timeseries(_parent, _args, _context) do
    Error.unauthorized()
  end

  defp build_query(input, _site) do
    filters = FilterParser.parse_filters(input.filters)

    %{
      date_range: %{
        start: input.date_range.start_date,
        end: input.date_range.end_date
      },
      filters: filters,
      metrics: input.metrics
    }
  end

  defp validate_date_range(%{start_date: start, end_date: end_date}) do
    diff = Date.diff(end_date, start)

    cond do
      diff < 0 -> Error.invalid_date_range("Start date must be before end date")
      diff > 365 -> Error.invalid_date_range("Date range cannot exceed 1 year")
      true -> :ok
    end
  end

  defp validate_breakdown_limit(nil), do: :ok

  defp validate_breakdown_limit(limit) when limit > 0 and limit <= 1000, do: :ok

  defp validate_breakdown_limit(_), do: Error.validation("Breakdown limit must be between 1 and 1000", :limit)

  defp parse_granularity(:hourly), do: :hour
  defp parse_granularity(:daily), do: :day
  defp parse_granularity(:weekly), do: :week
  defp parse_granularity(:monthly), do: :month
end
