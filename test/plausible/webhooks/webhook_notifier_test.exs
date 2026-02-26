defmodule Plausible.Webhooks.WebhookNotifierTest do
  use Plausible.DataCase, async: true
  alias Plausible.Webhooks.WebhookNotifier

  describe "generate_signature/2" do
    test "generates HMAC-SHA256 signature" do
      payload = ~s({"event":"goal.completed","site_id":"abc123"})
      secret = "test-secret"

      signature = WebhookNotifier.generate_signature(payload, secret)

      assert is_binary(signature)
      assert byte_size(signature) == 64 # SHA256 hex = 64 chars
    end

    test "generates consistent signature for same input" do
      payload = ~s({"event":"goal.completed"})
      secret = "test-secret"

      sig1 = WebhookNotifier.generate_signature(payload, secret)
      sig2 = WebhookNotifier.generate_signature(payload, secret)

      assert sig1 == sig2
    end

    test "generates different signature for different secrets" do
      payload = ~s({"event":"goal.completed"})

      sig1 = WebhookNotifier.generate_signature(payload, "secret1")
      sig2 = WebhookNotifier.generate_signature(payload, "secret2")

      assert sig1 != sig2
    end

    test "generates different signature for different payloads" do
      secret = "test-secret"

      sig1 = WebhookNotifier.generate_signature(~s({"event":"a"}), secret)
      sig2 = WebhookNotifier.generate_signature(~s({"event":"b"}), secret)

      assert sig1 != sig2
    end
  end

  describe "build_payload/3" do
    test "builds goal.completed payload" do
      webhook = %{site_id: "site-123"}

      payload = WebhookNotifier.build_payload(webhook, "goal.completed", %{
        goal_id: "signup",
        goal_name: "Sign Up",
        visitor_id: "visitor-456",
        count: 1,
        revenue: nil
      })

      assert payload.event == "goal.completed"
      assert payload.site_id == "site-123"
      assert payload.data.goal_id == "signup"
      assert payload.data.goal_name == "Sign Up"
      assert payload.data.visitor_id == "visitor-456"
      assert payload.data.count == 1
      assert payload.timestamp != nil
    end

    test "builds visitor.spike payload" do
      webhook = %{site_id: "site-123"}

      payload = WebhookNotifier.build_payload(webhook, "visitor.spike", %{
        current_visitors: 1500,
        threshold: 1000,
        increase_percentage: 50,
        window_minutes: 15
      })

      assert payload.event == "visitor.spike"
      assert payload.site_id == "site-123"
      assert payload.data.current_visitors == 1500
      assert payload.data.threshold == 1000
      assert payload.data.increase_percentage == 50
      assert payload.data.window_minutes == 15
    end
  end

  describe "build_test_payload/1" do
    test "builds test payload" do
      webhook = %{site_id: "site-123"}

      payload = WebhookNotifier.build_test_payload(webhook)

      assert payload.event == "webhook.test"
      assert payload.site_id == "site-123"
      assert payload.data.message == "This is a test webhook from Plausible Analytics"
      assert payload.timestamp != nil
    end
  end
end
