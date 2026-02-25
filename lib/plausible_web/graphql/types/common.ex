defmodule PlausibleWeb.GraphQL.Types.Common do
  @moduledoc """
  Common GraphQL types used across the schema.
  """

  use Absinthe.Schema.Notation

  @desc "Date range input for queries"
  input_object :date_range_input do
    field :from, non_null(:string), description: "Start date (ISO 8601)"
    field :to, non_null(:string), description: "End date (ISO 8601)"
  end

  @desc "Pagination input"
  input_object :pagination_input do
    field :first, :integer, description: "Number of items to return"
    field :after, :string, description: "Cursor for pagination"
    field :last, :integer, description: "Number of items to return (from end)"
    field :before, :string, description: "Cursor for pagination (from end)"
  end

  @desc "Sort input"
  input_object :sort_input do
    field :field, non_null(:string), description: "Field to sort by"
    field :order, :sort_order, description: "Sort order"
  end

  enum :sort_order do
    value :asc
    value :desc
  end

  enum :time_interval do
    value :minute
    value :hour
    value :day
    value :week
    value :month
  end

  @desc "Page information for cursor-based pagination"
  object :page_info do
    field :has_next_page, non_null(:boolean)
    field :has_previous_page, non_null(:boolean)
    field :start_cursor, :string
    field :end_cursor, :string
  end

  scalar :json do
    parse fn
      %{__struct__: Absinthe.Blueprint.Input.String} = input ->
        {:ok, input.value}
      %{__struct__: Absinthe.Blueprint.Input.Null} ->
        {:ok, nil}
      _ ->
        :error
    end

    serialize &to_string/1
  end

  scalar :datetime do
    parse fn
      %{__struct__: Absinthe.Blueprint.Input.String} = input ->
        case DateTime.from_iso8601(input.value) do
          {:ok, datetime} -> {:ok, datetime}
          _ -> :error
        end
      _ ->
        :error
    end

    serialize &DateTime.to_iso8601/1
  end
end
