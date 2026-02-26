defmodule PlausibleWeb.GraphQL.Resolvers.CustomMetrics do
  @moduledoc """
  Resolver for custom metrics queries.
  """

  alias Plausible.Stats
  alias Plausible.Stats.Query
  alias Plausible.Goals
  alias PlausibleWeb.GraphQL.Resolver
  alias PlausibleWeb.GraphQL.Logger, as: GQLLogger

  require Logger

  @doc """
  Query custom metrics with optional filtering.
  """
  def custom_metrics(_parent, %{site_id: site_id} = args, %{context: %{user: user} = context}) do
    start_time = System.monotonic_time(:millisecond)

    # Log operation start (structured logging per T044)
    GQLLogger.log_operation_start("custom_metrics", args, context)

    with {:ok, site} <- authorize_site(user, site_id),
         {:ok, date_range} <- Resolver.validate_date_range(args[:date_range]) do

      # Get all custom metrics (goals) for the site
      goals = Goals.get_all(site)

      # Filter by name if provided
      filtered_goals = filter_goals(goals, args[:name], args[:category])

      # Build query and get metrics
      query = Query.build(date_range, site, %{})

      metrics = Enum.map(filtered_goals, fn goal ->
        case Goals.get_revenue_metrics(goal) do
          [] ->
            # Regular goal - get aggregate
            result = Stats.aggregate(site, query, [:count], goal)

            %{
              id: goal.id,
              name: goal.name,
              display_name: goal.name,
              value: Map.get(result, :count, 0) || 0,
              unit: nil,
              category: goal.event_name
            }

          revenue_metrics ->
            # Revenue goal - get revenue values
            Enum.map(revenue_metrics, fn metric ->
              result = Stats.aggregate(site, query, [:sum], metric)

              %{
                id: "#{goal.id}-#{metric}",
                name: "#{goal.name}_#{metric}",
                display_name: "#{goal.name} (#{metric})",
                value: Map.get(result, :sum, 0) || 0,
                unit: "currency",
                category: goal.event_name
              }
            end)
        end
      end)

      result = {:ok, List.flatten(metrics)}

      # Log operation result
      duration_ms = System.monotonic_time(:millisecond) - start_time
      case result do
        {:ok, data} ->
          GQLLogger.log_operation_success("custom_metrics", args, context, length(data), duration_ms)
        {:error, error} ->
          GQLLogger.log_operation_error("custom_metrics", args, context, error, duration_ms)
      end

      result
    else
      {:error, :unauthorized} ->
        duration_ms = System.monotonic_time(:millisecond) - start_time
        GQLLogger.log_operation_error("custom_metrics", args, context, {:error, :unauthorized}, duration_ms)
        {:error, message: "Access denied to site '#{site_id}'", code: :authorization_error}

      {:error, :site_not_found} ->
        duration_ms = System.monotonic_time(:millisecond) - start_time
        GQLLogger.log_operation_error("custom_metrics", args, context, {:error, :site_not_found}, duration_ms)
        {:error, message: "Site not found", code: :not_found}

      {:error, message} ->
        duration_ms = System.monotonic_time(:millisecond) - start_time
        GQLLogger.log_operation_error("custom_metrics", args, context, {:error, message}, duration_ms)
        {:error, message: message, code: :validation_error}
    end
  end

  def custom_metrics(_, _, %{context: %{user: nil}}) do
    {:error, message: "Authentication required", code: :authentication_error}
  end

  @doc """
  Query custom metrics time series.
  """
  def custom_metrics_time_series(_parent, %{site_id: site_id, metric_name: metric_name, date_range: date_range_input, interval: interval}, %{context: %{user: user} = context}) do
    start_time = System.monotonic_time(:millisecond)

    # Log operation start (structured logging per T044)
    GQLLogger.log_operation_start("custom_metrics_time_series", %{site_id: site_id, metric_name: metric_name}, context)

    with {:ok, site} <- authorize_site(user, site_id),
         {:ok, date_range} <- Resolver.validate_date_range(date_range_input) do

      query = Query.build(date_range, site, %{})

      # Find the goal for this metric
      goal = find_goal(site, metric_name)

      result = if goal do
        results = Stats.breakdown(site, query, :date, [:count], parse_interval(interval))

        {:ok, Enum.map(results, fn row ->
          %{
            timestamp: format_timestamp(Map.get(row, :date)),
            value: Map.get(row, :count, 0)
          }
        end)}
      else
        {:error, message: "Custom metric '#{metric_name}' not found", code: :not_found}
      end

      # Log operation result
      duration_ms = System.monotonic_time(:millisecond) - start_time
      case result do
        {:ok, data} ->
          GQLLogger.log_operation_success("custom_metrics_time_series", %{site_id: site_id, metric_name: metric_name}, context, length(data), duration_ms)
        {:error, error} ->
          GQLLogger.log_operation_error("custom_metrics_time_series", %{site_id: site_id, metric_name: metric_name}, context, error, duration_ms)
      end

      result
    else
      {:error, :unauthorized} ->
        duration_ms = System.monotonic_time(:millisecond) - start_time
        GQLLogger.log_operation_error("custom_metrics_time_series", %{site_id: site_id, metric_name: metric_name}, context, {:error, :unauthorized}, duration_ms)
        {:error, message: "Access denied to site '#{site_id}'", code: :authorization_error}

      {:error, :site_not_found} ->
        duration_ms = System.monotonic_time(:millisecond) - start_time
        GQLLogger.log_operation_error("custom_metrics_time_series", %{site_id: site_id, metric_name: metric_name}, context, {:error, :site_not_found}, duration_ms)
        {:error, message: "Site not found", code: :not_found}

      {:error, message} ->
        duration_ms = System.monotonic_time(:millisecond) - start_time
        GQLLogger.log_operation_error("custom_metrics_time_series", %{site_id: site_id, metric_name: metric_name}, context, {:error, message}, duration_ms)
        {:error, message: message, code: :validation_error}
    end
  end

  def custom_metrics_time_series(_, _, %{context: %{user: nil}}) do
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

  defp filter_goals(goals, name, category) do
    goals
    |> Enum.filter(fn goal ->
      matches_name?(goal, name) && matches_category?(goal, category)
    end)
  end

  defp matches_name?(_goal, nil), do: true
  defp matches_name?(goal, name) do
    String.contains?(String.downcase(goal.name), String.downcase(name))
  end

  defp matches_category?(_goal, nil), do: true
  defp matches_category?(goal, category) do
    goal.event_name == category
  end

  defp find_goal(site, metric_name) do
    Goals.get_all(site)
    |> Enum.find(fn goal ->
      goal.name == metric_name ||
      String.contains?(String.downcase(goal.name), String.downcase(metric_name))
    end)
  end

  defp parse_interval(:minute), do: :minute
  defp parse_interval(:hour), do: :hour
  defp parse_interval(:day), do: :date
  defp parse_interval(:week), do: :week
  defp parse_interval(:month), do: :month
  defp parse_interval(_), do: :date

  defp format_timestamp(date) when is_binary(date) do
    date
  end

  defp format_timestamp(date) do
    Date.to_string(date)
  end
end
