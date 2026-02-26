defmodule Plausible.WebhookNotifications.ContextTest do
  use Plausible.DataCase
  alias Plausible.WebhookNotifications.Context
  alias Plausible.Site

  describe "create_webhook/2" do
    setup [:create_site]

    test "creates a webhook with valid attributes", %{site: site} do
      {:ok, webhook} =
        Context.create_webhook(site, %{
          "endpoint_url" => "https://example.com/webhook",
          "secret" => "test_secret_key_123456"
        })

      assert webhook.id != nil
      assert webhook.endpoint_url == "https://example.com/webhook"
      assert webhook.site_id == site.id
      assert webhook.is_active == true
      assert webhook.secret != "test_secret_key_123456" # Secret should be hashed
    end

    test "creates a webhook with is_active set to false", %{site: site} do
      {:ok, webhook} =
        Context.create_webhook(site, %{
          "endpoint_url" => "https://example.com/webhook",
          "secret" => "test_secret_key_123456",
          "is_active" => false
        })

      assert webhook.is_active == false
    end

    test "fails when endpoint_url is not HTTPS", %{site: site} do
      {:error, changeset} =
        Context.create_webhook(site, %{
          "endpoint_url" => "http://example.com/webhook",
          "secret" => "test_secret_key_123456"
        })

      assert Keyword.has_key?(changeset.errors, :endpoint_url)
    end

    test "fails when endpoint_url is invalid", %{site: site} do
      {:error, changeset} =
        Context.create_webhook(site, %{
          "endpoint_url" => "not-a-url",
          "secret" => "test_secret_key_123456"
        })

      assert Keyword.has_key?(changeset.errors, :endpoint_url)
    end

    test "fails when secret is too short", %{site: site} do
      {:error, changeset} =
        Context.create_webhook(site, %{
          "endpoint_url" => "https://example.com/webhook",
          "secret" => "short"
        })

      assert Keyword.has_key?(changeset.errors, :secret)
    end

    test "fails when endpoint_url is missing", %{site: site} do
      {:error, changeset} =
        Context.create_webhook(site, %{
          "secret" => "test_secret_key_123456"
        })

      assert Keyword.has_key?(changeset.errors, :endpoint_url)
    end

    test "fails when secret is missing", %{site: site} do
      {:error, changeset} =
        Context.create_webhook(site, %{
          "endpoint_url" => "https://example.com/webhook"
        })

      assert Keyword.has_key?(changeset.errors, :secret)
    end
  end

  describe "test_webhook/1" do
    setup [:create_site]

    test "sends a test webhook and creates a delivery log", %{site: site} do
      {:ok, webhook} =
        Context.create_webhook(site, %{
          "endpoint_url" => "https://example.com/webhook",
          "secret" => "test_secret_key_123456"
        })

      {:ok, log, payload} = Context.test_webhook(webhook)

      assert log.event_type == "test"
      assert log.status == "pending"
      assert log.webhook_config_id == webhook.id

      assert payload.event == "test"
      assert payload.site_id == webhook.site_id
      assert is_binary(payload.timestamp)
      assert payload.data.message == "This is a test webhook from Plausible Analytics"
    end

    test "test_webhook/1 returns the created delivery log with correct payload structure", %{site: site} do
      {:ok, webhook} =
        Context.create_webhook(site, %{
          "endpoint_url" => "https://example.com/webhook",
          "secret" => "another_secret_key_"
        })

      {:ok, log, payload} = Context.test_webhook(webhook)

      # Verify delivery log was created in the database
      assert log.id != nil
      assert log.payload == payload

      # Verify payload structure
      assert Map.has_key?(payload, :event)
      assert Map.has_key?(payload, :site_id)
      assert Map.has_key?(payload, :timestamp)
      assert Map.has_key?(payload, :data)
    end
  end

  describe "trigger management" do
    setup [:create_site]

    test "add_trigger/2 creates a trigger with default enabled state", %{site: site} do
      {:ok, webhook} =
        Context.create_webhook(site, %{
          "endpoint_url" => "https://example.com/webhook",
          "secret" => "test_secret_key_123456"
        })

      {:ok, trigger} =
        Context.add_trigger(webhook, %{
          "trigger_type" => "goal_completion"
        })

      assert trigger.trigger_type == "goal_completion"
      assert trigger.is_enabled == true
      assert trigger.webhook_config_id == webhook.id
    end

    test "add_trigger/2 creates a disabled trigger when is_enabled is false", %{site: site} do
      {:ok, webhook} =
        Context.create_webhook(site, %{
          "endpoint_url" => "https://example.com/webhook",
          "secret" => "test_secret_key_123456"
        })

      {:ok, trigger} =
        Context.add_trigger(webhook, %{
          "trigger_type" => "visitor_spike",
          "is_enabled" => false
        })

      assert trigger.trigger_type == "visitor_spike"
      assert trigger.is_enabled == false
    end

    test "update_trigger/2 can disable an enabled trigger", %{site: site} do
      {:ok, webhook} =
        Context.create_webhook(site, %{
          "endpoint_url" => "https://example.com/webhook",
          "secret" => "test_secret_key_123456"
        })

      {:ok, trigger} =
        Context.add_trigger(webhook, %{
          "trigger_type" => "goal_completion"
        })

      assert trigger.is_enabled == true

      {:ok, updated_trigger} =
        Context.update_trigger(trigger, %{
          "is_enabled" => false
        })

      assert updated_trigger.is_enabled == false
    end

    test "update_trigger/2 can enable a disabled trigger", %{site: site} do
      {:ok, webhook} =
        Context.create_webhook(site, %{
          "endpoint_url" => "https://example.com/webhook",
          "secret" => "test_secret_key_123456"
        })

      {:ok, trigger} =
        Context.add_trigger(webhook, %{
          "trigger_type" => "visitor_spike",
          "is_enabled" => false
        })

      assert trigger.is_enabled == false

      {:ok, updated_trigger} =
        Context.update_trigger(trigger, %{
          "is_enabled" => true
        })

      assert updated_trigger.is_enabled == true
    end

    test "get_enabled_triggers/1 returns only enabled triggers", %{site: site} do
      {:ok, webhook} =
        Context.create_webhook(site, %{
          "endpoint_url" => "https://example.com/webhook",
          "secret" => "test_secret_key_123456"
        })

      {:ok, _trigger1} =
        Context.add_trigger(webhook, %{
          "trigger_type" => "goal_completion",
          "is_enabled" => true
        })

      {:ok, _trigger2} =
        Context.add_trigger(webhook, %{
          "trigger_type" => "visitor_spike",
          "is_enabled" => false
        })

      enabled_triggers = Context.get_enabled_triggers(webhook)

      assert length(enabled_triggers) == 1
      assert hd(enabled_triggers).trigger_type == "goal_completion"
    end

    test "get_enabled_triggers/1 returns empty list when no triggers are enabled", %{site: site} do
      {:ok, webhook} =
        Context.create_webhook(site, %{
          "endpoint_url" => "https://example.com/webhook",
          "secret" => "test_secret_key_123456"
        })

      {:ok, _trigger} =
        Context.add_trigger(webhook, %{
          "trigger_type" => "goal_completion",
          "is_enabled" => false
        })

      enabled_triggers = Context.get_enabled_triggers(webhook)

      assert enabled_triggers == []
    end

    test "remove_trigger/1 deletes a trigger", %{site: site} do
      {:ok, webhook} =
        Context.create_webhook(site, %{
          "endpoint_url" => "https://example.com/webhook",
          "secret" => "test_secret_key_123456"
        })

      {:ok, trigger} =
        Context.add_trigger(webhook, %{
          "trigger_type" => "goal_completion"
        })

      {:ok, _} = Context.remove_trigger(trigger)

      # Reload webhook to verify trigger is gone
      webhook = Context.get_webhook!(webhook.id)
      assert webhook.event_triggers == []
    end

    test "update_trigger/2 can update threshold values", %{site: site} do
      {:ok, webhook} =
        Context.create_webhook(site, %{
          "endpoint_url" => "https://example.com/webhook",
          "secret" => "test_secret_key_123456"
        })

      {:ok, trigger} =
        Context.add_trigger(webhook, %{
          "trigger_type" => "visitor_spike",
          "is_enabled" => true
        })

      {:ok, updated_trigger} =
        Context.update_trigger(trigger, %{
          "threshold_value" => 50,
          "threshold_unit" => "percentage"
        })

      assert updated_trigger.threshold_value == 50
      assert updated_trigger.threshold_unit == "percentage"
    end
  end

  describe "list_deliveries/2" do
    setup [:create_site]

    test "returns deliveries for a webhook with default pagination", %{site: site} do
      {:ok, webhook} =
        Context.create_webhook(site, %{
          "endpoint_url" => "https://example.com/webhook",
          "secret" => "test_secret_key_123456"
        })

      # Create multiple delivery logs
      for i <- 1..5 do
        insert(:delivery_log, webhook_config: webhook, event_type: "test_#{i}")
      end

      result = Context.list_deliveries(webhook)

      assert length(result.deliveries) == 5
      assert result.total == 5
      assert result.page == 1
      assert result.limit == 20
    end

    test "orders deliveries by inserted_at descending (newest first)", %{site: site} do
      {:ok, webhook} =
        Context.create_webhook(site, %{
          "endpoint_url" => "https://example.com/webhook",
          "secret" => "test_secret_key_123456"
        })

      # Create deliveries
      for i <- 1..3 do
        insert(:delivery_log, webhook_config: webhook, event_type: "test_#{i}")
      end

      result = Context.list_deliveries(webhook)

      [first, second, third] = result.deliveries
      assert first.inserted_at >= second.inserted_at
      assert second.inserted_at >= third.inserted_at
    end

    test "filters deliveries by status when status option is provided", %{site: site} do
      {:ok, webhook} =
        Context.create_webhook(site, %{
          "endpoint_url" => "https://example.com/webhook",
          "secret" => "test_secret_key_123456"
        })

      # Create successful deliveries
      for _ <- 1..3 do
        insert(:delivery_log, webhook_config: webhook, status: "success")
      end

      # Create failed deliveries
      for _ <- 1..2 do
        insert(:delivery_log, webhook_config: webhook, status: "failed")
      end

      success_result = Context.list_deliveries(webhook, %{status: "success"})
      assert length(success_result.deliveries) == 3
      assert success_result.total == 3

      failed_result = Context.list_deliveries(webhook, %{status: "failed"})
      assert length(failed_result.deliveries) == 2
      assert failed_result.total == 2
    end

    test "respects pagination options", %{site: site} do
      {:ok, webhook} =
        Context.create_webhook(site, %{
          "endpoint_url" => "https://example.com/webhook",
          "secret" => "test_secret_key_123456"
        })

      # Create 25 deliveries
      for i <- 1..25 do
        insert(:delivery_log, webhook_config: webhook, event_type: "test_#{i}")
      end

      # First page with 10 items
      result1 = Context.list_deliveries(webhook, %{page: 1, limit: 10})
      assert length(result1.deliveries) == 10
      assert result1.total == 25
      assert result1.page == 1
      assert result1.limit == 10
      assert result1.total_pages == 3

      # Second page
      result2 = Context.list_deliveries(webhook, %{page: 2, limit: 10})
      assert length(result2.deliveries) == 10

      # Third page
      result3 = Context.list_deliveries(webhook, %{page: 3, limit: 10})
      assert length(result3.deliveries) == 5
    end

    test "limits maximum items to 100", %{site: site} do
      {:ok, webhook} =
        Context.create_webhook(site, %{
          "endpoint_url" => "https://example.com/webhook",
          "secret" => "test_secret_key_123456"
        })

      # Create more than 100 deliveries
      for i <- 1..150 do
        insert(:delivery_log, webhook_config: webhook, event_type: "test_#{i}")
      end

      result = Context.list_deliveries(webhook, %{limit: 200})

      assert length(result.deliveries) == 100
      assert result.limit == 100
    end

    test "returns empty result when no deliveries exist", %{site: site} do
      {:ok, webhook} =
        Context.create_webhook(site, %{
          "endpoint_url" => "https://example.com/webhook",
          "secret" => "test_secret_key_123456"
        })

      result = Context.list_deliveries(webhook)

      assert length(result.deliveries) == 0
      assert result.total == 0
      assert result.total_pages == 0
    end
  end

  defp create_site(_) do
    site = insert(:site, domain: "test-site.com", hostname: "test-site.com")
    {:ok, site: site}
  end
end
