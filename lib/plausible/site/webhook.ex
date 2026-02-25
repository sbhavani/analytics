defmodule Plausible.Site.Webhook do
  @moduledoc """
  Schema for webhook configuration at site level.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "webhooks" do
    field :url, :string
    field :secret, :string
    field :enabled, :boolean, default: true

    belongs_to :site, Plausible.Site
    has_many :triggers, Plausible.Site.WebhookTrigger, foreign_key: :webhook_id
    has_many :deliveries, Plausible.Site.WebhookDelivery, foreign_key: :webhook_id

    timestamps()
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(webhook, attrs) do
    webhook
      |> cast(attrs, [:site_id, :url, :secret, :enabled])
      |> validate_required([:site_id, :url, :secret])
      |> validate_url(:url)
      |> validate_length(:secret, min: 32)
      |> validate_length(:url, max: 2048)
  end

  defp validate_url(changeset, field) do
    validate_change(changeset, field, fn _, url ->
      case URI.parse(url) do
        %URI{scheme: "https", host: host} when host not in ["", nil] ->
          []

        %URI{scheme: "http", host: host} when host not in ["", nil] ->
          [{field, "must use HTTPS, not HTTP"}]

        _ ->
          [{field, "must be a valid URL"}]
      end
    end)
  end

  @spec create_changeset(t(), map()) :: Ecto.Changeset.t()
  def create_changeset(webhook, attrs) do
    webhook
      |> changeset(attrs)
      |> put_change(:secret, generate_secret())
  end

  defp generate_secret do
    :crypto.strong_rand_bytes(32) |> Base.encode64()
  end
end
