defmodule Plausible.Webhooks.Webhook do
  @moduledoc """
  Schema for webhook configuration
  """
  use Ecto.Schema
  use Plausible
  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  @valid_trigger_types ["visitor_spike", "goal_completion"]

  schema "webhooks" do
    field :url, :string
    field :enabled, :boolean, default: true
    field :trigger_types, {:array, :string}, default: []

    belongs_to :site, Plausible.Site

    has_many :deliveries, Plausible.Webhooks.Delivery, foreign_key: :webhook_id

    timestamps()
  end

  def valid_trigger_types, do: @valid_trigger_types

  def changeset(webhook, attrs \\ %{}) do
    webhook
    |> cast(attrs, [:url, :enabled, :trigger_types, :site_id])
    |> validate_required([:url, :site_id])
    |> validate_url(:url)
    |> validate_trigger_types()
    |> foreign_key_constraint(:site_id)
  end

  defp validate_url(changeset, field) do
    validate_change(changeset, field, fn _, url ->
      case URI.parse(url) do
        %URI{scheme: "https", host: host} when host != "" ->
          []

        %URI{scheme: nil} ->
          [url: "must be a valid URL"]

        %URI{scheme: "http"} ->
          [url: "must use HTTPS protocol"]

        _ ->
          [url: "must be a valid HTTPS URL"]
      end
    end)
  end

  defp validate_trigger_types(changeset) do
    validate_change(changeset, :trigger_types, fn _, trigger_types ->
      if is_list(trigger_types) and length(trigger_types) > 0 do
        invalid = trigger_types -- @valid_trigger_types
        if invalid == [] do
          []
        else
          [trigger_types: "contains invalid trigger types: #{invalid |> Enum.join(", ")}"]
        end
      else
        [trigger_types: "must have at least one trigger type"]
      end
    end)
  end
end
