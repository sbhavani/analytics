defmodule PlausibleWeb.GraphQL.Resolvers.Metrics do
  @moduledoc """
  GraphQL resolvers for custom metrics queries
  """

  alias Plausible.Stats
  alias Plausible.CustomMetrics
  alias PlausibleWeb.GraphQL.Error

  def custom_metrics(_parent, %{site_id: _site_id}, %{context: %{site: site}}) do
    case CustomMetrics.for_site(site) do
      metrics when is_list(metrics) ->
        formatted = Enum.map(metrics, fn metric ->
          %{
            name: metric.name,
            value: calculate_metric_value(site, metric)
          }
        end)
        {:ok, formatted}

      _ ->
        {:ok, []}
    end
  end

  def custom_metrics(_parent, _args, _context) do
    Error.unauthorized()
  end

  defp calculate_metric_value(site, metric) do
    # Custom metrics are calculated based on their formula
    # This is a placeholder - actual implementation would use the metric's formula
    query = %{
      date_range: %{
        start: Date.utc_today() |> Date.add(-30),
        end: Date.utc_today()
      },
      filters: %{},
      metrics: [metric.name]
    }

    case Stats.aggregate(site, query, [metric.name]) do
      {:ok, results} ->
        Map.get(results, String.to_atom(metric.name), 0.0)

      _ ->
        0.0
    end
  end
end
