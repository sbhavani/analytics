defmodule PlausibleWeb.GraphQL.Resolvers.Metrics do
  @moduledoc """
  Resolvers for custom metrics queries.
  """

  alias PlausibleWeb.GraphQL.Resolvers.Helpers

  require Logger

  @doc """
  Lists custom metrics for a site.
  """
  def list_custom_metrics(_parent, %{site_id: site_id} = args, _resolution) do
    start_time = System.monotonic_time(:millisecond)

    with {:ok, site} <- Helpers.get_site(site_id) do
      # Parse date range if provided
      date_range =
        case Helpers.parse_date_range(args[:date_range]) do
          {:ok, range} -> range
          _ -> nil
        end

      # Get custom metrics for the site
      # Custom metrics are stored in site settings
      metrics = get_custom_metrics(site, date_range)

      duration_ms = System.monotonic_time(:millisecond) - start_time
      Helpers.log_operation("custom_metrics", site_id, duration_ms)

      {:ok, metrics}
    else
      {:error, %{message: _} = error} ->
        {:error, error}
    end
  end

  defp get_custom_metrics(site, date_range) do
    # For now, return an empty list as custom metrics need to be defined
    # In a full implementation, this would query the site's custom metrics
    # from the database and compute their values

    # Placeholder: In production, query custom metrics from site settings
    # and compute their values based on ClickHouse data
    []
  end
end
