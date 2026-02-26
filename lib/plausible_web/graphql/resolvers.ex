defmodule PlausibleWeb.GraphQL.Resolvers do
  @moduledoc """
  GraphQL resolvers for analytics queries.
  """

  alias Plausible.Stats
  alias Plausible.Stats.Query
  alias Plausible.Site
  alias Plausible.Repo

  @spec pageviews(any(), %{required(:site_id) => String.t(), optional(:filter) => map(), optional(:limit) => integer(), optional(:offset) => integer()}, any()) ::
          {:ok, [map()]} | {:error, String.t()}
  def pageviews(_parent, %{site_id: site_id} = args, _info) do
    with {:ok, site} <- get_site(site_id),
         {:ok, query} <- build_query(site, args[:filter]) do
      pagination = %{limit: args[:limit] || 100, offset: args[:offset] || 0}

      case Stats.breakdown(site, query, [:visitors, :pageviews], pagination) do
        {:ok, results} ->
          formatted = Enum.map(results, &format_pageview/1)
          {:ok, formatted}

        {:error, reason} ->
          {:error, inspect(reason)}
      end
    else
      {:error, reason} -> {:error, inspect(reason)}
    end
  end

  @spec pageviews_aggregate(any(), %{required(:site_id) => String.t(), required(:aggregation) => map()}, any()) ::
          {:ok, map()} | {:error, String.t()}
  def pageviews_aggregate(_parent, %{site_id: site_id, aggregation: agg} = args, _info) do
    with {:ok, site} <- get_site(site_id),
         {:ok, query} <- build_query(site, args[:filter]) do
      metrics = [String.to_atom(agg.metric)]

      case Stats.aggregate(site, query, metrics) do
        {:ok, results} ->
          formatted = %{
            metric: agg.metric,
            value: Map.get(results, hd(metrics), 0.0)
          }
          {:ok, formatted}

        {:error, reason} ->
          {:error, inspect(reason)}
      end
    else
      {:error, reason} -> {:error, inspect(reason)}
    end
  end

  @spec pageviews_timeseries(any(), %{required(:site_id) => String.t(), required(:interval) => String.t()}, any()) ::
          {:ok, [map()]} | {:error, String.t()}
  def pageviews_timeseries(_parent, %{site_id: site_id, interval: interval} = args, _info) do
    with {:ok, site} <- get_site(site_id),
         {:ok, query} <- build_query(site, args[:filter], interval) do
      case Stats.timeseries(site, query, [:visitors, :pageviews]) do
        {:ok, results} ->
          formatted = Enum.map(results, &format_timeseries/1)
          {:ok, formatted}

        {:error, reason} ->
          {:error, inspect(reason)}
      end
    else
      {:error, reason} -> {:error, inspect(reason)}
    end
  end

  @spec events(any(), %{required(:site_id) => String.t(), optional(:filter) => map(), optional(:event_type) => String.t(), optional(:limit) => integer(), optional(:offset) => integer()}, any()) ::
          {:ok, [map()]} | {:error, String.t()}
  def events(_parent, %{site_id: site_id} = args, _info) do
    with {:ok, site} <- get_site(site_id),
         {:ok, query} <- build_event_query(site, args[:filter], args[:event_type]) do
      pagination = %{limit: args[:limit] || 100, offset: args[:offset] || 0}

      case Stats.breakdown(site, query, [:visitors, :events], pagination) do
        {:ok, results} ->
          formatted = Enum.map(results, &format_event/1)
          {:ok, formatted}

        {:error, reason} ->
          {:error, inspect(reason)}
      end
    else
      {:error, reason} -> {:error, inspect(reason)}
    end
  end

  @spec events_aggregate(any(), %{required(:site_id) => String.t(), required(:aggregation) => map(), optional(:event_type) => String.t()}, any()) ::
          {:ok, map()} | {:error, String.t()}
  def events_aggregate(_parent, %{site_id: site_id, aggregation: agg, event_type: event_type} = args, _info) do
    with {:ok, site} <- get_site(site_id),
         {:ok, query} <- build_event_query(site, args[:filter], event_type) do
      metrics = [String.to_atom(agg.metric)]

      case Stats.aggregate(site, query, metrics) do
        {:ok, results} ->
          formatted = %{
            metric: agg.metric,
            value: Map.get(results, hd(metrics), 0.0)
          }
          {:ok, formatted}

        {:error, reason} ->
          {:error, inspect(reason)}
      end
    else
      {:error, reason} -> {:error, inspect(reason)}
    end
  end

  @spec custom_metrics(any(), %{required(:site_id) => String.t()}, any()) ::
          {:ok, [map()]} | {:error, String.t()}
  def custom_metrics(_parent, %{site_id: site_id} = args, _info) do
    with {:ok, site} <- get_site(site_id),
         {:ok, query} <- build_query(site, args[:filter]) do
      # Get custom goals/metrics for the site
      goals = Repo.all(Plausible.Goal.for_site(site.id))

      metrics =
        Enum.map(goals, fn goal ->
          %{
            name: goal.name,
            value: 0.0,
            formula: "Goal: #{goal.name}"
          }
        end)

      {:ok, metrics}
    else
      {:error, reason} -> {:error, inspect(reason)}
    end
  end

  @spec analytics(any(), %{required(:site_id) => String.t(), required(:metrics) => [String.t()], optional(:interval) => String.t()}, any()) ::
          {:ok, [map()]} | {:error, String.t()}
  def analytics(_parent, %{site_id: site_id, metrics: metrics} = args, _info) do
    with {:ok, site} <- get_site(site_id),
         {:ok, query} <- build_query(site, args[:filter], args[:interval]) do
      metrics_atoms = Enum.map(metrics, &String.to_atom/1)

      case Stats.timeseries(site, query, metrics_atoms) do
        {:ok, results} ->
          formatted = Enum.map(results, &format_timeseries/1)
          {:ok, formatted}

        {:error, reason} ->
          {:error, inspect(reason)}
      end
    else
      {:error, reason} -> {:error, inspect(reason)}
    end
  end

  defp get_site(site_id) do
    case Repo.get_by(Site, domain: site_id) do
      nil -> {:error, "Site not found"}
      site -> {:ok, site}
    end
  end

  defp build_query(site, filter, interval \\ nil) do
    params = %{}

    params =
      if filter do
        filter_params = build_filter_params(filter)
        Map.merge(params, filter_params)
      else
        params
      end

    params =
      if interval do
        Map.put(params, "period", interval_to_period(interval))
      else
        Map.put(params, "period", "30d")
      end

    case Query.parse_and_build(site, params) do
      {:ok, query} -> {:ok, query}
      {:error, reason} -> {:error, inspect(reason)}
    end
  end

  defp build_event_query(site, filter, event_type) do
    params = %{}

    params =
      if event_type do
        Map.put(params, "event", event_type)
      else
        params
      end

    params =
      if filter do
        filter_params = build_filter_params(filter)
        Map.merge(params, filter_params)
      else
        params
      end

    params = Map.put(params, "period", "30d")

    case Query.parse_and_build(site, params) do
      {:ok, query} -> {:ok, query}
      {:error, reason} -> {:error, inspect(reason)}
    end
  end

  defp build_filter_params(filter) do
    params = %{}

    params =
      if filter[:date_range] do
        dr = filter[:date_range]
        Map.merge(params, %{
          "date" => "#{dr.start_date}:#{dr.end_date}"
        })
      else
        params
      end

    params =
      if filter[:url_pattern] do
        Map.merge(params, %{"page" => filter[:url_pattern]})
      else
        params
      end

    params =
      if filter[:referrer] do
        Map.merge(params, %{"source" => filter[:referrer]})
      else
        params
      end

    params =
      if filter[:device_type] do
        device = Atom.to_string(filter[:device_type])
        Map.merge(params, %{"device" => device})
      else
        params
      end

    params =
      if filter[:country] do
        Map.merge(params, %{"country" => filter[:country]})
      else
        params
      end

    params =
      if filter[:region] do
        Map.merge(params, %{"region" => filter[:region]})
      else
        params
      end

    params =
      if filter[:city] do
        Map.merge(params, %{"city" => filter[:city]})
      else
        params
      end

    params
  end

  defp interval_to_period("hour"), do: "hour"
  defp interval_to_period("day"), do: "day"
  defp interval_to_period("week"), do: "week"
  defp interval_to_period("month"), do: "month"
  defp interval_to_period(_), do: "day"

  defp format_pageview(row) do
    %{
      url: row[:path] || "",
      visitor_count: row[:visitors] || 0,
      view_count: row[:pageviews] || 0,
      timestamp: row[:date] || DateTime.utc_now()
    }
  end

  defp format_event(row) do
    %{
      name: row[:event] || "",
      count: row[:events] || 0,
      timestamp: row[:date] || DateTime.utc_now(),
      properties: %{}
    }
  end

  defp format_timeseries(row) do
    %{
      date: row[:date] || DateTime.utc_now(),
      visitors: row[:visitors],
      pageviews: row[:pageviews],
      events: row[:events]
    }
  end
end
