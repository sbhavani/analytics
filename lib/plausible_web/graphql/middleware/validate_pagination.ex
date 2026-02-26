defmodule PlausibleWeb.GraphQL.Middleware.ValidatePagination do
  @moduledoc """
  Middleware to validate pagination input bounds
  """
  use Plausible

  @min_limit 1
  @max_limit 1000
  @min_offset 0

  def call(resolution, _opts) do
    %{arguments: args} = resolution

    case validate_args(args) do
      :ok ->
        resolution

      {:error, error} ->
        resolution
        |> Absinthe.Resolution.put_error(%{
          message: error.message,
          code: error.code,
          locations: [{:line, 1, :column}],
          path: resolution.path
        })
    end
  end

  defp validate_args(args) do
    errors =
      []
      |> check_limit(args[:pagination][:limit])
      |> check_offset(args[:pagination][:offset])

    if errors == [] do
      :ok
    else
      {:error, hd(errors)}
    end
  end

  defp check_limit(acc, nil), do: acc
  defp check_limit(acc, limit) when limit < @min_limit do
    [%{message: "limit must be at least #{@min_limit}", code: "INVALID_LIMIT"} | acc]
  end
  defp check_limit(acc, limit) when limit > @max_limit do
    [%{message: "limit must be at most #{@max_limit}", code: "INVALID_LIMIT"} | acc]
  end
  defp check_limit(acc, _), do: acc

  defp check_offset(acc, nil), do: acc
  defp check_offset(acc, offset) when offset < @min_offset do
    [%{message: "offset must be at least #{@min_offset}", code: "INVALID_OFFSET"} | acc]
  end
  defp check_offset(acc, _), do: acc
end
