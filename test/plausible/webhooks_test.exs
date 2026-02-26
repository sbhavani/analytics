defmodule Plausible.WebhooksTest do
  use Plausible.DataCase
  alias Plausible.Webhooks
  alias Plausible.Site.Webhook

  describe "CRUD operations" do
    setup do
      site = new_site()
      {:ok, %{site: site}}
    end

    test "create_webhook/2 creates a webhook for a site", %{site: site} do
      attrs = %{
        url: "https://example.com/webhook",
        secret: "test_secret_key_12345678",
        enabled_events: ["spike"],
        threshold: 10
      }

      {:ok, webhook} = Webhooks.create_webhook(site, attrs)

      assert webhook.site_id == site.id
      assert webhook.url == "https://example.com/webhook"
      assert webhook.secret == "test_secret_key_12345678"
      assert webhook.enabled_events == ["spike"]
      assert webhook.threshold == 10
    end

    test "create_webhook/2 validates required fields", %{site: site} do
      attrs = %{url: "https://example.com/webhook"}

      {:error, changeset} = Webhooks.create_webhook(site, attrs)

      assert changeset.errors[:secret]
      assert changeset.errors[:enabled_events]
    end

    test "create_webhook/2 validates URL format", %{site: site} do
      attrs = %{
        url: "not-a-url",
        secret: "test_secret_key_12345678",
        enabled_events: ["spike"]
      }

      {:error, changeset} = Webhooks.create_webhook(site, attrs)

      assert changeset.errors[:url]
    end

    test "create_webhook/2 validates secret minimum length", %{site: site} do
      attrs = %{
        url: "https://example.com/webhook",
        secret: "short",
        enabled_events: ["spike"]
      }

      {:error, changeset} = Webhooks.create_webhook(site, attrs)

      assert changeset.errors[:secret]
    end

    test "list_webhooks/1 returns all webhooks for a site", %{site: site} do
      {:ok, _} = Webhooks.create_webhook(site, %{
        url: "https://example.com/webhook1",
        secret: "test_secret_key_12345678",
        enabled_events: ["spike"]
      })

      {:ok, _} = Webhooks.create_webhook(site, %{
        url: "https://example.com/webhook2",
        secret: "another_secret_key_123456",
        enabled_events: ["goal"]
      })

      webhooks = Webhooks.list_webhooks(site)

      assert length(webhooks) == 2
    end

    test "list_webhooks/1 returns empty list for site with no webhooks", %{site: site} do
      webhooks = Webhooks.list_webhooks(site)

      assert webhooks == []
    end

    test "get_webhook!/1 returns a webhook by id", %{site: site} do
      {:ok, created} = Webhooks.create_webhook(site, %{
        url: "https://example.com/webhook",
        secret: "test_secret_key_12345678",
        enabled_events: ["spike"]
      })

      webhook = Webhooks.get_webhook!(created.id)

      assert webhook.id == created.id
      assert webhook.url == "https://example.com/webhook"
    end

    test "update_webhook/2 updates a webhook", %{site: site} do
      {:ok, webhook} = Webhooks.create_webhook(site, %{
        url: "https://example.com/webhook",
        secret: "test_secret_key_12345678",
        enabled_events: ["spike"]
      })

      {:ok, updated} = Webhooks.update_webhook(webhook, %{
        url: "https://example.com/updated",
        enabled_events: ["spike", "drop"]
      })

      assert updated.id == webhook.id
      assert updated.url == "https://example.com/updated"
      assert updated.enabled_events == ["spike", "drop"]
      assert updated.secret == webhook.secret
    end

    test "update_webhook/2 validates URL format on update", %{site: site} do
      {:ok, webhook} = Webhooks.create_webhook(site, %{
        url: "https://example.com/webhook",
        secret: "test_secret_key_12345678",
        enabled_events: ["spike"]
      })

      {:error, changeset} = Webhooks.update_webhook(webhook, %{
        url: "invalid-url"
      })

      assert changeset.errors[:url]
    end

    test "delete_webhook/1 deletes a webhook", %{site: site} do
      {:ok, webhook} = Webhooks.create_webhook(site, %{
        url: "https://example.com/webhook",
        secret: "test_secret_key_12345678",
        enabled_events: ["spike"]
      })

      {:ok, deleted} = Webhooks.delete_webhook(webhook)

      assert deleted.id == webhook.id

      assert_raise Ecto.NoResultsError, fn ->
        Webhooks.get_webhook!(webhook.id)
      end
    end

    test "webhooks_for_event/2 returns webhooks with specific event enabled", %{site: site} do
      {:ok, _} = Webhooks.create_webhook(site, %{
        url: "https://example.com/spike-webhook",
        secret: "test_secret_key_12345678",
        enabled_events: ["spike"]
      })

      {:ok, _} = Webhooks.create_webhook(site, %{
        url: "https://example.com/goal-webhook",
        secret: "another_secret_key_123456",
        enabled_events: ["goal"]
      })

      {:ok, _} = Webhooks.create_webhook(site, %{
        url: "https://example.com/both-webhook",
        secret: "yet_another_secret_key_1234",
        enabled_events: ["spike", "goal"]
      })

      spike_webhooks = Webhooks.webhooks_for_event(site, "spike")
      goal_webhooks = Webhooks.webhooks_for_event(site, "goal")

      assert length(spike_webhooks) == 2
      assert length(goal_webhooks) == 2
    end

    test "webhooks_for_event/2 returns empty list when no webhooks have the event", %{site: site} do
      {:ok, _} = Webhooks.create_webhook(site, %{
        url: "https://example.com/webhook",
        secret: "test_secret_key_12345678",
        enabled_events: ["spike"]
      })

      webhooks = Webhooks.webhooks_for_event(site, "goal")

      assert webhooks == []
    end
  end

  describe "goal_payload/2" do
    test "generates correct goal event payload" do
      site = %{id: 1, domain: "example.com"}
      goal = %{id: 42, display_name: "Signup"}

      payload = Webhooks.goal_payload(site, goal)

      assert payload.event_type == "goal"
      assert payload.site_id == 1
      assert payload.site_domain == "example.com"
      assert payload.goal_id == 42
      assert payload.goal_name == "Signup"
      assert payload.count == 1
      assert is_binary(payload.timestamp)
    end

    test "generates payload with custom count" do
      site = %{id: 1, domain: "example.com"}
      goal = %{id: 42, display_name: "Purchase"}

      payload = Webhooks.goal_payload(site, goal, 5)

      assert payload.count == 5
      assert payload.event_type == "goal"
      assert payload.goal_name == "Purchase"
    end

    test "timestamp is in ISO8601 format" do
      site = %{id: 1, domain: "example.com"}
      goal = %{id: 42, display_name: "Test"}

      payload = Webhooks.goal_payload(site, goal)

      # ISO8601 format matches pattern like "2024-01-15T10:30:00Z"
      assert payload.timestamp =~ ~r/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/
      assert String.ends_with?(payload.timestamp, "Z")
    end
  end

  describe "spike_payload/4" do
    test "generates correct spike event payload" do
      site = %{id: 1, domain: "example.com"}

      payload = Webhooks.spike_payload(site, 150, 100)

      assert payload.event_type == "spike"
      assert payload.site_id == 1
      assert payload.site_domain == "example.com"
      assert payload.current_visitors == 150
      assert payload.threshold == 100
      assert payload.change_type == "spike"
      assert is_binary(payload.timestamp)
    end

    test "spike payload includes sources and pages when provided" do
      site = %{id: 1, domain: "example.com"}
      sources = [%{name: "Google", visitors: 50}]
      pages = [%{path: "/home", visitors: 100}]

      payload = Webhooks.spike_payload(site, 150, 100, sources, pages)

      assert payload.sources == sources
      assert payload.pages == pages
    end

    test "spike payload defaults sources and pages to empty lists" do
      site = %{id: 1, domain: "example.com"}

      payload = Webhooks.spike_payload(site, 150, 100)

      assert payload.sources == []
      assert payload.pages == []
    end

    test "spike payload timestamp is in ISO8601 format" do
      site = %{id: 1, domain: "example.com"}

      payload = Webhooks.spike_payload(site, 150, 100)

      assert payload.timestamp =~ ~r/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/
      assert String.ends_with?(payload.timestamp, "Z")
    end

    test "spike payload matches contract format" do
      site = %{id: "abc123def456", domain: "example.com"}
      sources = [
        %{name: "Twitter", visitors: 80},
        %{name: "Google", visitors: 40}
      ]
      pages = [%{path: "/blog/viral-post", visitors: 60}]

      payload = Webhooks.spike_payload(site, 150, 100, sources, pages)

      # Verify all contract fields are present
      assert payload.event_type == "spike"
      assert payload.site_id == "abc123def456"
      assert payload.site_domain == "example.com"
      assert payload.current_visitors == 150
      assert payload.threshold == 100
      assert payload.change_type == "spike"
      assert length(payload.sources) == 2
      assert length(payload.pages) == 1
      assert is_binary(payload.timestamp)
    end
  end

  describe "drop_payload/3" do
    test "generates correct drop event payload" do
      site = %{id: 1, domain: "example.com"}

      payload = Webhooks.drop_payload(site, 25, 50)

      assert payload.event_type == "drop"
      assert payload.site_id == 1
      assert payload.site_domain == "example.com"
      assert payload.current_visitors == 25
      assert payload.threshold == 50
      assert payload.change_type == "drop"
      assert is_binary(payload.timestamp)
    end
  end
end
