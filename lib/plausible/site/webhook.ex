defmodule Plausible.Site.Webhook do
  @moduledoc """
  Schema for webhook configuration.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "webhooks" do
    field :url, :string
    field :secret, :string
    field :name, :string
    field :enabled, :boolean, default: true

    belongs_to :site, Plausible.Site
    has_many :triggers, Plausible.Site.WebhookTrigger, foreign_key: :webhook_id
    has_many :deliveries, Plausible.Site.WebhookDelivery, foreign_key: :webhook_id

    timestamps()
  end

  def changeset(webhook, attrs) do
    webhook
    |> cast(attrs, [:site_id, :url, :secret, :name, :enabled])
    |> validate_required([:site_id, :url, :secret, :name])
    |> validate_url(:url)
    |> validate_length(:secret, min: 16, message: "must be at least 16 characters")
    |> validate_length(:name, min: 1, max: 255)
  end

  def toggle_enabled(webhook) do
    webhook |> change(enabled: !webhook.enabled)
  end

  defp validate_url(changeset, field) do
    validate_change(changeset, field, fn _, url ->
      case URI.parse(url) do
        %URI{scheme: "https", host: host} when host != nil ->
          []

        %URI{scheme: s} when s != "https" ->
          [url: "must use HTTPS"]

        _ ->
          [url: "must be a valid URL"]
      end
    end)
  end
end
