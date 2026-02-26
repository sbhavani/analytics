defmodule PlausibleWeb.GraphQL.Resolvers.Pageviews do
  @moduledoc """
  Resolver for pageview queries.
  """

  alias Plausible.Stats
  alias Plausible.Stats.Query
  alias PlausibleWeb.GraphQL.Resolver
  alias PlausibleWeb.GraphQL.Logger, as: GQLLogger

  require Logger

  @doc """
  Query pageview data with optional filtering and aggregation.
  """
  def pageviews(_parent, %{site_id: site_id, date_range: date_range_input} = args, %{context: %{user: user} = context}) do
    start_time = System.monotonic_time(:millisecond)

    # Log operation start (structured logging per T044)
    GQLLogger.log_operation_start("pageviews", args, context)

    with {:ok, site} <- authorize_site(user, site_id),
         {:ok, date_range} <- Resolver.validate_date_range(date_range_input) do

      filters = parse_filters(args[:filters])
      aggregation = parse_aggregation(args[:aggregation])

      # Build the query
      query = Query.build(date_range, site, filters)

      # Execute the query based on aggregation type
      result = case aggregation do
        %{group_by: group_by, interval: interval} when group_by != nil or interval != nil ->
          query_time_series(query, site, group_by, interval, aggregation.type)

        %{type: type} ->
          query_aggregate(query, site, type)
      end

      # Log operation result
      duration_ms = System.monotonic_time(:millisecond) - start_time
      case result do
        {:ok, data} ->
          GQLLogger.log_operation_success("pageviews", args, context, length(data), duration_ms)
        {:error, error} ->
          GQLLogger.log_operation_error("pageviews", args, context, error, duration_ms)
      end

      result
    else
      {:error, :unauthorized} ->
        duration_ms = System.monotonic_time(:millisecond) - start_time
        GQLLogger.log_operation_error("pageviews", args, context, {:error, :unauthorized}, duration_ms)
        {:error, message: "Access denied to site '#{site_id}'", code: :authorization_error}

      {:error, :site_not_found} ->
        duration_ms = System.monotonic_time(:millisecond) - start_time
        GQLLogger.log_operation_error("pageviews", args, context, {:error, :site_not_found}, duration_ms)
        {:error, message: "Site not found", code: :not_found}

      {:error, message} ->
        duration_ms = System.monotonic_time(:millisecond) - start_time
        GQLLogger.log_operation_error("pageviews", args, context, {:error, message}, duration_ms)
        {:error, message: message, code: :validation_error}
    end
  end

  def pageviews(_, _, %{context: %{user: nil}}) do
    {:error, message: "Authentication required", code: :authentication_error}
  end

  defp authorize_site(user, site_id) do
    case PlausibleWeb.GraphQL.Context.authorize_site(%{user: user}, site_id) do
      {:ok, site} -> {:ok, site}
      {:error, :unauthorized} -> {:error, :unauthorized}
      {:error, :site_not_found} -> {:error, :site_not_found}
      {:error, :invalid_site_id} -> {:error, :invalid_site_id}
    end
  end

  defp parse_filters(nil), do: %{}

  defp parse_filters(filters) do
    Enum.reduce(filters, %{}, fn
      {:path, path}, acc when is_binary(path) and path != "" ->
        Map.put(acc, :page, path)

      {:referrer, referrer}, acc when is_binary(referrer) and referrer != "" ->
        Map.put(acc, :referrer, referrer)

      {:browser, browser}, acc when is_binary(browser) and browser != "" ->
        Map.put(acc, :browser, browser)

      {:device, device}, acc when is_binary(device) and device != "" ->
        Map.put(acc, :device, device)

      {:country, country}, acc when is_binary(country) and country != "" ->
        Map.put(acc, :country, country)

      _, acc ->
        acc
    end)
  end

  defp parse_aggregation(nil) do
    %{type: :count, group_by: nil, interval: nil}
  end

  defp parse_aggregation(%{type: type, group_by: group_by, interval: interval}) do
    %{
      type: parse_aggregation_type(type),
      group_by: parse_group_by(group_by),
      interval: parse_time_interval(interval)
    }
  end

  defp parse_aggregation_type(:sum), do: :sum
  defp parse_aggregation_type(:count), do: :count
  defp parse_aggregation_type(:avg), do: :avg
  defp parse_aggregation_type(:min), do: :min
  defp parse_aggregation_type(:max), do: :max
  defp parse_aggregation_type(_), do: :count

  defp parse_group_by(:path), do: :pathname
  defp parse_group_by(:url), do: :url
  defp parse_group_by(:browser), do: :browser
  defp parse_group_by(:device), do: :device
  defp parse_group_by(:country), do: :country
  defp parse_group_by(:referrer), do: :referrer
  defp parse_group_by(nil), do: nil

  defp parse_time_interval(:minute), do: :minute
  defp parse_time_interval(:hour), do: :hour
  defp parse_time_interval(:day), do: :date
  defp parse_time_interval(:week), do: :week
  defp parse_time_interval(:month), do: :month
  defp parse_time_interval(nil), do: nil

  defp query_time_series(query, site, group_by, interval, aggregation_type) do
    # Query with time series and/or group by
    results = Stats.breakdown(site, query, group_by, [aggregation_type], interval)

    {:ok, Enum.map(results, fn row ->
      %{
        count: Map.get(row, :count, 0),
        visitors: Map.get(row, :visitors, 0),
        group: Map.get(row, group_by),
        period: format_period(row, interval)
      }
    end)}
  rescue
    e ->
      Logger.error("Error querying pageviews: #{inspect(e)}")
      {:error, "Failed to query pageview data"}
  end

  defp query_aggregate(query, site, aggregation_type) do
    # Simple aggregate query
    result = Stats.aggregate(site, query, [aggregation_type])

    {:ok, [%{
      count: Map.get(result, :count, 0) || 0,
      visitors: Map.get(result, :visitors, 0) || 0,
      group: nil,
      period: nil
    }]}
  rescue
    e ->
      Logger.error("Error querying pageviews: #{inspect(e)}")
      {:error, "Failed to query pageview data"}
  end

  defp format_period(row, :minute), do: Map.get(row, :date)
  defp format_period(row, :hour), do: Map.get(row, :date)
  defp format_period(row, :date), do: Map.get(row, :date)
  defp format_period(row, :week), do: Map.get(row, :date)
  defp format_period(row, :month), do: Map.get(row, :date)
  defp format_period(_, _), do: nil
end
