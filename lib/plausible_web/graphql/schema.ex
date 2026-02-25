defmodule PlausibleWeb.GraphQL.Schema do
  use Absinthe.Schema

  alias PlausibleWeb.GraphQL.Resolvers.{Pageview, Event, Metric}

  # Import input types from separate modules
  import_types PlausibleWeb.GraphQL.Types.DateRange
  import_types PlausibleWeb.GraphQL.Types.Pagination
  import_types PlausibleWeb.GraphQL.Types.Filters
  import_types PlausibleWeb.GraphQL.Types.AggregationInput
  import_types PlausibleWeb.GraphQL.Types.EventType
  import_types PlausibleWeb.GraphQL.Types.MetricDataPoint
  import_types PlausibleWeb.GraphQL.Types.MetricType

  # Scalar types
  scalar :date_time do
    parse(&parse_datetime/1)
    serialize(&format_datetime/1)
  end

  scalar :json do
    parse(&parse_json/1)
    serialize(&encode_json/1)
  end

  # Enums
  enum :filter_operator do
    value :eq
    value :neq
    value :contains
    value :gt
    value :gte
    value :lt
    value :lte
  end

  enum :aggregation_type do
    value :count
    value :sum
    value :avg
    value :min
    value :max
  end

  enum :device_type do
    value :desktop
    value :mobile
    value :tablet
  end

  enum :time_interval do
    value :minute
    value :hour
    value :day
    value :week
    value :month
  end

  # Object types - Results
  object :pageview_result do
    field :url, non_null(:string)
    field :view_count, non_null(:integer)
    field :unique_visitors, non_null(:integer)
    field :timestamp, :date_time
    field :referrer, :string
    field :country, :string
    field :device, :device_type
  end

  # Queries
  query do
    @desc "Get pageview data"
    field :pageviews, list_of(:pageview_result) do
      arg :site_id, non_null(:id)
      arg :filter, :pageview_filter_input
      arg :pagination, :pagination_input
      arg :aggregation, :aggregation_input

      resolve &Pageview.list_pageviews/3
    end

    @desc "Get custom events"
    field :events, list_of(:event_result) do
      arg :site_id, non_null(:id)
      arg :filter, :event_filter_input
      arg :pagination, :pagination_input
      arg :aggregation, :aggregation_input

      resolve &Event.list_events/3
    end

    @desc "Get custom metrics"
    field :metrics, list_of(:custom_metric) do
      arg :site_id, non_null(:id)
      arg :filter, :metric_filter_input
      arg :time_series, :boolean
      arg :interval, :time_interval

      resolve &Metric.list_metrics/3
    end
  end

  # Scalar implementations
  defp parse_datetime(%Absinthe.Blueprint.Input.String{value: value}) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _} -> {:ok, datetime}
      _ -> :error
    end
  end

  defp parse_datetime(_) do
    :error
  end

  defp format_datetime(datetime) do
    DateTime.to_iso8601(datetime)
  end

  defp parse_json(%Absinthe.Blueprint.Input.String{value: value}) do
    case Jason.decode(value) do
      {:ok, json} -> {:ok, json}
      _ -> :error
    end
  end

  defp parse_json(%Absinthe.Blueprint.Input.Object{fields: fields}) do
    result =
      fields
      |> Enum.map(fn %{name: name, value: value} ->
        {name, value}
      end)
      |> Map.new()

    {:ok, result}
  end

  defp parse_json(_) do
    :error
  end

  defp encode_json(json) do
    Jason.encode!(json)
  end
end
