defmodule Plausible.Site.Webhook do
  @moduledoc """
  Schema for webhook configuration
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  schema "webhooks" do
    field :name, :string
    field :url, :string
    field :secret, :string
    field :enabled, :boolean, default: true

    belongs_to :site, Plausible.Site
    has_many :triggers, Plausible.Site.WebhookTrigger
    has_many :deliveries, Plausible.Site.WebhookDelivery

    timestamps()
  end

  def changeset(webhook, attrs) do
    webhook
    |> cast(attrs, [:site_id, :name, :url, :secret, :enabled])
    |> validate_required([:site_id, :name, :url, :secret])
    |> validate_length(:name, max: 255)
    |> validate_length(:url, max: 2048)
    |> validate_length(:secret, min: 16, max: 255)
    |> validate_url_format(:url)
    |> validate_https_url(:url)
  end

  defp validate_url_format(changeset, field) do
    validate_format(changeset, field, ~r/^https?:\/\/.+/,
      message: "must be a valid URL"
    )
  end

  defp validate_https_url(changeset, field) do
    case get_change(changeset, field) do
      nil ->
        changeset

      url ->
        if String.starts_with?(url, "https://") do
          changeset
        else
          add_error(changeset, field, "must use HTTPS for production deployments")
        end
    end
  end
end
