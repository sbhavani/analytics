defmodule Plausible.Site.WebhookTrigger do
  @moduledoc """
  Schema for webhook trigger configuration.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @trigger_types [:goal_completion, :visitor_spike]

  schema "webhook_triggers" do
    field :trigger_type, :string
    field :enabled, :boolean, default: true
    field :threshold, :integer

    belongs_to :webhook, Plausible.Site.Webhook

    timestamps()
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(trigger, attrs) do
    trigger
      |> cast(attrs, [:webhook_id, :trigger_type, :enabled, :threshold])
      |> validate_required([:webhook_id, :trigger_type])
      |> validate_inclusion(:trigger_type, @trigger_types)
      |> validate_number(:threshold, greater_than_or_equal_to: 1)
      |> validate_number(:threshold, less_than_or_equal_to: 10_000_000)
  end

  @spec create_for_webhook(t(), map()) :: Ecto.Changeset.t()
  def create_for_webhook(webhook, attrs) do
    webhook
      |> Ecto.build_assoc(:triggers)
      |> changeset(attrs)
  end

  @spec trigger_types() :: [atom()]
  def trigger_types, do: @trigger_types
end
