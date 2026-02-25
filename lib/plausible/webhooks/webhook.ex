defmodule Plausible.Webhooks.Webhook do
  @moduledoc """
  Schema for webhook configurations.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "webhooks" do
    field :url, :string
    field :secret, Plausible.Auth.TOTP.EncryptedBinary
    field :name, :string
    field :active, :boolean, default: true

    belongs_to :site, Plausible.Site
    has_many :triggers, Plausible.Webhooks.Trigger, on_delete: :delete_all
    has_many :deliveries, Plausible.Webhooks.Delivery, on_delete: :delete_all

    timestamps()
  end

  def create_changeset(webhook, attrs) do
    webhook
    |> cast(attrs, [:site_id, :url, :secret, :name, :active])
    |> validate_required([:site_id, :url, :name])
    |> validate_url(:url)
    |> validate_length(:url, max: 2048)
    |> validate_length(:name, max: 255)
    |> validate_secret()
  end

  def update_changeset(webhook, attrs) do
    webhook
    |> cast(attrs, [:url, :secret, :name, :active])
    |> validate_url(:url)
    |> validate_length(:url, max: 2048)
    |> validate_length(:name, max: 255)
    |> validate_secret()
  end

  defp validate_url(changeset, field) do
    validate_change(changeset, field, fn _, url ->
      case URI.parse(url) do
        %URI{scheme: "https", host: host} when host != nil ->
          []

        %URI{scheme: "http"} ->
          [url: "must use HTTPS protocol"]

        _ ->
          [url: "must be a valid HTTPS URL"]
      end
    end)
  end

  defp validate_secret(changeset) do
    validate_change(changeset, :secret, fn _, secret ->
      if is_nil(secret) || String.length(secret) >= 16 do
        []
      else
        [secret: "must be at least 16 characters"]
      end
    end)
  end
end
