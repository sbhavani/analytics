defmodule Plausible.WebhooksTest do
  use Plausible.DataCase
  alias Plausible.Webhooks
  alias Plausible.Webhooks.Webhook

  setup do
    user = insert(:user)
    site = insert(:site, members: [user])
    {:ok, user: user, site: site}
  end

  describe "create_webhook/2" do
    test "creates a webhook with valid HTTPS URL", %{site: site} do
      attrs = %{
        url: "https://example.com/webhook",
        trigger_types: ["visitor_spike"]
      }

      {:ok, webhook} = Webhooks.create_webhook(site, attrs)

      assert webhook.url == "https://example.com/webhook"
      assert webhook.trigger_types == ["visitor_spike"]
      assert webhook.enabled == true
    end

    test "creates a webhook with multiple trigger types", %{site: site} do
      attrs = %{
        url: "https://example.com/webhook",
        trigger_types: ["visitor_spike", "goal_completion"]
      }

      {:ok, webhook} = Webhooks.create_webhook(site, attrs)

      assert webhook.trigger_types == ["visitor_spike", "goal_completion"]
    end

    test "rejects HTTP (non-secure) URLs", %{site: site} do
      attrs = %{
        url: "http://example.com/webhook",
        trigger_types: ["visitor_spike"]
      }

      {:error, changeset} = Webhooks.create_webhook(site, attrs)

      assert "must use HTTPS protocol" in errors_on(changeset).url
    end

    test "rejects invalid URLs", %{site: site} do
      attrs = %{
        url: "not-a-url",
        trigger_types: ["visitor_spike"]
      }

      {:error, changeset} = Webhooks.create_webhook(site, attrs)

      assert "must be a valid HTTPS URL" in errors_on(changeset).url
    end

    test "rejects empty trigger types", %{site: site} do
      attrs = %{
        url: "https://example.com/webhook",
        trigger_types: []
      }

      {:error, changeset} = Webhooks.create_webhook(site, attrs)

      assert "must have at least one trigger type" in errors_on(changeset).trigger_types
    end

    test "rejects invalid trigger types", %{site: site} do
      attrs = %{
        url: "https://example.com/webhook",
        trigger_types: ["invalid_type"]
      }

      {:error, changeset} = Webhooks.create_webhook(site, attrs)

      assert "contains invalid trigger types: invalid_type" in errors_on(changeset).trigger_types
    end
  end

  describe "update_webhook/2" do
    test "updates webhook URL", %{site: site} do
      {:ok, webhook} = Webhooks.create_webhook(site, %{
        url: "https://example.com/webhook",
        trigger_types: ["visitor_spike"]
      })

      {:ok, updated} = Webhooks.update_webhook(webhook, %{
        url: "https://example.com/new-webhook"
      })

      assert updated.url == "https://example.com/new-webhook"
    end

    test "updates webhook enabled status", %{site: site} do
      {:ok, webhook} = Webhooks.create_webhook(site, %{
        url: "https://example.com/webhook",
        trigger_types: ["visitor_spike"],
        enabled: true
      })

      {:ok, updated} = Webhooks.update_webhook(webhook, %{enabled: false})

      assert updated.enabled == false
    end

    test "updates trigger types", %{site: site} do
      {:ok, webhook} = Webhooks.create_webhook(site, %{
        url: "https://example.com/webhook",
        trigger_types: ["visitor_spike"]
      })

      {:ok, updated} = Webhooks.update_webhook(webhook, %{
        trigger_types: ["goal_completion"]
      })

      assert updated.trigger_types == ["goal_completion"]
    end
  end

  describe "list_webhooks/1" do
    test "lists webhooks for a site", %{site: site} do
      {:ok, _webhook1} = Webhooks.create_webhook(site, %{
        url: "https://example.com/webhook1",
        trigger_types: ["visitor_spike"]
      })

      {:ok, _webhook2} = Webhooks.create_webhook(site, %{
        url: "https://example.com/webhook2",
        trigger_types: ["goal_completion"]
      })

      webhooks = Webhooks.list_webhooks(site)

      assert length(webhooks) == 2
    end
  end

  describe "delete_webhook/1" do
    test "deletes a webhook", %{site: site} do
      {:ok, webhook} = Webhooks.create_webhook(site, %{
        url: "https://example.com/webhook",
        trigger_types: ["visitor_spike"]
      })

      {:ok, deleted} = Webhooks.delete_webhook(webhook)

      assert deleted.id == webhook.id
    end
  end

  describe "get_enabled_webhooks_for_event/2" do
    test "returns only enabled webhooks with matching trigger", %{site: site} do
      {:ok, _enabled} = Webhooks.create_webhook(site, %{
        url: "https://example.com/enabled",
        trigger_types: ["visitor_spike"],
        enabled: true
      })

      {:ok, _disabled} = Webhooks.create_webhook(site, %{
        url: "https://example.com/disabled",
        trigger_types: ["visitor_spike"],
        enabled: false
      })

      {:ok, _wrong_trigger} = Webhooks.create_webhook(site, %{
        url: "https://example.com/wrong",
        trigger_types: ["goal_completion"],
        enabled: true
      })

      webhooks = Webhooks.get_enabled_webhooks_for_event(site, "visitor_spike")

      assert length(webhooks) == 1
      assert hd(webhooks).url == "https://example.com/enabled"
    end
  end

  describe "validate_https_url/1" do
    test "returns :ok for valid HTTPS URLs" do
      assert Webhooks.validate_https_url("https://example.com/webhook") == :ok
    end

    test "returns error for HTTP URLs" do
      assert {:error, "must use HTTPS protocol"} = Webhooks.validate_https_url("http://example.com/webhook")
    end

    test "returns error for invalid URLs" do
      assert {:error, "must be a valid HTTPS URL"} = Webhooks.validate_https_url("not-a-url")
    end
  end
end
