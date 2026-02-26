defmodule Plausible.Site.WebhookTest do
  use Plausible.DataCase, async: true

  alias Plausible.Site.Webhook

  # Helper function to extract errors from a changeset as a map
  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  describe "changeset/2" do
    test "creates a valid webhook with all required fields" do
      site = insert(:site)

      attrs = %{
        site_id: site.id,
        url: "https://example.com/webhook",
        secret: "a_very_long_secret_key_123",
        name: "My Webhook"
      }

      changeset = Webhook.changeset(%Webhook{}, attrs)

      assert changeset.valid?
      assert get_change(changeset, :url) == "https://example.com/webhook"
      assert get_change(changeset, :secret) == "a_very_long_secret_key_123"
      assert get_change(changeset, :name) == "My Webhook"
      assert get_change(changeset, :enabled) == true
    end

    test "creates a disabled webhook when enabled is set to false" do
      site = insert(:site)

      attrs = %{
        site_id: site.id,
        url: "https://example.com/webhook",
        secret: "a_very_long_secret_key_123",
        name: "My Webhook",
        enabled: false
      }

      changeset = Webhook.changeset(%Webhook{}, attrs)

      assert changeset.valid?
      assert get_change(changeset, :enabled) == false
    end

    test "requires site_id" do
      attrs = %{
        url: "https://example.com/webhook",
        secret: "a_very_long_secret_key_123",
        name: "My Webhook"
      }

      changeset = Webhook.changeset(%Webhook{}, attrs)

      refute changeset.valid?
      assert %{site_id: ["can't be blank"]} = errors_on(changeset)
    end

    test "requires url" do
      site = insert(:site)

      attrs = %{
        site_id: site.id,
        secret: "a_very_long_secret_key_123",
        name: "My Webhook"
      }

      changeset = Webhook.changeset(%Webhook{}, attrs)

      refute changeset.valid?
      assert %{url: ["can't be blank"]} = errors_on(changeset)
    end

    test "requires secret" do
      site = insert(:site)

      attrs = %{
        site_id: site.id,
        url: "https://example.com/webhook",
        name: "My Webhook"
      }

      changeset = Webhook.changeset(%Webhook{}, attrs)

      refute changeset.valid?
      assert %{secret: ["can't be blank"]} = errors_on(changeset)
    end

    test "requires name" do
      site = insert(:site)

      attrs = %{
        site_id: site.id,
        url: "https://example.com/webhook",
        secret: "a_very_long_secret_key_123"
      }

      changeset = Webhook.changeset(%Webhook{}, attrs)

      refute changeset.valid?
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates url uses HTTPS" do
      site = insert(:site)

      attrs = %{
        site_id: site.id,
        url: "http://example.com/webhook",
        secret: "a_very_long_secret_key_123",
        name: "My Webhook"
      }

      changeset = Webhook.changeset(%Webhook{}, attrs)

      refute changeset.valid?
      assert %{url: ["must use HTTPS"]} = errors_on(changeset)
    end

    test "validates url is a valid URL" do
      site = insert(:site)

      attrs = %{
        site_id: site.id,
        url: "not-a-url",
        secret: "a_very_long_secret_key_123",
        name: "My Webhook"
      }

      changeset = Webhook.changeset(%Webhook{}, attrs)

      refute changeset.valid?
      assert %{url: ["must be a valid URL"]} = errors_on(changeset)
    end

    test "validates secret is at least 16 characters" do
      site = insert(:site)

      attrs = %{
        site_id: site.id,
        url: "https://example.com/webhook",
        secret: "short",
        name: "My Webhook"
      }

      changeset = Webhook.changeset(%Webhook{}, attrs)

      refute changeset.valid?
      assert %{secret: ["must be at least 16 characters"]} = errors_on(changeset)
    end

    test "validates secret exactly at 16 characters passes" do
      site = insert(:site)

      attrs = %{
        site_id: site.id,
        url: "https://example.com/webhook",
        secret: "1234567890123456",
        name: "My Webhook"
      }

      changeset = Webhook.changeset(%Webhook{}, attrs)

      assert changeset.valid?
    end

    test "validates name is at most 255 characters" do
      site = insert(:site)

      attrs = %{
        site_id: site.id,
        url: "https://example.com/webhook",
        secret: "a_very_long_secret_key_123",
        name: String.duplicate("a", 256)
      }

      changeset = Webhook.changeset(%Webhook{}, attrs)

      refute changeset.valid?
      assert %{name: ["should be at most 255 character(s)"]} = errors_on(changeset)
    end
  end

  describe "toggle_enabled/1" do
    test "toggles enabled from true to false" do
      site = insert(:site)

      webhook = %Webhook{
        site_id: site.id,
        url: "https://example.com/webhook",
        secret: "a_very_long_secret_key_123",
        name: "My Webhook",
        enabled: true
      }

      toggled = Webhook.toggle_enabled(webhook)

      assert toggled.enabled == false
    end

    test "toggles enabled from false to true" do
      site = insert(:site)

      webhook = %Webhook{
        site_id: site.id,
        url: "https://example.com/webhook",
        secret: "a_very_long_secret_key_123",
        name: "My Webhook",
        enabled: false
      }

      toggled = Webhook.toggle_enabled(webhook)

      assert toggled.enabled == true
    end
  end

  describe "associations" do
    test "webhook belongs to a site" do
      site = insert(:site)

      attrs = %{
        site_id: site.id,
        url: "https://example.com/webhook",
        secret: "a_very_long_secret_key_123",
        name: "My Webhook"
      }

      changeset = Webhook.changeset(%Webhook{}, attrs)

      assert changeset.data.site_id == site.id
    end
  end
end
