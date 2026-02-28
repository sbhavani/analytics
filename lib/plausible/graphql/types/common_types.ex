defmodule Plausible.GraphQL.Types.CommonTypes do
  @moduledoc """
  Common GraphQL types used across the analytics API.
  """

  use Absinthe.Schema.Notation

  @max_date_range_days 365

  enum :aggregation_type do
    value :count, description: "Count of records"
    value :sum, description: "Sum of values"
    value :avg, description: "Average of values"
    value :min, description: "Minimum value"
    value :max, description: "Maximum value"
  end

  input_object :date_range_input do
    field :from, non_null(:date), description: "Start of date range (inclusive)"
    field :to, non_null(:date), description: "End of date range (inclusive)"
  end

  input_object :aggregation_input do
    field :type, non_null(:aggregation_type), description: "Type of aggregation to perform"
    field :field, :string, description: "Field to aggregate (for SUM, AVG, MIN, MAX)"
  end

  @doc """
  Validates that the date range does not exceed the maximum allowed period.
  """
  def validate_date_range(%{from: from, to: to}) do
    days_diff = Date.diff(to, from)

    if days_diff > @max_date_range_days do
      {:error, "Date range cannot exceed #{@max_date_range_days} days"}
    else
      :ok
    end
  end

  def validate_date_range(_), do: :ok
end
