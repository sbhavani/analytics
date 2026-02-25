defmodule Plausible.Webhooks.Webhook do
  @moduledoc """
  Schema for webhook configurations.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Plausible.Site
  alias Plausible.Webhooks.Context

  schema "webhook_configurations" do
    field :url, :string
    field :secret, :string
    field :enabled, :boolean, default: true
    field :triggers, {:array, :string}, default: []
    field :thresholds, :map, default: %{}
    field :deleted_at, :naive_datetime

    belongs_to :site, Site, type: :binary_id

    has_many :deliveries, Plausible.Webhooks.Delivery, foreign_key: :webhook_configuration_id

    timestamps()
  end

  def enabled(webhooks) do
    Enum.filter(webhooks, fn w -> w.enabled end)
  end

  def for_site(query \\ __MODULE__, site_id) do
    from w in query,
      where: w.site_id == ^site_id,
      where: is_nil(w.deleted_at),
      order_by: [desc: :inserted_at]
  end

  def changeset(webhook \\ %__MODULE__{}, attrs) do
    webhook
    |> cast(attrs, [:url, :secret, :enabled, :triggers, :thresholds, :site_id])
    |> validate_required([:url, :secret, :site_id])
    |> validate_url(:url)
    |> validate_length(:secret, min: 16)
    |> validate_trigger_selection()
    |> validate_thresholds()
  end

  defp validate_url(changeset, field) do
    validate_change(changeset, field, fn field, value ->
      if Context.valid_url?(value) do
        []
      else
        [{field, "must be a valid HTTP/HTTPS URL"}]
      end
    end)
  end

  defp validate_trigger_selection(changeset) do
    validate_change(changeset, :triggers, fn _, triggers ->
      if Context.valid_triggers?(triggers) do
        []
      else
        [{:triggers, "must contain at least one valid trigger (goal_completion, visitor_spike)"}]
      end
    end)
  end

  defp validate_thresholds(changeset) do
    thresholds = get_change(changeset, :thresholds) || %{}

    errors =
      thresholds
      |> Enum.flat_map(fn {key, value} ->
        if Context.valid_threshold?(value) do
          []
        else
          [{:thresholds, "threshold for #{key} must be a positive integer between 1 and 500"}]
        end
      end)

    case errors do
      [] -> changeset
      _ -> add_error(changeset, :thresholds, "invalid threshold configuration")
    end
  end
end
