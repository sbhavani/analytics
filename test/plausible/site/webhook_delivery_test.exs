defmodule Plausible.Site.WebhookDeliveryTest do
  use Plausible.DataCase
  alias Plausible.Site.WebhookDelivery
  alias Plausible.Site.Webhook
  alias Plausible.Site.WebhookTrigger

  describe "changeset/2" do
    test "validates required fields" do
      changeset = WebhookDelivery.changeset(%WebhookDelivery{}, %{})

      assert changeset.errors[:webhook_id] == {"can't be blank", [validation: :required]}
      assert changeset.errors[:trigger_id] == {"can't be blank", [validation: :required]}
      assert changeset.errors[:event_type] == {"can't be blank", [validation: :required]}
      assert changeset.errors[:payload] == {"can't be blank", [validation: :required]}
    end

    test "creates valid changeset with required fields" do
      webhook = insert(:webhook)
      trigger = insert(:webhook_trigger, webhook: webhook)

      attrs = %{
        webhook_id: webhook.id,
        trigger_id: trigger.id,
        event_type: "spike",
        payload: %{"visitors" => 100}
      }

      changeset = WebhookDelivery.changeset(%WebhookDelivery{}, attrs)

      assert changeset.valid?
      assert changeset.changes.webhook_id == webhook.id
      assert changeset.changes.trigger_id == trigger.id
      assert changeset.changes.event_type == "spike"
      assert changeset.changes.payload == %{"visitors" => 100}
    end

    test "accepts optional fields" do
      webhook = insert(:webhook)
      trigger = insert(:webhook_trigger, webhook: webhook)

      attrs = %{
        webhook_id: webhook.id,
        trigger_id: trigger.id,
        event_type: "spike",
        payload: %{"visitors" => 100},
        status_code: 200,
        response_body: "OK",
        error_message: nil,
        attempt_number: 1
      }

      changeset = WebhookDelivery.changeset(%WebhookDelivery{}, attrs)

      assert changeset.valid?
      assert changeset.changes.status_code == 200
      assert changeset.changes.response_body == "OK"
      assert changeset.changes.attempt_number == 1
    end

    test "accepts error state fields" do
      webhook = insert(:webhook)
      trigger = insert(:webhook_trigger, webhook: webhook)

      attrs = %{
        webhook_id: webhook.id,
        trigger_id: trigger.id,
        event_type: "spike",
        payload: %{"visitors" => 100},
        status_code: nil,
        response_body: nil,
        error_message: "Connection refused",
        attempt_number: 2
      }

      changeset = WebhookDelivery.changeset(%WebhookDelivery{}, attrs)

      assert changeset.valid?
      assert changeset.changes.error_message == "Connection refused"
      assert changeset.changes.attempt_number == 2
    end
  end

  describe "successful/1" do
    test "filters deliveries with 2xx status codes" do
      webhook = insert(:webhook)

      delivery_200 = insert(:webhook_delivery, webhook: webhook, status_code: 200)
      delivery_201 = insert(:webhook_delivery, webhook: webhook, status_code: 201)
      delivery_299 = insert(:webhook_delivery, webhook: webhook, status_code: 299)

      result =
        WebhookDelivery
        |> WebhookDelivery.successful()
        |> Repo.all()
        |> Enum.map(& &1.id)

      assert delivery_200.id in result
      assert delivery_201.id in result
      assert delivery_299.id in result
    end

    test "excludes non-2xx status codes from successful" do
      webhook = insert(:webhook)

      insert(:webhook_delivery, webhook: webhook, status_code: 400)
      insert(:webhook_delivery, webhook: webhook, status_code: 500)
      insert(:webhook_delivery, webhook: webhook, status_code: nil, error_message: "Error")

      result =
        WebhookDelivery
        |> WebhookDelivery.successful()
        |> Repo.all()

      assert result == []
    end
  end

  describe "failed/1" do test "filters deliveries with 4xx status codes" do
      webhook = insert(:webhook)

      delivery_400 = insert(:webhook_delivery, webhook: webhook, status_code: 400)
      delivery_404 = insert(:webhook_delivery, webhook: webhook, status_code: 404)
      delivery_499 = insert(:webhook_delivery, webhook: webhook, status_code: 499)

      result =
        WebhookDelivery
        |> WebhookDelivery.failed()
        |> Repo.all()
        |> Enum.map(& &1.id)

      assert delivery_400.id in result
      assert delivery_404.id in result
      assert delivery_499.id in result
    end

    test "filters deliveries with 5xx status codes" do
      webhook = insert(:webhook)

      delivery_500 = insert(:webhook_delivery, webhook: webhook, status_code: 500)
      delivery_503 = insert(:webhook_delivery, webhook: webhook, status_code: 503)

      result =
        WebhookDelivery
        |> WebhookDelivery.failed()
        |> Repo.all()
        |> Enum.map(& &1.id)

      assert delivery_500.id in result
      assert delivery_503.id in result
    end

    test "filters deliveries with error messages" do
      webhook = insert(:webhook)

      delivery =
        insert(:webhook_delivery,
          webhook: webhook,
          status_code: nil,
          error_message: "Connection refused"
        )

      result =
        WebhookDelivery
        |> WebhookDelivery.failed()
        |> Repo.all()
        |> Enum.map(& &1.id)

      assert delivery.id in result
    end

    test "filters deliveries with nil status code" do
      webhook = insert(:webhook)

      delivery = insert(:webhook_delivery, webhook: webhook, status_code: nil)

      result =
        WebhookDelivery
        |> WebhookDelivery.failed()
        |> Repo.all()
        |> Enum.map(& &1.id)

      assert delivery.id in result
    end

    test "excludes successful deliveries from failed" do
      webhook = insert(:webhook)

      insert(:webhook_delivery, webhook: webhook, status_code: 200)
      insert(:webhook_delivery, webhook: webhook, status_code: 201)

      result =
        WebhookDelivery
        |> WebhookDelivery.failed()
        |> Repo.all()

      assert result == []
    end
  end

  describe "for_webhook/2" do
    test "filters deliveries by webhook_id" do
      webhook1 = insert(:webhook)
      webhook2 = insert(:webhook)

      delivery1 = insert(:webhook_delivery, webhook: webhook1)
      delivery2 = insert(:webhook_delivery, webhook: webhook2)

      result =
        WebhookDelivery
        |> WebhookDelivery.for_webhook(webhook1.id)
        |> Repo.all()
        |> Enum.map(& &1.id)

      assert delivery1.id in result
      refute delivery2.id in result
    end

    test "works as queryable" do
      webhook = insert(:webhook)
      delivery = insert(:webhook_delivery, webhook: webhook)

      result =
        WebhookDelivery.for_webhook(webhook.id)
        |> Repo.all()
        |> Enum.map(& &1.id)

      assert delivery.id in result
    end
  end

  describe "ordered_by_inserted_at/2" do
    test "orders by inserted_at descending by default" do
      webhook = insert(:webhook)

      delivery1 = insert(:webhook_delivery, webhook: webhook)
      delivery2 = insert(:webhook_delivery, webhook: webhook)
      delivery3 = insert(:webhook_delivery, webhook: webhook)

      result =
        WebhookDelivery
        |> WebhookDelivery.for_webhook(webhook.id)
        |> WebhookDelivery.ordered_by_inserted_at()
        |> Repo.all()
        |> Enum.map(& &1.id)

      # Descending order - newest first
      assert result == [delivery3.id, delivery2.id, delivery1.id]
    end

    test "orders by inserted_at ascending when specified" do
      webhook = insert(:webhook)

      delivery1 = insert(:webhook_delivery, webhook: webhook)
      delivery2 = insert(:webhook_delivery, webhook: webhook)
      delivery3 = insert(:webhook_delivery, webhook: webhook)

      result =
        WebhookDelivery
        |> WebhookDelivery.for_webhook(webhook.id)
        |> WebhookDelivery.ordered_by_inserted_at(:asc)
        |> Repo.all()
        |> Enum.map(& &1.id)

      # Ascending order - oldest first
      assert result == [delivery1.id, delivery2.id, delivery3.id]
    end
  end

  describe "with_status/2" do
    test "filters by 'success' status" do
      webhook = insert(:webhook)

      insert(:webhook_delivery, webhook: webhook, status_code: 200)
      failed_delivery = insert(:webhook_delivery, webhook: webhook, status_code: 400)

      result =
        WebhookDelivery
        |> WebhookDelivery.with_status("success")
        |> Repo.all()
        |> Enum.map(& &1.id)

      assert length(result) == 1
      refute failed_delivery.id in result
    end

    test "filters by 'failed' status" do
      webhook = insert(:webhook)

      success_delivery = insert(:webhook_delivery, webhook: webhook, status_code: 200)
      insert(:webhook_delivery, webhook: webhook, status_code: 400)

      result =
        WebhookDelivery
        |> WebhookDelivery.with_status("failed")
        |> Repo.all()
        |> Enum.map(& &1.id)

      assert length(result) == 1
      refute success_delivery.id in result
    end

    test "returns all when status is nil or unknown" do
      webhook = insert(:webhook)

      delivery1 = insert(:webhook_delivery, webhook: webhook, status_code: 200)
      delivery2 = insert(:webhook_delivery, webhook: webhook, status_code: 400)

      result_all =
        WebhookDelivery
        |> WebhookDelivery.with_status(nil)
        |> Repo.all()
        |> Enum.map(& &1.id)

      assert delivery1.id in result_all
      assert delivery2.id in result_all

      result_unknown =
        WebhookDelivery
        |> WebhookDelivery.with_status("unknown")
        |> Repo.all()
        |> Enum.map(& &1.id)

      assert delivery1.id in result_unknown
      assert delivery2.id in result_unknown
    end
  end

  describe "within_date_range/3" do
    test "filters deliveries within date range" do
      webhook = insert(:webhook)

      # Insert deliveries at specific times
      delivery1 =
        insert(:webhook_delivery, webhook: webhook)
        |> Repo.update!(inserted_at: ~N[2024-01-01 10:00:00])

      delivery2 =
        insert(:webhook_delivery, webhook: webhook)
        |> Repo.update!(inserted_at: ~N[2024-01-15 10:00:00])

      delivery3 =
        insert(:webhook_delivery, webhook: webhook)
        |> Repo.update!(inserted_at: ~N[2024-02-01 10:00:00])

      from_date = ~N[2024-01-01 00:00:00]
      to_date = ~N[2024-01-31 23:59:59]

      result =
        WebhookDelivery
        |> WebhookDelivery.within_date_range(from_date, to_date)
        |> Repo.all()
        |> Enum.map(& &1.id)

      assert delivery1.id in result
      assert delivery2.id in result
      refute delivery3.id in result
    end

    test "returns empty when no deliveries in range" do
      webhook = insert(:webhook)

      insert(:webhook_delivery, webhook: webhook)
      |> Repo.update!(inserted_at: ~N[2024-03-01 10:00:00])

      from_date = ~N[2024-01-01 00:00:00]
      to_date = ~N[2024-01-31 23:59:59]

      result =
        WebhookDelivery
        |> WebhookDelivery.within_date_range(from_date, to_date)
        |> Repo.all()

      assert result == []
    end
  end

  describe "combined queries" do
    test "can chain multiple query functions" do
      webhook = insert(:webhook)

      # Successful delivery in range
      success_delivery1 =
        insert(:webhook_delivery, webhook: webhook, status_code: 200)
        |> Repo.update!(inserted_at: ~N[2024-01-10 10:00:00])

      # Failed delivery in range
      insert(:webhook_delivery, webhook: webhook, status_code: 400)
      |> Repo.update!(inserted_at: ~N[2024-01-10 10:00:00])

      # Successful delivery out of range
      insert(:webhook_delivery, webhook: webhook, status_code: 200)
      |> Repo.update!(inserted_at: ~N[2024-03-01 10:00:00])

      from_date = ~N[2024-01-01 00:00:00]
      to_date = ~N[2024-01-31 23:59:59]

      result =
        WebhookDelivery
        |> WebhookDelivery.for_webhook(webhook.id)
        |> WebhookDelivery.with_status("success")
        |> WebhookDelivery.within_date_range(from_date, to_date)
        |> WebhookDelivery.ordered_by_inserted_at()
        |> Repo.all()

      assert length(result) == 1
      assert hd(result).id == success_delivery1.id
    end
  end
end
