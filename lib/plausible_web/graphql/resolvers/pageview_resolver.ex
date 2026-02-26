defmodule PlausibleWeb.GraphQL.Resolvers.PageviewResolver do
  @moduledoc """
  Resolver for pageview GraphQL queries.
  """

  alias Plausible.Stats
  alias Plausible.Sites
  alias PlausibleWeb.GraphQL.Helpers.{FilterParser, AggregationHelper, CursorHelper}

  # Connection and Result structs for union type resolution
  defstruct [:edges, :page_info, :total_count]
  defmodule AggregateResult do
    defstruct [:aggregation_type, :value, :dimension]
  end

  @type t :: %__MODULE__{
          edges: list(),
          page_info: map(),
          total_count: integer()
        }

  @doc """
  Query pageview data for a site.
  """
  def pageviews(_parent, %{site_id: site_id} = args, %{context: %{current_user: user}}) do
    with {:ok, site} <- authorize_site(user, site_id),
         {:ok, query} <- build_query(site, args),
         {:ok, filters} <- FilterParser.parse_filters(args[:filters]),
         :ok <- validate_filters(filters),
         {:ok, pagination} <- parse_pagination(args[:pagination]) do
      # Check if aggregation is requested
      if AggregationHelper.should_aggregate?(args[:aggregation]) do
        query_aggregated_data(site, query, filters, args[:aggregation])
      else
        query_pageview_data(site, query, filters, pagination)
      end
    else
      {:error, %{message: message, extensions: extensions}} ->
        {:error, message: message, extensions: extensions}

      {:error, message} when is_binary(message) ->
        {:error, message: message}

      error ->
        {:error, message: "Failed to query pageviews: #{inspect(error)}"}
    end
  end

  def pageviews(_parent, _args, _context) do
    {:error, message: "Authentication required", extensions: %{code: "UNAUTHORIZED"}}
  end

  defp authorize_site(user, site_id) do
    case Sites.get_by_id(site_id, user) do
      nil ->
        {:error, %{message: "Site not found", extensions: %{code: "NOT_FOUND", field: "siteId"}}}

      site ->
        {:ok, site}
    end
  end

  defp build_query(site, args) do
    date_range = args[:date_range]

    query =
      case date_range do
        %{start_date: start_date, end_date: end_date} ->
          Plausible.Stats.Query.from_date_range(site, start_date, end_date)

        _ ->
          # Default to last 7 days
          Plausible.Stats.Query.default(site)
      end

    {:ok, query}
  end

  defp parse_pagination(nil) do
    {:ok, %{limit: 50, cursor: nil}}
  end

  defp parse_pagination(%{first: first, after: after}) do
    {:ok, %{limit: first || 50, cursor: after}}
  end

  defp parse_pagination(%{last: last, before: before}) do
    {:ok, %{limit: last || 50, cursor: before}}
  end

  defp parse_pagination(_) do
    {:ok, %{limit: 50, cursor: nil}}
  end

  defp validate_filters(_filters), do: :ok

  defp query_pageview_data(site, query, filters, pagination) do
    # Query for pageview data using breakdown
    result =
      Stats.breakdown(
        site,
        query,
        [:pathname, :visitors],
        %{
          filters: filters,
          limit: pagination.limit + 1
        }
      )

    case result do
      {:ok, breakdown_data} ->
        items = Enum.map(breakdown_data, &format_pageview/1)
        total_count = length(items)

        page_info =
          CursorHelper.calculate_page_info(items, pagination.limit, pagination.cursor)

        edges =
          Enum.map(items |> Enum.take(pagination.limit), fn item ->
            %{
              node: item,
              cursor: CursorHelper.encode_cursor(item)
            }
          })

        {:ok,
         %__MODULE__{
           edges: edges,
           page_info: page_info,
           total_count: total_count
         }}

      {:error, reason} ->
        {:error, message: "Failed to query pageviews: #{inspect(reason)}"}
    end
  end

  defp query_aggregated_data(site, query, filters, aggregation_input) do
    with {:ok, agg_config} <- AggregationHelper.parse_aggregation(aggregation_input) do
      result =
        Stats.aggregate(
          site,
          query,
          agg_config.metrics,
          %{
            filters: filters,
            aggregation: agg_config.aggregation
          }
        )

      case result do
        {:ok, data} ->
          dimension = aggregation_input[:dimension]
          AggregationHelper.format_aggregate_result(data, aggregation_input.type, dimension)

        {:error, reason} ->
          {:error, message: "Failed to aggregate pageviews: #{inspect(reason)}"}
      end
    end
  end

  defp format_pageview(%{pathname: pathname, visitors: visitors}) do
    %{
      id: pathname,
      url: "https://example.com#{pathname}",
      pathname: pathname,
      timestamp: DateTime.utc_now(),
      visitor_id: "anonymous",
      referrer: nil,
      session_id: nil,
      country: nil,
      device: "desktop",
      browser: "Chrome",
      operating_system: "Linux"
    }
  end
end
