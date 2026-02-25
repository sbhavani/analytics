defmodule Plausible.Stats.Funnel do
  @moduledoc """
  Module responsible for funnel evaluation, i.e. building and executing
  ClickHouse funnel query based on `Plausible.Funnel` definition.
  """

  @funnel_window_duration 86_400

  alias Plausible.Funnel
  alias Plausible.Funnels

  import Ecto.Query
  import Plausible.Stats.SQL.Fragments

  alias Plausible.ClickhouseRepo
  alias Plausible.Stats.Base
  alias Plausible.Stats.Query

  @spec funnel(Plausible.Site.t(), Plausible.Stats.Query.t(), Funnel.t() | pos_integer()) ::
          {:ok, map()} | {:error, :funnel_not_found}
  def funnel(site, query, funnel_id) when is_integer(funnel_id) do
    case Funnels.get(site.id, funnel_id) do
      %Funnel{} = funnel ->
        funnel(site, query, funnel)

      nil ->
        {:error, :funnel_not_found}
    end
  end

  def funnel(_site, query, %Funnel{} = funnel) do
    funnel_data =
      query
      |> Base.base_event_query()
      |> query_funnel(funnel)

    # Funnel definition steps are 1-indexed, if there's index 0 in the resulting query,
    # it signifies the number of visitors that haven't entered the funnel.
    not_entering_visitors =
      case funnel_data do
        [{0, count} | _] -> count
        _ -> 0
      end

    all_visitors = Enum.reduce(funnel_data, 0, fn {_, n}, acc -> acc + n end)
    steps = backfill_steps(funnel_data, funnel)

    visitors_at_first_step = List.first(steps).visitors

    {:ok,
     %{
       name: funnel.name,
       steps: steps,
       all_visitors: all_visitors,
       entering_visitors: visitors_at_first_step,
       entering_visitors_percentage: percentage(visitors_at_first_step, all_visitors),
       never_entering_visitors: all_visitors - visitors_at_first_step,
       never_entering_visitors_percentage: percentage(not_entering_visitors, all_visitors)
     }}
  end

  @spec funnel_comparison(Plausible.Site.t(), Plausible.Stats.Query.t(), Plausible.Stats.Query.t(), Funnel.t() | pos_integer()) ::
          {:ok, map()} | {:error, :funnel_not_found}
  def funnel_comparison(site, query_a, query_b, funnel_id) when is_integer(funnel_id) do
    case Funnels.get(site.id, funnel_id) do
      %Funnel{} = funnel ->
        funnel_comparison(site, query_a, query_b, funnel)

      nil ->
        {:error, :funnel_not_found}
    end
  end

  def funnel_comparison(_site, query_a, query_b, %Funnel{} = funnel) do
    # Query both periods
    funnel_data_a =
      query_a
      |> Base.base_event_query()
      |> query_funnel(funnel)

    funnel_data_b =
      query_b
      |> Base.base_event_query()
      |> query_funnel(funnel)

    steps_a = backfill_steps(funnel_data_a, funnel)
    steps_b = backfill_steps(funnel_data_b, funnel)

    # Extract date ranges
    date_range_a = Query.date_range(query_a)
    date_range_b = Query.date_range(query_b)

    # Format steps to match API contract
    formatted_steps_a = format_comparison_steps(steps_a)
    formatted_steps_b = format_comparison_steps(steps_b)

    # Build comparison data (skip first step as there's nothing to compare)
    comparison =
      Enum.zip(steps_a, steps_b)
      |> Enum.drop(1)
      |> Enum.map(fn {step_a, step_b} ->
        %{
          step: step_a.step_order || step_b.step_order,
          visitors_change: percentage_change(step_a.visitors, step_b.visitors),
          conversion_change: percentage_change(step_a.conversion_rate_step, step_b.conversion_rate_step)
        }
      end)

    {:ok,
     %{
       funnel_id: funnel.id,
       funnel_name: funnel.name,
       period_a: %{
         date_range: [Date.to_iso8601(date_range_a.first), Date.to_iso8601(date_range_a.last)],
         steps: formatted_steps_a
       },
       period_b: %{
         date_range: [Date.to_iso8601(date_range_b.first), Date.to_iso8601(date_range_b.last)],
         steps: formatted_steps_b
       },
       comparison: comparison
     }}
  end

  defp format_comparison_steps(steps) do
    Enum.map(steps, fn step ->
      base = %{
        step: step.step_order,
        visitors: step.visitors,
        name: step.label
      }

      # Add conversion_rate and dropoff_rate for steps after the first
      if step.step_order > 1 do
        Map.merge(base, %{
          conversion_rate: parse_percentage(step.conversion_rate_step),
          dropoff_rate: parse_percentage(step.dropoff_rate)
        })
      else
        base
      end
    end)
  end

  defp percentage_change(old_value, new_value) do
    old_value = parse_percentage(old_value)
    new_value = parse_percentage(new_value)

    if old_value == 0 || new_value == 0 do
      "0"
    else
      change = ((new_value - old_value) / old_value) * 100
      Decimal.from_float(change)
      |> Decimal.round(2)
      |> Decimal.to_string()
    end
  end

  defp parse_percentage(value) when is_binary(value) do
    case Float.parse(value) do
      {float, _} -> float
      :error -> 0.0
    end
  end

  defp parse_percentage(value), do: value

  defp query_funnel(query, funnel_definition) do
    q_events =
      from(e in query,
        select: %{user_id: e.user_id, _sample_factor: fragment("any(_sample_factor)")},
        where: e.site_id == ^funnel_definition.site_id,
        group_by: e.user_id,
        order_by: [desc: fragment("step")]
      )
      |> select_funnel(funnel_definition)

    query =
      from(f in subquery(q_events),
        select: {f.step, total()},
        group_by: f.step
      )

    ClickhouseRepo.all(query)
  end

  defp select_funnel(db_query, funnel_definition) do
    window_funnel_steps =
      Enum.reduce(funnel_definition.steps, nil, fn step, acc ->
        step_condition = step_condition(step)

        if acc do
          dynamic([q], fragment("?, ?", ^acc, ^step_condition))
        else
          dynamic([q], fragment("?", ^step_condition))
        end
      end)

    dynamic_window_funnel =
      dynamic(
        [q],
        fragment("windowFunnel(?)(timestamp, ?)", @funnel_window_duration, ^window_funnel_steps)
      )

    from(q in db_query,
      select_merge:
        ^%{
          step: dynamic_window_funnel
        }
    )
  end

  defp step_condition(%{goal: nil, event_name: nil}) do
    raise ArgumentError, "Funnel step must have either a goal or event_name"
  end

  defp step_condition(%{goal: goal}) when not is_nil(goal) do
    Plausible.Stats.Goals.goal_condition(goal)
  end

  defp step_condition(%{event_name: event_name}) when not is_nil(event_name) do
    dynamic([q], q.name == ^event_name)
  end

  defp backfill_steps(funnel_result, funnel) do
    # Directly from ClickHouse we only get {step_idx(), visitor_count()} tuples.
    # but no totals including previous steps are aggregated.
    # Hence we need to perform the appropriate backfill
    # and also calculate dropoff and conversion rate for each step.
    # In case ClickHouse returns 0-index funnel result, we're going to ignore it
    # anyway, since we fold over steps as per definition, that are always
    # indexed starting from 1.
    funnel_result = Enum.into(funnel_result, %{})
    max_step = Enum.max_by(funnel.steps, & &1.step_order).step_order

    funnel
    |> Map.fetch!(:steps)
    |> Enum.reduce({nil, nil, []}, fn step, {total_visitors, visitors_at_previous, acc} ->
      # first step contains the total number of all visitors qualifying for the funnel,
      # with each subsequent step needing to accumulate sum of the previous one(s)
      visitors_at_step =
        step.step_order..max_step
        |> Enum.map(&Map.get(funnel_result, &1, 0))
        |> Enum.sum()

      # accumulate current_visitors for the next iteration
      current_visitors = visitors_at_step

      # First step contains the total number of visitors that we base percentage dropoff on
      total_visitors =
        total_visitors ||
          current_visitors

      # Dropoff is 0 for the first step, otherwise we subtract current from previous
      dropoff = if visitors_at_previous, do: visitors_at_previous - current_visitors, else: 0

      dropoff_percentage = percentage(dropoff, visitors_at_previous)
      conversion_rate = percentage(current_visitors, total_visitors)
      conversion_rate_step = percentage(current_visitors, visitors_at_previous)

      step = %{
        step_order: step.step_order,
        dropoff: dropoff,
        dropoff_rate: dropoff_percentage,
        conversion_rate: conversion_rate,
        conversion_rate_step: conversion_rate_step,
        visitors: visitors_at_step,
        label: step_label(step)
      }

      {total_visitors, current_visitors, [step | acc]}
    end)
    |> elem(2)
    |> Enum.reverse()
  end

  defp step_label(%{goal: nil, event_name: event_name}) when not is_nil(event_name) do
    event_name
  end

  defp step_label(%{goal: goal}) when not is_nil(goal) do
    to_string(goal)
  end

  defp percentage(x, y) when x in [0, nil] or y in [0, nil] do
    "0"
  end

  defp percentage(x, y) do
    result =
      x
      |> Decimal.div(y)
      |> Decimal.mult(100)
      |> Decimal.round(2)
      |> Decimal.to_string()

    case result do
      <<compact::binary-size(1), ".00">> -> compact
      <<compact::binary-size(2), ".00">> -> compact
      <<compact::binary-size(3), ".00">> -> compact
      decimal -> decimal
    end
  end
end
