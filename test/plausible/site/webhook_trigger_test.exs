defmodule Plausible.Site.WebhookTriggerTest do
  use Plausible.DataCase, async: false

  alias Plausible.Site.WebhookTrigger

  describe "changeset/2" do
    test "validates required fields: webhook_id and trigger_type" do
      changeset = WebhookTrigger.changeset(%WebhookTrigger{}, %{})

      refute changeset.valid?

      assert {"can't be blank", _} = changeset.errors[:webhook_id]
      assert {"can't be blank", _} = changeset.errors[:trigger_type]
    end

    test "validates trigger_type is one of allowed values" do
      webhook = insert(:webhook)

      attrs = %{
        webhook_id: webhook.id,
        trigger_type: "invalid_type"
      }

      changeset = WebhookTrigger.changeset(%WebhookTrigger{}, attrs)

      refute changeset.valid?
      assert {"is invalid", _} = changeset.errors[:trigger_type]
    end

    test "valid visitor_spike trigger with threshold" do
      webhook = insert(:webhook)

      attrs = %{
        webhook_id: webhook.id,
        trigger_type: "visitor_spike",
        threshold: 100
      }

      changeset = WebhookTrigger.changeset(%WebhookTrigger{}, attrs)

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :trigger_type) == "visitor_spike"
      assert Ecto.Changeset.get_field(changeset, :threshold) == 100
    end

    test "valid goal_completion trigger with goal_id" do
      webhook = insert(:webhook)
      goal = insert(:goal)

      attrs = %{
        webhook_id: webhook.id,
        trigger_type: "goal_completion",
        goal_id: goal.id
      }

      changeset = WebhookTrigger.changeset(%WebhookTrigger{}, attrs)

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :trigger_type) == "goal_completion"
      assert Ecto.Changeset.get_field(changeset, :goal_id) == goal.id
    end

    test "visitor_spike requires threshold" do
      webhook = insert(:webhook)

      attrs = %{
        webhook_id: webhook.id,
        trigger_type: "visitor_spike"
      }

      changeset = WebhookTrigger.changeset(%WebhookTrigger{}, attrs)

      refute changeset.valid?
      assert {"can't be blank", _} = changeset.errors[:threshold]
    end

    test "goal_completion requires goal_id" do
      webhook = insert(:webhook)

      attrs = %{
        webhook_id: webhook.id,
        trigger_type: "goal_completion"
      }

      changeset = WebhookTrigger.changeset(%WebhookTrigger{}, attrs)

      refute changeset.valid?
      assert {"can't be blank", _} = changeset.errors[:goal_id]
    end

    test "threshold must be greater than 0" do
      webhook = insert(:webhook)

      attrs = %{
        webhook_id: webhook.id,
        trigger_type: "visitor_spike",
        threshold: 0
      }

      changeset = WebhookTrigger.changeset(%WebhookTrigger{}, attrs)

      refute changeset.valid?
      assert {"must be greater than 0", _} = changeset.errors[:threshold]
    end
  end

  describe "visitor_spike_changeset/2" do
    test "creates valid changeset with required fields" do
      webhook = insert(:webhook)

      attrs = %{
        webhook_id: webhook.id,
        trigger_type: "visitor_spike",
        threshold: 50
      }

      changeset = WebhookTrigger.visitor_spike_changeset(%WebhookTrigger{}, attrs)

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :trigger_type) == "visitor_spike"
      assert Ecto.Changeset.get_field(changeset, :threshold) == 50
      assert Ecto.Changeset.get_field(changeset, :enabled) == true
    end

    test "requires threshold to be greater than 0" do
      webhook = insert(:webhook)

      attrs = %{
        webhook_id: webhook.id,
        trigger_type: "visitor_spike",
        threshold: -1
      }

      changeset = WebhookTrigger.visitor_spike_changeset(%WebhookTrigger{}, attrs)

      refute changeset.valid?
      assert {"must be greater than 0", _} = changeset.errors[:threshold]
    end

    test "only allows visitor_spike trigger_type" do
      webhook = insert(:webhook)

      attrs = %{
        webhook_id: webhook.id,
        trigger_type: "goal_completion",
        threshold: 50
      }

      changeset = WebhookTrigger.visitor_spike_changeset(%WebhookTrigger{}, attrs)

      refute changeset.valid?
      assert {"is invalid", _} = changeset.errors[:trigger_type]
    end

    test "requires all fields" do
      changeset = WebhookTrigger.visitor_spike_changeset(%WebhookTrigger{}, %{})

      refute changeset.valid?

      assert {"can't be blank", _} = changeset.errors[:webhook_id]
      assert {"can't be blank", _} = changeset.errors[:trigger_type]
      assert {"can't be blank", _} = changeset.errors[:threshold]
    end
  end

  describe "goal_completion_changeset/2" do
    test "creates valid changeset with required fields" do
      webhook = insert(:webhook)
      goal = insert(:goal, event_name: "signup")

      attrs = %{
        webhook_id: webhook.id,
        trigger_type: "goal_completion",
        goal_id: goal.id
      }

      changeset = WebhookTrigger.goal_completion_changeset(%WebhookTrigger{}, attrs)

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :trigger_type) == "goal_completion"
      assert Ecto.Changeset.get_field(changeset, :goal_id) == goal.id
      assert Ecto.Changeset.get_field(changeset, :enabled) == true
    end

    test "only allows goal_completion trigger_type" do
      webhook = insert(:webhook)
      goal = insert(:goal)

      attrs = %{
        webhook_id: webhook.id,
        trigger_type: "visitor_spike",
        goal_id: goal.id
      }

      changeset = WebhookTrigger.goal_completion_changeset(%WebhookTrigger{}, attrs)

      refute changeset.valid?
      assert {"is invalid", _} = changeset.errors[:trigger_type]
    end

    test "requires goal_id" do
      webhook = insert(:webhook)

      attrs = %{
        webhook_id: webhook.id,
        trigger_type: "goal_completion"
      }

      changeset = WebhookTrigger.goal_completion_changeset(%WebhookTrigger{}, attrs)

      refute changeset.valid?
      assert {"can't be blank", _} = changeset.errors[:goal_id]
    end

    test "requires all fields" do
      changeset = WebhookTrigger.goal_completion_changeset(%WebhookTrigger{}, %{})

      refute changeset.valid?

      assert {"can't be blank", _} = changeset.errors[:webhook_id]
      assert {"can't be blank", _} = changeset.errors[:trigger_type]
      assert {"can't be blank", _} = changeset.errors[:goal_id]
    end
  end

  describe "toggle_enabled/1" do
    test "toggles enabled from true to false" do
      webhook = insert(:webhook)

      trigger =
        %WebhookTrigger{
          webhook_id: webhook.id,
          trigger_type: "visitor_spike",
          threshold: 100,
          enabled: true
        }
        |> insert()

      toggled = WebhookTrigger.toggle_enabled(trigger)

      refute Ecto.Changeset.get_change(toggled, :enabled)
    end

    test "toggles enabled from false to true" do
      webhook = insert(:webhook)

      trigger =
        %WebhookTrigger{
          webhook_id: webhook.id,
          trigger_type: "visitor_spike",
          threshold: 100,
          enabled: false
        }
        |> insert()

      toggled = WebhookTrigger.toggle_enabled(trigger)

      assert Ecto.Changeset.get_change(toggled, :enabled)
    end
  end

  describe "CRUD operations" do
    test "can insert a visitor_spike trigger" do
      webhook = insert(:webhook)

      attrs = %{
        webhook_id: webhook.id,
        trigger_type: "visitor_spike",
        threshold: 100,
        enabled: true
      }

      changeset = WebhookTrigger.visitor_spike_changeset(%WebhookTrigger{}, attrs)

      assert {:ok, trigger} = Repo.insert(changeset)

      assert trigger.id
      assert trigger.trigger_type == "visitor_spike"
      assert trigger.threshold == 100
      assert trigger.enabled == true
    end

    test "can insert a goal_completion trigger" do
      webhook = insert(:webhook)
      goal = insert(:goal, event_name: "purchase")

      attrs = %{
        webhook_id: webhook.id,
        trigger_type: "goal_completion",
        goal_id: goal.id,
        enabled: true
      }

      changeset = WebhookTrigger.goal_completion_changeset(%WebhookTrigger{}, attrs)

      assert {:ok, trigger} = Repo.insert(changeset)

      assert trigger.id
      assert trigger.trigger_type == "goal_completion"
      assert trigger.goal_id == goal.id
      assert trigger.enabled == true
    end

    test "can update a trigger" do
      webhook = insert(:webhook)

      trigger =
        %WebhookTrigger{
          webhook_id: webhook.id,
          trigger_type: "visitor_spike",
          threshold: 50,
          enabled: true
        }
        |> insert()

      update_attrs = %{threshold: 200}

      changeset = WebhookTrigger.changeset(trigger, update_attrs)

      assert {:ok, updated} = Repo.update(changeset)

      assert updated.threshold == 200
    end

    test "can delete a trigger" do
      webhook = insert(:webhook)

      trigger =
        %WebhookTrigger{
          webhook_id: webhook.id,
          trigger_type: "visitor_spike",
          threshold: 100,
          enabled: true
        }
        |> insert()

      trigger_id = trigger.id

      assert {:ok, _} = Repo.delete(trigger)

      refute Repo.get(WebhookTrigger, trigger_id)
    end

    test "triggers belong to webhook" do
      webhook = insert(:webhook)

      trigger =
        %WebhookTrigger{
          webhook_id: webhook.id,
          trigger_type: "visitor_spike",
          threshold: 100
        }
        |> insert()

      assert trigger.webhook_id == webhook.id

      loaded = Repo.get(WebhookTrigger, trigger.id) |> Repo.preload(:webhook)
      assert loaded.webhook.id == webhook.id
    end

    test "triggers can be associated with goal" do
      webhook = insert(:webhook)
      goal = insert(:goal, event_name: "signup")

      trigger =
        %WebhookTrigger{
          webhook_id: webhook.id,
          trigger_type: "goal_completion",
          goal_id: goal.id
        }
        |> insert()

      assert trigger.goal_id == goal.id

      loaded = Repo.get(WebhookTrigger, trigger.id) |> Repo.preload(:goal)
      assert loaded.goal.id == goal.id
    end
  end
end
