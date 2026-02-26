defmodule PlausibleWeb.GraphQL.Resolvers.FilterParser do
  @moduledoc """
  Parses GraphQL filter inputs into the format expected by the Stats module
  """

  @doc """
  Parses a list of GraphQL filter inputs into a filter map
  """
  def parse_filters(nil), do: %{}

  def parse_filters(filters) when is_list(filters) do
    Enum.reduce(filters, %{}, fn filter, acc ->
      Map.merge(acc, parse_single_filter(filter))
    end)
  end

  defp parse_single_filter(%{
    "country" => country
  }) when is_binary(country) do
    %{"country" => country}
  end

  defp parse_single_filter(%{
    "region" => region
  }) when is_binary(region) do
    %{"region" => region}
  end

  defp parse_single_filter(%{
    "city" => city
  }) when is_binary(city) do
    %{"city" => city}
  end

  defp parse_single_filter(%{
    "referrer" => referrer
  }) when is_binary(referrer) do
    %{"referrer" => referrer}
  end

  defp parse_single_filter(%{
    "utm_medium" => medium
  }) when is_binary(medium) do
    %{"utm_medium" => medium}
  end

  defp parse_single_filter(%{
    "utm_source" => source
  }) when is_binary(source) do
    %{"utm_source" => source}
  end

  defp parse_single_filter(%{
    "utm_campaign" => campaign
  }) when is_binary(campaign) do
    %{"utm_campaign" => campaign}
  end

  defp parse_single_filter(%{
    "device" => device
  }) when is_binary(device) do
    %{"device" => device}
  end

  defp parse_single_filter(%{
    "browser" => browser
  }) when is_binary(browser) do
    %{"browser" => browser}
  end

  defp parse_single_filter(%{
    "operating_system" => os
  }) when is_binary(os) do
    %{"operating_system" => os}
  end

  defp parse_single_filter(%{
    "pathname" => pathname
  }) when is_binary(pathname) do
    %{"pathname" => pathname}
  end

  defp parse_single_filter(_), do: %{}

  @doc """
  Parses filter input from atoms (as received from GraphQL)
  """
  def parse_filters_atoms(nil), do: %{}

  def parse_filters_atoms(filters) when is_list(filters) do
    Enum.reduce(filters, %{}, fn filter, acc ->
      Map.merge(acc, parse_single_filter_atoms(filter))
    end)
  end

  defp parse_single_filter_atoms(%{country: country}) when is_binary(country) do
    %{"country" => country}
  end

  defp parse_single_filter_atoms(%{region: region}) when is_binary(region) do
    %{"region" => region}
  end

  defp parse_single_filter_atoms(%{city: city}) when is_binary(city) do
    %{"city" => city}
  end

  defp parse_single_filter_atoms(%{referrer: referrer}) when is_binary(referrer) do
    %{"referrer" => referrer}
  end

  defp parse_single_filter_atoms(%{utm_medium: medium}) when is_binary(medium) do
    %{"utm_medium" => medium}
  end

  defp parse_single_filter_atoms(%{utm_source: source}) when is_binary(source) do
    %{"utm_source" => source}
  end

  defp parse_single_filter_atoms(%{utm_campaign: campaign}) when is_binary(campaign) do
    %{"utm_campaign" => campaign}
  end

  defp parse_single_filter_atoms(%{device: device}) when is_binary(device) do
    %{"device" => device}
  end

  defp parse_single_filter_atoms(%{browser: browser}) when is_binary(browser) do
    %{"browser" => browser}
  end

  defp parse_single_filter_atoms(%{operating_system: os}) when is_binary(os) do
    %{"operating_system" => os}
  end

  defp parse_single_filter_atoms(%{pathname: pathname}) when is_binary(pathname) do
    %{"pathname" => pathname}
  end

  defp parse_single_filter_atoms(_), do: %{}
end
