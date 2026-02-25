defmodule Plausible.Site.Webhook do
  @moduledoc """
  Schema for webhook configuration per site.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @valid_event_types [:goal_completion, :visitor_spike, :custom_event, :error_condition]

  schema "webhooks" do
    field :url, :string
    field :secret, :string
    field :name, :string
    field :events, {:array, :string}
    field :enabled, :boolean, default: true
    field :failure_threshold, :integer, default: 3

    belongs_to :site, Plausible.Site

    has_many :deliveries, Plausible.Site.WebhookDelivery, foreign_key: :webhook_id

    timestamps()
  end

  def valid_event_types, do: @valid_event_types

  def changeset(webhook, attrs) do
    webhook
    |> cast(attrs, [:site_id, :url, :secret, :name, :events, :enabled, :failure_threshold])
    |> validate_required([:site_id, :url, :events])
    |> validate_url()
    |> validate_events()
    |> validate_secret()
    |> validate_length(:name, max: 100)
    |> validate_number(:failure_threshold, greater_than: 0)
  end

  defp validate_url(changeset) do
    changeset
    |> validate_length(:url, max: 500)
    |> validate_format(:url, ~r/\Ahttps?:\/\/.+/, message: "must be a valid HTTP/HTTPS URL")
    |> validate_not_localhost()
  end

  defp validate_not_localhost(changeset) do
    url = get_change(changeset, :url)

    if url && String.contains?(url, "localhost") do
      add_error(changeset, :url, "cannot be a localhost URL")
    else
      changeset
    end
  end

  defp validate_events(changeset) do
    validate_change(changeset, :events, fn :events, events ->
      if is_list(events) && length(events) > 0 do
        invalid = events -- @valid_event_types
        if invalid == [] do
          []
        else
          [events: "contains invalid event types: #{inspect(invalid)}"]
        end
      else
        [events: "must have at least one event type"]
      end
    end)
  end

  defp validate_secret(changeset) do
    changeset
    |> validate_length(:secret, min: 0, max: 64)
    |> validate_format(:secret, ~r/^[a-zA-Z0-9_-]*$/,
      message: "must contain only alphanumeric characters, underscores, and hyphens"
    )
  end
end
