defmodule Plausible.Workers.CleanWebhookDeliveries do
  @moduledoc """
  Job removing webhook delivery logs older than 30 days.
  """

  use Plausible.Repo
  use Oban.Worker, queue: :clean_webhook_deliveries

  @retention_days 30

  @impl Oban.Worker
  def perform(_job) do
    cutoff =
      NaiveDateTime.utc_now(:second)
      |> NaiveDateTime.add(-1 * @retention_days * 24 * 3600)

    deleted_count =
      Repo.delete_all(
        from dl in Plausible.WebhookNotifications.DeliveryLog,
          where: dl.inserted_at < ^cutoff
      )

    {:ok, deleted_count}
  end
end
