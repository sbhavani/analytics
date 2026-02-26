defmodule Plausible.Graphqla.Types.Scalars.Date do
  @moduledoc """
  Date scalar type for GraphQL
  """
  use Absinthe.Schema.Notation

  scalar "Date" do
    parse(fn
      %Absinthe.Blueprint.Input.String{value: value} ->
        case Date.from_iso8601(value) do
          {:ok, date} -> {:ok, date}
          _ -> :error
        end

      _ ->
        :error
    end)

    serialize(fn
      %Date{} = date -> Date.to_iso8601(date)
      _ -> nil
    end)
  end
end

defmodule Plausible.Graphqla.Types.Scalars.DateTime do
  @moduledoc """
  DateTime scalar type for GraphQL
  """
  use Absinthe.Schema.Notation

  scalar "DateTime" do
    parse(fn
      %Absinthe.Blueprint.Input.String{value: value} ->
        case DateTime.from_iso8601(value) do
          {:ok, datetime, _} -> {:ok, datetime}
          _ -> :error
        end

      _ ->
        :error
    end)

    serialize(fn
      %DateTime{} = datetime -> DateTime.to_iso8601(datetime)
      _ -> nil
    end)
  end
end

defmodule Plausible.Graphqla.Types.Scalars.JSON do
  @moduledoc """
  JSON scalar type for GraphQL
  """
  use Absinthe.Schema.Notation

  scalar "JSON" do
    parse(fn
      %Absinthe.Blueprint.Input.String{value: value} ->
        case Jason.decode(value) do
          {:ok, json} -> {:ok, json}
          _ -> :error
        end

      %Absinthe.Blueprint.Input.Object{} ->
        :error

      _ ->
        :error
    end)

    serialize(fn json ->
      Jason.encode!(json)
    end)
  end
end
