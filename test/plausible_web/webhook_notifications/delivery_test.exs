defmodule PlausibleWeb.WebhookNotifications.DeliveryTest do
  use PlausibleWeb.ConnCase
  use Plausible.Repo
  alias Plug.Conn
  alias Plausible.WebhookNotifications.{Context, DeliveryLog}

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  defp bypass_url(bypass, opts \\ []) do
    port = bypass.port
    path = Keyword.get(opts, :path, "/")
    "http://localhost:#{port}#{path}"
  end

  describe "webhook delivery HTTP requests" do
    test "delivers webhook successfully on HTTP 200", %{bypass: bypass, site: site} do
      webhook_config = insert(:webhook_config, %{
        site: site,
        endpoint_url: bypass_url(bypass, path: "/webhook"),
        secret: "test_secret_key_12345",
        is_active: true
      })

      delivery_log = insert(:webhook_delivery_log, %{
        webhook_config: webhook_config,
        event_type: "test",
        payload: %{"message" => "test webhook"},
        status: "pending"
      })

      Bypass.expect_once(bypass, "POST", "/webhook", fn conn ->
        conn = Plug.Parsers.call(conn, Plug.Parsers.init(parsers: [:json], json_decoder: Jason))

        assert Conn.get_req_header(conn, "content-type") == ["application/json"]
        assert Conn.get_req_header(conn, "x-webhook-event") == ["test"]

        # Verify signature header is present
        [signature_header] = Conn.get_req_header(conn, "x-webhook-signature")
        assert signature_header =~ "sha256="

        Conn.resp(conn, 200, "OK")
      end)

      # Run the delivery worker
      result = Plausible.Workers.WebhookDeliveryWorker.perform(%Oban.Job{
        args: %{"delivery_log_id" => delivery_log.id}
      })

      assert result == :ok

      # Verify the delivery was marked as successful
      updated_log = Repo.get!(Plausible.WebhookNotifications.DeliveryLog, delivery_log.id)
      assert updated_log.status == "success"
      assert updated_log.response_code == 200
    end

    test "marks delivery as failed on HTTP 4xx", %{bypass: bypass, site: site} do
      webhook_config = insert(:webhook_config, %{
        site: site,
        endpoint_url: bypass_url(bypass, path: "/webhook"),
        secret: "test_secret_key_12345",
        is_active: true
      })

      delivery_log = insert(:webhook_delivery_log, %{
        webhook_config: webhook_config,
        event_type: "goal_completion",
        payload: %{"goal" => "signup", "count" => 1},
        status: "pending"
      })

      Bypass.expect_once(bypass, "POST", "/webhook", fn conn ->
        Conn.resp(conn, 400, "Bad Request")
      end)

      result = Plausible.Workers.WebhookDeliveryWorker.perform(%Oban.Job{
        args: %{"delivery_log_id" => delivery_log.id}
      })

      # 4xx errors are non-retryable
      assert {:cancel, "Permanent failure - HTTP 400"} = result

      # Verify the delivery was marked as failed
      updated_log = Repo.get!(Plausible.WebhookNotifications.DeliveryLog, delivery_log.id)
      assert updated_log.status == "failed"
      assert updated_log.response_code == 400
    end

    test "schedules retry on HTTP 5xx", %{bypass: bypass, site: site} do
      webhook_config = insert(:webhook_config, %{
        site: site,
        endpoint_url: bypass_url(bypass, path: "/webhook"),
        secret: "test_secret_key_12345",
        is_active: true
      })

      delivery_log = insert(:webhook_delivery_log, %{
        webhook_config: webhook_config,
        event_type: "visitor_spike",
        payload: %{"visitors" => 1000},
        status: "pending",
        attempt_number: 1
      })

      Bypass.expect_once(bypass, "POST", "/webhook", fn conn ->
        Conn.resp(conn, 500, "Internal Server Error")
      end)

      result = Plausible.Workers.WebhookDeliveryWorker.perform(%Oban.Job{
        args: %{"delivery_log_id" => delivery_log.id}
      })

      # 5xx errors should trigger retry
      assert {:snooze, _delay} = result

      # Verify the delivery is still pending (not marked as failed since it's retryable)
      updated_log = Repo.get!(Plausible.WebhookNotifications.DeliveryLog, delivery_log.id)
      assert updated_log.status == "pending"
      assert updated_log.attempt_number == 2
    end

    test "handles network errors gracefully", %{bypass: bypass, site: site} do
      webhook_config = insert(:webhook_config, %{
        site: site,
        endpoint_url: bypass_url(bypass, path: "/webhook"),
        secret: "test_secret_key_12345",
        is_active: true
      })

      delivery_log = insert(:webhook_delivery_log, %{
        webhook_config: webhook_config,
        event_type: "test",
        payload: %{"message" => "test"},
        status: "pending"
      })

      # Close the bypass to simulate network error
      Bypass.down(bypass)

      result = Plausible.Workers.WebhookDeliveryWorker.perform(%Oban.Job{
        args: %{"delivery_log_id" => delivery_log.id}
      })

      # Network errors should trigger retry
      assert {:snooze, _delay} = result

      # Verify attempt number was incremented
      updated_log = Repo.get!(Plausible.WebhookNotifications.DeliveryLog, delivery_log.id)
      assert updated_log.attempt_number == 2
    end

    test "cancels webhook when disabled", %{bypass: bypass, site: site} do
      webhook_config = insert(:webhook_config, %{
        site: site,
        endpoint_url: bypass_url(bypass, path: "/webhook"),
        secret: "test_secret_key_12345",
        is_active: false  # Webhook is disabled
      })

      delivery_log = insert(:webhook_delivery_log, %{
        webhook_config: webhook_config,
        event_type: "test",
        payload: %{"message" => "test"},
        status: "pending"
      })

      result = Plausible.Workers.WebhookDeliveryWorker.perform(%Oban.Job{
        args: %{"delivery_log_id" => delivery_log.id}
      })

      assert result == {:cancel, "Webhook is disabled"}
    end

    test "sends correct payload format", %{bypass: bypass, site: site} do
      webhook_config = insert(:webhook_config, %{
        site: site,
        endpoint_url: bypass_url(bypass, path: "/webhook"),
        secret: "test_secret_key_12345",
        is_active: true
      })

      delivery_log = insert(:webhook_delivery_log, %{
        webhook_config: webhook_config,
        event_type: "goal_completion",
        payload: %{
          "event" => "goal_completion",
          "site_id" => site.id,
          "timestamp" => "2024-01-15T10:30:00Z",
          "data" => %{
            "goal_id" => 123,
            "goal_name" => "Signup",
            "count" => 5
          }
        },
        status: "pending"
      })

      Bypass.expect_once(bypass, "POST", "/webhook", fn conn ->
        opts = Plug.Parsers.init(parsers: [:urlencoded, {:json, json_decoder: Jason}])
        conn = Plug.Parsers.call(conn, opts)

        assert conn.body_params["event"] == "goal_completion"
        assert conn.body_params["site_id"] == to_string(site.id)
        assert conn.body_params["data"]["goal_name"] == "Signup"

        Conn.resp(conn, 200, "OK")
      end)

      result = Plausible.Workers.WebhookDeliveryWorker.perform(%Oban.Job{
        args: %{"delivery_log_id" => delivery_log.id}
      })

      assert result == :ok

      updated_log = Repo.get!(Plausible.WebhookNotifications.DeliveryLog, delivery_log.id)
      assert updated_log.status == "success"
    end
  end

  describe "create_delivery_log/3 - delivery log creation on webhook send" do
    test "creates a delivery log entry with pending status" do
      site = new_site()
      webhook = insert(:webhook_config, site: site)

      payload = %{
        event: "test",
        site_id: site.id,
        timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
        data: %{message: "Test webhook"}
      }

      assert {:ok, log} = Context.create_delivery_log(webhook, "test", payload)

      assert log.webhook_config_id == webhook.id
      assert log.event_type == "test"
      assert log.payload == payload
      assert log.status == "pending"
      assert log.attempt_number == 1
      assert log.delivered_at == nil
      assert log.response_code == nil
    end

    test "associates delivery log with the correct webhook config" do
      site = new_site()
      webhook = insert(:webhook_config, site: site)

      payload = %{"event" => "goal_completion", "goal_id" => "123"}

      assert {:ok, log} = Context.create_delivery_log(webhook, "goal_completion", payload)

      # Verify association through preload
      log_with_webhook = Repo.get!(DeliveryLog, log.id) |> Repo.preload(:webhook_config)
      assert log_with_webhook.webhook_config.id == webhook.id
      assert log_with_webhook.webhook_config.endpoint_url == webhook.endpoint_url
    end

    test "stores payload as JSON in the database" do
      site = new_site()
      webhook = insert(:webhook_config, site: site)

      payload = %{
        event: "visitor_spike",
        data: %{
          current_visitors: 150,
          threshold: 100,
          percentage_increase: 50
        }
      }

      assert {:ok, log} = Context.create_delivery_log(webhook, "visitor_spike", payload)

      # Verify the payload is stored correctly
      assert log.payload == payload

      # Verify it can be retrieved from the database as expected
      stored_log = Repo.get!(DeliveryLog, log.id)
      assert stored_log.payload == payload
    end

    test "allows different event types" do
      site = new_site()
      webhook = insert(:webhook_config, site: site)

      event_types = ["test", "goal_completion", "visitor_spike", "custom_event"]

      Enum.each(event_types, fn event_type ->
        payload = %{"type" => event_type}

        assert {:ok, log} = Context.create_delivery_log(webhook, event_type, payload)
        assert log.event_type == event_type
      end)
    end
  end

  describe "test_webhook/1 - creates delivery log when sending test webhook" do
    test "creates a delivery log when sending test webhook" do
      site = new_site()
      webhook = insert(:webhook_config, site: site)

      assert {:ok, log, payload} = Context.test_webhook(webhook)

      assert log.webhook_config_id == webhook.id
      assert log.event_type == "test"
      assert log.status == "pending"
      assert payload.event == "test"
      assert payload.data.message == "This is a test webhook from Plausible Analytics"
    end
  end

  describe "delivery log state transitions" do
    test "marks delivery as success" do
      site = new_site()
      webhook = insert(:webhook_config, site: site)
      {:ok, log} = Context.create_delivery_log(webhook, "test", %{})

      assert {:ok, updated_log} = Context.mark_delivery_success(log, 200, "OK")

      assert updated_log.status == "success"
      assert updated_log.response_code == 200
      assert updated_log.response_body == "OK"
      assert updated_log.delivered_at != nil
    end

    test "marks delivery as failure" do
      site = new_site()
      webhook = insert(:webhook_config, site: site)
      {:ok, log} = Context.create_delivery_log(webhook, "test", %{})

      assert {:ok, updated_log} = Context.mark_delivery_failure(log, 500, "Internal Server Error", 1)

      assert updated_log.status == "failed"
      assert updated_log.response_code == 500
      assert updated_log.response_body == "Internal Server Error"
      assert updated_log.attempt_number == 1
      assert updated_log.delivered_at == nil
    end

    test "increments attempt number on retry" do
      site = new_site()
      webhook = insert(:webhook_config, site: site)
      {:ok, log} = Context.create_delivery_log(webhook, "test", %{})
      {:ok, failed_log} = Context.mark_delivery_failure(log, 500, "Error", 1)

      assert {:ok, retry_log} = Context.retry_delivery(failed_log)

      assert retry_log.status == "pending"
      assert retry_log.attempt_number == 2
      assert retry_log.delivered_at == nil
    end
  end
end
