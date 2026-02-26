defmodule PlausibleWeb.Api.GraphQLController do
  @moduledoc """
  Controller for GraphQL API endpoint
  """

  use PlausibleWeb, :controller

  alias PlausibleWeb.GraphQL.Schema
  alias PlausibleWeb.GraphQL.Context
  alias PlausibleWeb.GraphQL.Error

  @request_id_header "x-request-id"

  def execute(conn, %{"query" => query}) do
    variables = Map.get(conn.params, "variables", %{})
    operation_name = Map.get(conn.params, "operationName")

    request_id = get_req_header(conn, @request_id_header) |> List.first() || generate_request_id()

    context = Context.build_context(conn)

    result = Absinthe.run(query, Schema,
      variables: variables,
      context: context,
      operation_name: operation_name
    )

    case result do
      {:ok, %{data: data, errors: []}} ->
        json(conn, %{data: data, request_id: request_id})

      {:ok, %{data: data, errors: errors}} when is_list(errors) ->
        # Check if there are only validation errors (non-critical)
        has_critical_errors = Enum.any?(errors, fn e ->
          code = Map.get(e, :code) || Map.get(e.extensions || %{}, :code)
          code in [:unauthorized, :forbidden, :internal_error, :rate_limit_exceeded]
        end)

        formatted_errors = format_errors(errors)

        response = %{data: data, errors: formatted_errors, request_id: request_id}

        if has_critical_errors do
          conn
          |> put_status(:internal_server_error)
          |> json(response)
        else
          json(conn, response)
        end

      {:error, %{errors: errors}} ->
        formatted_errors = format_errors(errors)
        request_id = get_req_header(conn, @request_id_header) |> List.first() || generate_request_id()

        conn
        |> put_status(:bad_request)
        |> json(%{
          errors: formatted_errors,
          request_id: request_id,
          message: "GraphQL execution failed"
        })

      {:error, reason} when is_atom(reason) ->
        formatted_error = Error.format_error(reason)

        conn
        |> put_status(map_error_status(reason))
        |> json(%{
          errors: [formatted_error],
          request_id: request_id
        })

      {:error, error} ->
        formatted_error = Error.format_error(error)

        conn
        |> put_status(:internal_server_error)
        |> json(%{
          errors: [formatted_error],
          request_id: request_id
        })
    end
  end

  def execute(conn, _params) do
    request_id = generate_request_id()

    conn
    |> put_status(:bad_request)
    |> json(%{
      errors: [
        %{
          message: "Missing required 'query' parameter",
          code: :bad_request,
          details: "A valid GraphQL query string is required"
        }
      ],
      request_id: request_id
    })
  end

  # Handle malformed JSON body
  def execute(conn, nil) do
    execute(conn, %{})
  end

  defp format_errors(errors) when is_list(errors) do
    Enum.map(errors, fn error ->
      cond
        is_binary(error) ->
          %{message: error, code: :validation_error}

        is_map(error) ->
          %{
            message: Map.get(error, :message) || "Unknown error",
            code: Map.get(error, :code) || Map.get(error, :code, :validation_error),
            field: Map.get(error, :field),
            details: Map.get(error, :details),
            path: format_path(error)
          }

        true ->
          %{message: "Unknown error", code: :validation_error}
      end
    end)
  end

  defp format_error(%{message: message, code: code} = error) do
    %{
      message: message,
      code: code,
      field: Map.get(error, :field),
      details: Map.get(error, :details)
    }
  end

  defp format_path(%{locations: locations}) when is_list(locations) do
    Enum.map(locations, fn loc ->
      "#{loc.line}:#{loc.column}"
    end)
  end

  defp format_path(_), do: nil

  defp map_error_status(:unauthorized), do: :unauthorized
  defp map_error_status(:forbidden), do: :forbidden
  defp map_error_status(:not_found), do: :not_found
  defp map_error_status(:validation_error), do: :bad_request
  defp map_error_status(:invalid_date_range), do: :bad_request
  defp map_error_status(:invalid_filter), do: :bad_request
  defp map_error_status(:rate_limit_exceeded), do: :too_many_requests
  defp map_error_status(:internal_error), do: :internal_server_error
  defp map_error_status(_), do: :internal_server_error

  defp generate_request_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end
end
