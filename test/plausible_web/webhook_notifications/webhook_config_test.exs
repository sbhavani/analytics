defmodule Plausible.WebhookNotifications.WebhookConfigTest do
  use Plausible.DataCase, async: false

  alias Plausible.WebhookNotifications.WebhookConfig

  describe "changeset/2" do
    test "creates valid changeset with valid HTTPS URL" do
      site = build(:site)

      attrs = %{
        endpoint_url: "https://example.com/webhook",
        secret: "test_secret_key_12345",
        is_active: true
      }

      changeset = WebhookConfig.changeset(Ecto.build_assoc(site, :webhook_configs), attrs)

      assert changeset.valid?
      assert changeset.changes.endpoint_url == "https://example.com/webhook"
      assert changeset.changes.is_active == true
    end

    test "generates secret hash on creation" do
      site = build(:site)

      attrs = %{
        endpoint_url: "https://example.com/webhook",
        secret: "my_secret_key_123",
        is_active: true
      }

      changeset = WebhookConfig.changeset(Ecto.build_assoc(site, :webhook_configs), attrs)

      assert changeset.valid?
      # The secret should be hashed (base64 encoded SHA256)
      assert changeset.changes.secret != "my_secret_key_123"
      assert is_binary(changeset.changes.secret)
    end

    test "requires endpoint_url" do
      site = build(:site)

      attrs = %{
        secret: "test_secret_key_12345"
      }

      changeset = WebhookConfig.changeset(Ecto.build_assoc(site, :webhook_configs), attrs)

      refute changeset.valid?
      assert {:endpoint_url, {"can't be blank", _}} = List.keyfind(changeset.errors, :endpoint_url, 0)
    end

    test "requires secret" do
      site = build(:site)

      attrs = %{
        endpoint_url: "https://example.com/webhook"
      }

      changeset = WebhookConfig.changeset(Ecto.build_assoc(site, :webhook_configs), attrs)

      refute changeset.valid?
      assert {:secret, {"can't be blank", _}} = List.keyfind(changeset.errors, :secret, 0)
    end

    test "validates endpoint_url format - must be HTTPS" do
      site = build(:site)

      attrs = %{
        endpoint_url: "http://example.com/webhook",
        secret: "test_secret_key_12345"
      }

      changeset = WebhookConfig.changeset(Ecto.build_assoc(site, :webhook_configs), attrs)

      refute changeset.valid?
      assert {:endpoint_url, {"must be a valid HTTPS URL", _}} = List.keyfind(changeset.errors, :endpoint_url, 0)
    end

    test "validates endpoint_url is a valid URL" do
      site = build(:site)

      attrs = %{
        endpoint_url: "not-a-url",
        secret: "test_secret_key_12345"
      }

      changeset = WebhookConfig.changeset(Ecto.build_assoc(site, :webhook_configs), attrs)

      refute changeset.valid?
      assert {:endpoint_url, {"must be a valid HTTPS URL", _}} = List.keyfind(changeset.errors, :endpoint_url, 0)
    end

    test "validates secret minimum length" do
      site = build(:site)

      attrs = %{
        endpoint_url: "https://example.com/webhook",
        secret: "short"
      }

      changeset = WebhookConfig.changeset(Ecto.build_assoc(site, :webhook_configs), attrs)

      refute changeset.valid?
      assert {:secret, {"should be at least %{count} character(s)", _}} = List.keyfind(changeset.errors, :secret, 0)
    end

    test "validates endpoint_url maximum length" do
      site = build(:site)
      long_url = "https://example.com/" <> String.duplicate("a", 500)

      attrs = %{
        endpoint_url: long_url,
        secret: "test_secret_key_12345"
      }

      changeset = WebhookConfig.changeset(Ecto.build_assoc(site, :webhook_configs), attrs)

      refute changeset.valid?
      assert {:endpoint_url, {"should be at most %{count} character(s)", _}} = List.keyfind(changeset.errors, :endpoint_url, 0)
    end
  end
end
