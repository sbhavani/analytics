defmodule Plausible.GraphQL.Resolvers.Analytics do
  @moduledoc """
  Resolver for analytics GraphQL queries
  """
  import Plausible.GraphQL.Helpers

  alias Plausible.Stats
  alias Plausible.Stats.{Aggregate, Breakdown, Timeseries}
  alias Plausible.GraphQL.ErrorHandler

  require Logger

  @telemetry_event [:plausible, :graphql, :query]

  def analytics(_parent, %{site_id: site_id} = args, %{context: %{site: site}}) do
    start = System.monotonic_time(:millisecond)

    result = %{
      pageviews: get_pageviews(site, args),
      events: get_events(site, args),
      custom_metrics: get_custom_metrics(site, args),
      timeseries: get_timeseries(site, args),
      metadata: %{
        site: site,
        date_range: get_date_range(args)
      }
    }

    # Emit telemetry
    duration = System.monotonic_time(:millisecond) - start
    :telemetry.execute(@telemetry_event, %{duration: duration}, %{site_id: site_id})

    {:ok, result}
  end

  def analytics(_parent, _args, _context) do
    {:error, ErrorHandler.handle_error(:unauthorized)}
  end

  # Get pageview data using Plausible.Stats.Aggregate
  defp get_pageviews(site, args) do
    date_range = parse_date_range(args)

    query = Stats.build_query(site, date_range, :aggregate)

    case Aggregate.run(query, site) do
      %{visitors: visitors, pageviews: pageviews, bounce_rate: bounce_rate, visit_duration: visit_duration} ->
        %{
          visitors: visitors || 0,
          pageviews: pageviews || 0,
          bounce_rate: bounce_rate || 0.0,
          visit_duration: visit_duration || 0
        }

      _ ->
        %{
          visitors: 0,
          pageviews: 0,
          bounce_rate: 0.0,
          visit_duration: 0
        }
    end
  end

  # Get event data using Plausible.Stats.Breakdown
  defp get_events(site, args) do
    date_range = parse_date_range(args)
    filters = parse_filters(args)

    query = Stats.build_query(site, date_range, :breakdown, filters)

    case Breakdown.run(query, site, [[:event_name], [:name]], 100) do
      results when is_list(results) ->
        Enum.map(results, fn row ->
          %{
            name: row[:event_name] || row[:name] || "",
            count: row[:events] || 0,
            unique_visitors: row[:visitors] || 0
          }
        end)

      _ ->
        []
    end
  end

  # Get custom metrics (placeholder - would need custom metrics implementation)
  defp get_custom_metrics(_site, _args) do
    []
  end

  # Get timeseries data using Plausible.Stats.Timeseries
  defp get_timeseries(site, args) do
    date_range = parse_date_range(args)
    filters = parse_filters(args)

    query = Stats.build_query(site, date_range, :timeseries, filters)

    period = get_in(args, [:date_range, :period]) || :daily

    case Timeseries.run(query, site, period) do
      results when is_list(results) ->
        Enum.map(results, fn row ->
          %{
            date: row[:date] || DateTime.utc_now(),
            visitors: row[:visitors] || 0,
            pageviews: row[:pageviews] || 0
          }
        end)

      _ ->
        []
    end
  end

  defp parse_date_range(args) do
    case args[:date_range] do
      %{from: from, to: to} ->
        %{from: parse_date(from), to: parse_date(to)}

      _ ->
        # Default to last 30 days
        to = Date.utc_today()
        from = Date.add(to, -30)
        %{from: from, to: to}
    end
  end

  defp parse_date(date) when is_binary(date) do
    Date.from_iso8601!(date)
  end

  defp parse_date(date) when is_struct(date, Date) do
    date
  end

  defp parse_date(_), do: Date.utc_today()

  defp parse_filters(args) do
    case args[:filters] do
      %{source: source, medium: medium, country: country, device: device, page: page, event_name: event_name} ->
        filters = []

        filters =
          if source do
            [{"is", "source", [source]} | filters]
          else
            filters
          end

        filters =
          if medium do
            [{"is", "medium", [medium]} | filters]
          else
            filters
          end

        filters =
          if country do
            [{"is", "country", [country]} | filters]
          else
            filters
          end

        filters =
          if device do
            [{"is", "device", [Atom.to_string(device)]} | filters]
          else
            filters
          end

        filters =
          if page do
            [{"is", "pathname", [page]} | filters]
          else
            filters
          end

        if event_name do
          [{"is", "event:name", [event_name]} | filters]
        else
          filters
        end

      _ ->
        []
    end
  end

  defp get_date_range(args) do
    case args[:date_range] do
      %{from: from, to: to, period: period} ->
        %{
          from: parse_date(from),
          to: parse_date(to),
          period: period || :daily
        }

      %{from: from, to: to} ->
        %{
          from: parse_date(from),
          to: parse_date(to),
          period: :daily
        }

      _ ->
        to = Date.utc_today()
        from = Date.add(to, -30)
        %{from: from, to: to, period: :daily}
    end
  end
end
