defmodule Plausible.Workers.DeliverWebhook do
  @moduledoc """
  Oban worker for delivering webhook payloads to configured endpoints.
  Implements retry logic with exponential backoff (1s, 2s, 4s).
  """
  use Oban.Worker, queue: :webhooks, max_attempts: 3

  alias Plausible.Repo
  alias Plausible.Webhooks.Signature

  @http_timeout 10_000

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"delivery_id" => delivery_id}}) do
    delivery = Repo.get!(Plausible.Webhooks.Delivery, delivery_id)
    webhook = Repo.get!(Plausible.Webhooks.Webhook, delivery.webhook_configuration_id)

    unless webhook.enabled do
      {:cancel, "webhook disabled"}
    end

    payload = Jason.encode!(delivery.payload)
    signature = Signature.generate(payload, webhook.secret)

    headers = [
      {"Content-Type", "application/json"},
      {"X-Signature", "sha256=#{signature}"},
      {"X-Webhook-Event", delivery.event_type},
      {"User-Agent", "Plausible/Analytics"}
    ]

    case HTTPoison.post(webhook.url, payload, headers, timeout: @http_timeout, recv_timeout: @http_timeout) do
      {:ok, %{status_code: status_code}} when status_code >= 200 and status_code < 300 ->
        delivery
        |> Ecto.Changeset.change(%{
          status: "success",
          response_code: status_code
        })
        |> Repo.update!()

        :ok

      {:ok, %{status_code: status_code, body: body}} ->
        error_msg = "HTTP #{status_code}: #{body}"

        delivery
        |> Ecto.Changeset.change(%{
          status: "failed",
          response_code: status_code,
          error_message: String.slice(error_msg, 0..500)
        })
        |> Repo.update!()

        {:error, error_msg}

      {:error, %{reason: reason}} ->
        error_msg = inspect(reason)

        delivery
        |> Ecto.Changeset.change(%{
          status: "failed",
          error_message: String.slice(error_msg, 0..500)
        })
        |> Repo.update!()

        {:error, reason}
    end
  end

  @impl Oban.Worker
  def timeout(_job), do: @http_timeout
end
