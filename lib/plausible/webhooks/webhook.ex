defmodule Plausible.Webhooks.Webhook do
  @moduledoc """
  Schema for webhook configuration
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @type t() :: %__MODULE__{}

  @valid_triggers ["goal.completed", "visitor.spike"]

  schema "webhooks" do
    field :url, :string
    field :secret, :string
    field :triggers, {:array, :string}
    field :active, :boolean, default: true
    field :name, :string

    belongs_to :site, Plausible.Site
    has_many :deliveries, Plausible.Webhooks.WebhookDelivery

    timestamps()
  end

  def valid_triggers, do: @valid_triggers

  def changeset(webhook, attrs \\ %{}) do
    webhook
    |> cast(attrs, [:url, :secret, :triggers, :active, :name, :site_id])
    |> validate_required([:url, :secret, :triggers, :site_id])
    |> validate_url_format()
    |> validate_triggers()
    |> put_secret()
  end

  def update_changeset(webhook, attrs \\ %{}) do
    webhook
    |> cast(attrs, [:url, :triggers, :active, :name])
    |> validate_url_format()
    |> validate_triggers()
  end

  defp validate_url_format(changeset) do
    changeset
    |> validate_required([:url])
    |> validate_format(:url, ~r/^https:\/\/.+/,
      message: "must be a valid HTTPS URL"
    )
  end

  defp validate_triggers(changeset) do
    validate_change(changeset, :triggers, fn :triggers, triggers ->
      if Enum.empty?(triggers) do
        [triggers: "must select at least one trigger"]
      else
        invalid = Enum.reject(triggers, &(&1 in @valid_triggers))
        if Enum.empty?(invalid) do
          []
        else
          [triggers: "contains invalid triggers: #{Enum.join(invalid, ", ")}"]
        end
      end
    end)
  end

  defp put_secret(changeset) do
    if get_change(changeset, :secret) do
      changeset
    else
      secret = :crypto.strong_rand_bytes(32) |> Base.encode64()
      put_change(changeset, :secret, secret)
    end
  end

  def for_site(query \\ __MODULE__, site_id) do
    from w in query, where: w.site_id == ^site_id
  end

  def active(query \\ __MODULE__) do
    from w in query, where: w.active == true
  end

  def with_trigger(query \\ __MODULE__, trigger) do
    from w in query, where: ^trigger in w.triggers
  end
end
