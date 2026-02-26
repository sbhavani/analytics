defmodule Plausible.WebhooksTest do
  use Plausible.DataCase, async: true
  alias Plausible.Webhooks
  alias Plausible.Webhooks.Webhook

  describe "create_webhook/2" do
    test "creates a webhook with valid HTTPS URL" do
      site = insert(:site)

      {:ok, webhook} = Webhooks.create_webhook(site, %{
        url: "https://example.com/webhook",
        triggers: ["goal.completed"]
      })

      assert webhook.site_id == site.id
      assert webhook.url == "https://example.com/webhook"
      assert webhook.triggers == ["goal.completed"]
      assert webhook.active == true
      assert webhook.secret != nil
    end

    test "creates webhook with multiple triggers" do
      site = insert(:site)

      {:ok, webhook} = Webhooks.create_webhook(site, %{
        url: "https://example.com/webhook",
        triggers: ["goal.completed", "visitor.spike"]
      })

      assert webhook.triggers == ["goal.completed", "visitor.spike"]
    end

    test "generates secret if not provided" do
      site = insert(:site)

      {:ok, webhook} = Webhooks.create_webhook(site, %{
        url: "https://example.com/webhook",
        triggers: ["goal.completed"]
      })

      assert webhook.secret != nil
      assert byte_size(webhook.secret) > 0
    end

    test "fails with HTTP URL" do
      site = insert(:site)

      {:error, changeset} = Webhooks.create_webhook(site, %{
        url: "http://example.com/webhook",
        triggers: ["goal.completed"]
      })

      assert "must be a valid HTTPS URL" in errors_on(changeset).url
    end

    test "fails with invalid URL" do
      site = insert(:site)

      {:error, changeset} = Webhooks.create_webhook(site, %{
        url: "not-a-url",
        triggers: ["goal.completed"]
      })

      assert "must be a valid HTTPS URL" in errors_on(changeset).url
    end

    test "fails with empty triggers" do
      site = insert(:site)

      {:error, changeset} = Webhooks.create_webhook(site, %{
        url: "https://example.com/webhook",
        triggers: []
      })

      assert "must select at least one trigger" in errors_on(changeset).triggers
    end

    test "fails with invalid trigger" do
      site = insert(:site)

      {:error, changeset} = Webhooks.create_webhook(site, %{
        url: "https://example.com/webhook",
        triggers: ["invalid.trigger"]
      })

      assert "contains invalid triggers: invalid.trigger" in errors_on(changeset).triggers
    end

    test "fails when webhook limit is reached" do
      site = insert(:site)

      # Create 10 webhooks to reach the limit
      for i <- 1..10 do
        {:ok, _} = Webhooks.create_webhook(site, %{
          url: "https://example.com/webhook#{i}",
          triggers: ["goal.completed"]
        })
      end

      {:error, :webhook_limit_reached} = Webhooks.create_webhook(site, %{
        url: "https://example.com/webhook11",
        triggers: ["goal.completed"]
      })
    end
  end

  describe "update_webhook/2" do
    test "updates webhook URL" do
      site = insert(:site)
      {:ok, webhook} = Webhooks.create_webhook(site, %{
        url: "https://example.com/webhook",
        triggers: ["goal.completed"]
      })

      {:ok, updated} = Webhooks.update_webhook(webhook, %{
        url: "https://example.com/new-webhook"
      })

      assert updated.url == "https://example.com/new-webhook"
    end

    test "updates webhook triggers" do
      site = insert(:site)
      {:ok, webhook} = Webhooks.create_webhook(site, %{
        url: "https://example.com/webhook",
        triggers: ["goal.completed"]
      })

      {:ok, updated} = Webhooks.update_webhook(webhook, %{
        triggers: ["goal.completed", "visitor.spike"]
      })

      assert updated.triggers == ["goal.completed", "visitor.spike"]
    end

    test "updates webhook active status" do
      site = insert(:site)
      {:ok, webhook} = Webhooks.create_webhook(site, %{
        url: "https://example.com/webhook",
        triggers: ["goal.completed"]
      })

      {:ok, updated} = Webhooks.update_webhook(webhook, %{
        active: false
      })

      assert updated.active == false
    end
  end

  describe "delete_webhook/1" do
    test "deletes webhook" do
      site = insert(:site)
      {:ok, webhook} = Webhooks.create_webhook(site, %{
        url: "https://example.com/webhook",
        triggers: ["goal.completed"]
      })

      {:ok, deleted} = Webhooks.delete_webhook(webhook)

      assert deleted.id == webhook.id
      assert Webhooks.get_webhook(webhook.id) == nil
    end
  end

  describe "get_webhooks_for_trigger/2" do
    test "returns webhooks with matching trigger" do
      site = insert(:site)

      {:ok, _} = Webhooks.create_webhook(site, %{
        url: "https://example.com/webhook1",
        triggers: ["goal.completed"]
      })

      {:ok, _} = Webhooks.create_webhook(site, %{
        url: "https://example.com/webhook2",
        triggers: ["visitor.spike"]
      })

      webhooks = Webhooks.get_webhooks_for_trigger(site.id, "goal.completed")
      assert length(webhooks) == 1
      assert hd(webhooks).url == "https://example.com/webhook1"
    end

    test "does not return inactive webhooks" do
      site = insert(:site)

      {:ok, webhook} = Webhooks.create_webhook(site, %{
        url: "https://example.com/webhook",
        triggers: ["goal.completed"]
      })

      {:ok, _} = Webhooks.update_webhook(webhook, %{active: false})

      webhooks = Webhooks.get_webhooks_for_trigger(site.id, "goal.completed")
      assert Enum.empty?(webhooks)
    end
  end

  describe "get_site_with_webhook/2" do
    test "returns webhook when it belongs to site" do
      site = insert(:site)
      {:ok, webhook} = Webhooks.create_webhook(site, %{
        url: "https://example.com/webhook",
        triggers: ["goal.completed"]
      })

      result = Webhooks.get_site_with_webhook(webhook.id, site.id)
      assert result.id == webhook.id
    end

    test "returns nil when webhook does not belong to site" do
      site1 = insert(:site)
      site2 = insert(:site)
      {:ok, webhook} = Webhooks.create_webhook(site1, %{
        url: "https://example.com/webhook",
        triggers: ["goal.completed"]
      })

      result = Webhooks.get_site_with_webhook(webhook.id, site2.id)
      assert result == nil
    end

    test "returns nil when webhook does not exist" do
      site = insert(:site)
      result = Webhooks.get_site_with_webhook(UUID.uuid4(), site.id)
      assert result == nil
    end
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
