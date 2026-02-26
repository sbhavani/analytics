defmodule PlausibleWeb.WebhookNotifications.EventTriggerTest do
  use Plausible.DataCase, async: true
  alias Plausible.WebhookNotifications.EventTrigger

  describe "threshold validation" do
    test "valid trigger without threshold" do
      changeset =
        EventTrigger.changeset(%EventTrigger{}, %{
          webhook_config_id: 1,
          trigger_type: "visitor_spike"
        })

      assert changeset.valid?
    end

    test "valid trigger with threshold value and unit" do
      changeset =
        EventTrigger.changeset(%EventTrigger{}, %{
          webhook_config_id: 1,
          trigger_type: "visitor_spike",
          threshold_value: 50,
          threshold_unit: "percentage"
        })

      assert changeset.valid?
      assert changeset.changes.threshold_value == 50
      assert changeset.changes.threshold_unit == "percentage"
    end

    test "valid trigger with absolute threshold unit" do
      changeset =
        EventTrigger.changeset(%EventTrigger{}, %{
          webhook_config_id: 1,
          trigger_type: "visitor_spike",
          threshold_value: 100,
          threshold_unit: "absolute"
        })

      assert changeset.valid?
      assert changeset.changes.threshold_value == 100
      assert changeset.changes.threshold_unit == "absolute"
    end

    test "invalid threshold value - zero" do
      changeset =
        EventTrigger.changeset(%EventTrigger{}, %{
          webhook_config_id: 1,
          trigger_type: "visitor_spike",
          threshold_value: 0,
          threshold_unit: "percentage"
        })

      refute changeset.valid?
      assert Keyword.has_key?(changeset.errors, :threshold_value)
    end

    test "invalid threshold value - negative" do
      changeset =
        EventTrigger.changeset(%EventTrigger{}, %{
          webhook_config_id: 1,
          trigger_type: "visitor_spike",
          threshold_value: -10,
          threshold_unit: "percentage"
        })

      refute changeset.valid?
      assert Keyword.has_key?(changeset.errors, :threshold_value)
    end

    test "invalid threshold unit" do
      changeset =
        EventTrigger.changeset(%EventTrigger{}, %{
          webhook_config_id: 1,
          trigger_type: "visitor_spike",
          threshold_value: 50,
          threshold_unit: "invalid_unit"
        })

      refute changeset.valid?
      assert Keyword.has_key?(changeset.errors, :threshold_unit)
    end

    test "threshold value nil is valid" do
      changeset =
        EventTrigger.changeset(%EventTrigger{}, %{
          webhook_config_id: 1,
          trigger_type: "goal_completion",
          threshold_value: nil,
          threshold_unit: nil
        })

      assert changeset.valid?
    end

    test "threshold_unit can be nil when threshold_value is provided but validation still passes" do
      # The schema allows threshold_unit to be nil even with threshold_value
      changeset =
        EventTrigger.changeset(%EventTrigger{}, %{
          webhook_config_id: 1,
          trigger_type: "visitor_spike",
          threshold_value: 50,
          threshold_unit: nil
        })

      # With allow_nil: true, this should still be valid
      assert changeset.valid?
    end

    test "threshold_value without threshold_unit is valid" do
      changeset =
        EventTrigger.changeset(%EventTrigger{}, %{
          webhook_config_id: 1,
          trigger_type: "visitor_spike",
          threshold_value: 100,
          threshold_unit: nil
        })

      assert changeset.valid?
    end
  end

  describe "trigger_type validation" do
    test "valid trigger types" do
      for trigger_type <- EventTrigger.trigger_types() do
        changeset =
          EventTrigger.changeset(%EventTrigger{}, %{
            webhook_config_id: 1,
            trigger_type: trigger_type
          })

        assert changeset.valid?, "trigger_type #{trigger_type} should be valid"
      end
    end

    test "invalid trigger type" do
      changeset =
        EventTrigger.changeset(%EventTrigger{}, %{
          webhook_config_id: 1,
          trigger_type: "invalid_trigger"
        })

      refute changeset.valid?
      assert Keyword.has_key?(changeset.errors, :trigger_type)
    end
  end

  describe "required fields" do
    test "webhook_config_id is required" do
      changeset =
        EventTrigger.changeset(%EventTrigger{}, %{
          trigger_type: "visitor_spike"
        })

      refute changeset.valid?
      assert Keyword.has_key?(changeset.errors, :webhook_config_id)
    end

    test "trigger_type is required" do
      changeset =
        EventTrigger.changeset(%EventTrigger{}, %{
          webhook_config_id: 1
        })

      refute changeset.valid?
      assert Keyword.has_key?(changeset.errors, :trigger_type)
    end
  end
end
