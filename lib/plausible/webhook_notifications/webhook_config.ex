defmodule Plausible.WebhookNotifications.WebhookConfig do
  @moduledoc """
  Schema for webhook configuration
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  @type t() :: %__MODULE__{}

  schema "webhook_configs" do
    field :endpoint_url, :string
    field :secret, :string
    field :is_active, :boolean, default: true

    belongs_to :site, Plausible.Site
    has_many :event_triggers, Plausible.WebhookNotifications.EventTrigger
    has_many :delivery_logs, Plausible.WebhookNotifications.DeliveryLog

    timestamps()
  end

  def changeset(webhook_config, attrs) do
    webhook_config
    |> cast(attrs, [:site_id, :endpoint_url, :secret, :is_active])
    |> validate_required([:site_id, :endpoint_url, :secret])
    |> validate_format(:endpoint_url, ~r/^https:\/\/.+/, message: "must be a valid HTTPS URL")
    |> validate_length(:endpoint_url, max: 500)
    |> validate_length(:secret, min: 16, max: 128)
  end
end
