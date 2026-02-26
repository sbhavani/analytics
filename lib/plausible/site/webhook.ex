defmodule Plausible.Site.Webhook do
  @moduledoc """
  Schema for webhook configuration per site.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "webhooks" do
    field :url, :string
    field :secret, :string
    field :enabled_events, {:array, :string}
    field :threshold, :integer
    field :last_sent, :naive_datetime
    belongs_to :site, Plausible.Site

    timestamps()
  end

  def changeset(webhook, attrs) do
    webhook
    |> cast(attrs, [:site_id, :url, :secret, :enabled_events, :threshold])
    |> validate_required([:site_id, :url, :secret, :enabled_events])
    |> validate_url(:url)
    |> validate_length(:url, max: 500)
    |> validate_length(:secret, min: 16)
    |> validate_subset(:enabled_events, ["spike", "drop", "goal"])
    |> validate_number(:threshold, greater_than_or_equal_to: 1)
    |> check_constraint(:enabled_events, name: :at_least_one_event_enabled)
  end

  defp validate_url(changeset, field) do
    validate_change(changeset, field, fn field, value ->
      case URI.parse(value) do
        %URI{scheme: scheme, host: host} when scheme in ["http", "https"] and host != nil ->
          []

        _ ->
          [{field, "must be a valid HTTP or HTTPS URL"}]
      end
    end)
  end
end
