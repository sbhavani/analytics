defmodule Plausible.Webhooks do
  @moduledoc """
  Context module for webhook CRUD operations.
  """
  use Plausible
  use Plausible.Repo

  import Ecto.Query

  alias Plausible.Site.Webhook
  alias Plausible.Site.WebhookDelivery

  @max_webhooks_per_site 10

  @spec list(Plausible.Site.t()) :: [Webhook.t()]
  def list(%Plausible.Site{id: site_id}) do
    from(w in Webhook,
      where: w.site_id == ^site_id,
      order_by: [desc: :inserted_at]
    )
    |> Repo.all()
  end

  @spec get(Plausible.Site.t(), String.t() | integer()) :: Webhook.t() | nil
  def get(%Plausible.Site{id: site_id}, webhook_id) when is_binary(webhook_id) do
    case Ecto.UUID.cast(webhook_id) do
      {:ok, uuid} -> get(site_id, uuid)
      :error -> nil
    end
  end

  def get(%Plausible.Site{id: site_id}, webhook_id) when is_integer(webhook_id) do
    from(w in Webhook,
      where: w.site_id == ^site_id,
      where: w.id == ^webhook_id,
      preload: [:site]
    )
    |> Repo.one()
  end

  @spec get!(Plausible.Site.t(), String.t() | integer()) :: Webhook.t()
  def get!(site, webhook_id) do
    get(site, webhook_id) || raise "Webhook not found"
  end

  @spec create(Plausible.Site.t(), map()) :: {:ok, Webhook.t()} | {:error, Ecto.Changeset.t()}
  def create(%Plausible.Site{} = site, attrs) do
    if at_webhook_limit?(site) do
      {:error, :at_limit}
    else
      site
      |> Ecto.build_assoc(:webhooks)
      |> Webhook.changeset(attrs)
      |> Repo.insert()
    end
  end

  @spec update(Webhook.t(), map()) :: {:ok, Webhook.t()} | {:error, Ecto.Changeset.t()}
  def update(%Webhook{} = webhook, attrs) do
    webhook
    |> Webhook.changeset(attrs)
    |> Repo.update()
  end

  @spec delete(Webhook.t()) :: {:ok, Webhook.t()} | {:error, Ecto.Changeset.t()}
  def delete(%Webhook{} = webhook) do
    Repo.delete(webhook)
  end

  @spec enable(Webhook.t()) :: {:ok, Webhook.t()} | {:error, Ecto.Changeset.t()}
  def enable(%Webhook{} = webhook) do
    webhook
    |> change(enabled: true)
    |> Repo.update()
  end

  @spec disable(Webhook.t()) :: {:ok, Webhook.t()} | {:error, Ecto.Changeset.t()}
  def disable(%Webhook{} = webhook) do
    webhook
    |> change(enabled: false)
    |> Repo.update()
  end

  @spec enabled_webhooks(Plausible.Site.t()) :: [Webhook.t()]
  def enabled_webhooks(%Plausible.Site{id: site_id}) do
    from(w in Webhook,
      where: w.site_id == ^site_id,
      where: w.enabled == true
    )
    |> Repo.all()
  end

  @spec webhooks_for_event(Plausible.Site.t(), String.t()) :: [Webhook.t()]
  def webhooks_for_event(%Plausible.Site{} = site, event_type) do
    site
    |> enabled_webhooks()
    |> Enum.filter(fn webhook -> event_type in webhook.events end)
  end

  @spec create_delivery(Webhook.t(), map()) :: WebhookDelivery.t()
  def create_delivery(%Webhook{} = webhook, attrs) do
    webhook
    |> Ecto.build_assoc(:deliveries)
    |> WebhookDelivery.changeset(attrs)
    |> Repo.insert!()
  end

  @spec list_deliveries(Webhook.t(), keyword()) :: [WebhookDelivery.t()]
  def list_deliveries(%Webhook{} = webhook, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    from(d in WebhookDelivery,
      where: d.webhook_id == ^webhook.id,
      order_by: [desc: :inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  @spec at_webhook_limit?(Plausible.Site.t()) :: boolean()
  def at_webhook_limit?(%Plausible.Site{id: site_id}) do
    limit = Application.get_env(:plausible, :max_webhooks_per_site, @max_webhooks_per_site)

    from(w in Webhook,
      where: w.site_id == ^site_id,
      select: count(w.id)
    )
    |> Repo.one()
    |> then(&(&1 >= limit))
  end

  @spec increment_failure_count(Webhook.t()) :: {:ok, Webhook.t()} | :disabled
  def increment_failure_count(%Webhook{} = webhook) do
    current_failures = webhook.failure_threshold - 1

    if current_failures <= 0 do
      disable(webhook)
      :disabled
    else
      {:ok, webhook}
    end
  end

  @doc """
  Sends a test webhook to verify the endpoint is reachable.
  """
  @spec test_webhook(Webhook.t()) :: {:ok, map()} | {:error, String.t()}
  def test_webhook(%Webhook{} = webhook) do
    payload = Plausible.Webhooks.PayloadBuilder.build_test(%{site: webhook.site})
    payload_json = Jason.encode!(payload)

    headers = [
      {"Content-Type", "application/json"},
      {"X-Webhook-Event", "test"},
      {"X-Webhook-Site-Id", webhook.site.domain}
    ]
    |> add_signature_header(webhook.secret, payload_json)

    case HTTPoison.post(webhook.url, payload_json, headers, timeout: 30_000, recv_timeout: 30_000) do
      {:ok, %{status_code: code, body: body}} when code in 200..299 ->
        {:ok, %{status_code: code, body: body}}

      {:ok, %{status_code: code, body: body}} ->
        {:error, "HTTP #{code}: #{body}"}

      {:error, %{reason: reason}} ->
        {:error, inspect(reason)}
    end
  end

  defp add_signature_header(headers, nil, _payload), do: headers
  defp add_signature_header(headers, "", _payload), do: headers

  defp add_signature_header(headers, secret, payload) do
    signature = :crypto.mac(:hmac, :sha256, secret, payload)
    signature_hex = Base.encode16(signature, case: :lower)
    [{"X-Webhook-Signature", "sha256=#{signature_hex}"} | headers]
  end
end
