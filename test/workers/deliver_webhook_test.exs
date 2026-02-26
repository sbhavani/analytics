defmodule Plausible.Workers.DeliverWebhookTest do
  use Plausible.DataCase, async: true

  import Mox

  alias Plausible.Workers.DeliverWebhook
  alias Plausible.Site.WebhookDelivery

  setup :verify_on_exit!

  describe "perform/1" do
    test "delivers webhook successfully and records successful delivery" do
      site = insert(:site)
      webhook = insert(:webhook, site: site, enabled: true, secret: "my_secret_key_12345")
      trigger = insert(:webhook_trigger, webhook: webhook, trigger_type: "visitor_spike")

      payload = %{
        "site_id" => site.id,
        "event_type" => "visitor_spike",
        "visitors" => 150,
        "threshold" => 100
      }

      expect(
        Plausible.HTTPClient.Mock,
        :post,
        fn "https://example.com/webhook", headers, ^payload ->
          # Verify signature header is present
          assert Enum.any?(headers, fn {k, _} -> k == "x-signature" end)
          assert Enum.any?(headers, fn {k, v} -> k == "content-type" && v == "application/json" end)
          assert Enum.any?(headers, fn {k, _} -> k == "user-agent" end)

          {:ok, %{status: 200, body: "OK"}}
        end
      )

      job = %Oban.Job{
        args: %{
          "webhook_id" => webhook.id,
          "trigger_id" => trigger.id,
          "event_type" => "visitor_spike",
          "payload" => payload
        }
      }

      assert :ok = DeliverWebhook.perform(job)

      # Verify delivery was recorded
      delivery = Repo.get_by(WebhookDelivery, webhook_id: webhook.id)
      assert delivery.event_type == "visitor_spike"
      assert delivery.status_code == 200
      assert delivery.attempt_number == 1
      assert delivery.error_message == nil
    end

    test "records failed delivery on non-2xx response" do
      site = insert(:site)
      webhook = insert(:webhook, site: site, enabled: true, secret: "my_secret_key_12345")
      trigger = insert(:webhook_trigger, webhook: webhook, trigger_type: "goal_completion")

      payload = %{
        "site_id" => site.id,
        "event_type" => "goal_completion",
        "goal_id" => "123",
        "visitors" => 5
      }

      expect(
        Plausible.HTTPClient.Mock,
        :post,
        fn "https://example.com/webhook", _headers, ^payload ->
          {:ok, %{status: 500, body: "Internal Server Error"}}
        end
      )

      job = %Oban.Job{
        args: %{
          "webhook_id" => webhook.id,
          "trigger_id" => trigger.id,
          "event_type" => "goal_completion",
          "payload" => payload
        }
      }

      assert {:error, :delivery_failed} = DeliverWebhook.perform(job)

      # Verify delivery was recorded as failed
      delivery = Repo.get_by(WebhookDelivery, webhook_id: webhook.id)
      assert delivery.event_type == "goal_completion"
      assert delivery.status_code == 500
      assert delivery.response_body == "Internal Server Error"
      assert delivery.error_message == "HTTP error"
    end

    test "records error on HTTP failure" do
      site = insert(:site)
      webhook = insert(:webhook, site: site, enabled: true, secret: "my_secret_key_12345")
      trigger = insert(:webhook_trigger, webhook: webhook, trigger_type: "visitor_spike")

      payload = %{
        "site_id" => site.id,
        "event_type" => "visitor_spike",
        "visitors" => 200
      }

      expect(
        Plausible.HTTPClient.Mock,
        :post,
        fn "https://example.com/webhook", _headers, ^payload ->
          {:error, :econnrefused}
        end
      )

      job = %Oban.Job{
        args: %{
          "webhook_id" => webhook.id,
          "trigger_id" => trigger.id,
          "event_type" => "visitor_spike",
          "payload" => payload
        }
      }

      assert {:error, :econnrefused} = DeliverWebhook.perform(job)

      # Verify delivery was recorded with error
      delivery = Repo.get_by(WebhookDelivery, webhook_id: webhook.id)
      assert delivery.status_code == nil
      assert delivery.error_message =~ "econnrefused"
    end

    test "skips delivery when webhook is disabled" do
      site = insert(:site)
      webhook = insert(:webhook, site: site, enabled: false, secret: "my_secret_key_12345")
      trigger = insert(:webhook_trigger, webhook: webhook)

      payload = %{"site_id" => site.id, "event_type" => "visitor_spike"}

      job = %Oban.Job{
        args: %{
          "webhook_id" => webhook.id,
          "trigger_id" => trigger.id,
          "event_type" => "visitor_spike",
          "payload" => payload
        }
      }

      assert :ok = DeliverWebhook.perform(job)

      # Verify no delivery was recorded
      refute Repo.get_by(WebhookDelivery, webhook_id: webhook.id)
    end

    test "skips delivery when webhook does not exist" do
      trigger = insert(:webhook_trigger)

      payload = %{"site_id" => "fake-site-id", "event_type" => "visitor_spike"}

      job = %Oban.Job{
        args: %{
          "webhook_id" => Ecto.UUID.generate(),
          "trigger_id" => trigger.id,
          "event_type" => "visitor_spike",
          "payload" => payload
        }
      }

      assert :ok = DeliverWebhook.perform(job)

      # Verify no delivery was recorded
      assert Repo.all(WebhookDelivery) == []
    end

    test "signs payload with HMAC-SHA256" do
      site = insert(:site)
      webhook = insert(:webhook, site: site, enabled: true, secret: "my_secret_key_12345")
      trigger = insert(:webhook_trigger, webhook: webhook, trigger_type: "visitor_spike")

      payload = %{"test" => "data"}

      expect(
        Plausible.HTTPClient.Mock,
        :post,
        fn "https://example.com/webhook", headers, ^payload ->
          # Verify the signature header is present and has correct format
          signature_header = List.keyfind(headers, "x-signature", 0)

          assert {_, "x-signature"} = signature_header
          {_, value} = signature_header
          assert value =~ "sha256="
          # HMAC-SHA256 produces 64 hex chars
          assert String.length(value) == 71  # "sha256=" (7) + 64 hex chars

          {:ok, %{status: 200, body: "OK"}}
        end
      )

      job = %Oban.Job{
        args: %{
          "webhook_id" => webhook.id,
          "trigger_id" => trigger.id,
          "event_type" => "visitor_spike",
          "payload" => payload
        }
      }

      DeliverWebhook.perform(job)
    end
  end

  describe "webhook_retry_delay/1" do
    test "returns correct delays for retry attempts" do
      # First attempt: 1 minute
      assert DeliverWebhook.webhook_retry_delay(1) == :timer.minutes(1)

      # Second attempt: 10 minutes
      assert DeliverWebhook.webhook_retry_delay(2) == :timer.minutes(10)

      # Third attempt: 60 minutes
      assert DeliverWebhook.webhook_retry_delay(3) == :timer.minutes(60)

      # Fourth and subsequent attempts: 60 minutes
      assert DeliverWebhook.webhook_retry_delay(4) == :timer.minutes(60)
      assert DeliverWebhook.webhook_retry_delay(5) == :timer.minutes(60)
    end
  end
end
