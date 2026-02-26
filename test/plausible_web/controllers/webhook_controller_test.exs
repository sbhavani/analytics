defmodule PlausibleWeb.WebhookControllerTest do
  use PlausibleWeb.ConnCase, async: false
  use Plausible.Repo
  use Oban.Testing, repo: Plausible.Repo

  alias Plausible.Webhooks

  describe "GET /api/:domain/webhooks" do
    setup [:create_user, :log_in, :create_site]

    test "returns empty list when no webhooks exist", %{conn: conn, site: site} do
      conn = get(conn, "/api/#{site.domain}/webhooks")

      assert %{"webhooks" => []} = json_response(conn, 200)
    end

    test "returns list of webhooks", %{conn: conn, site: site, user: _user} do
      {:ok, _webhook} = Webhooks.create_webhook(site, %{
        url: "https://example.com/webhook",
        trigger_types: ["visitor_spike"]
      })

      conn = get(conn, "/api/#{site.domain}/webhooks")

      assert %{"webhooks" => [webhook]} = json_response(conn, 200)
      assert webhook["url"] == "https://example.com/webhook"
      assert webhook["trigger_types"] == ["visitor_spike"]
    end
  end

  describe "POST /api/:domain/webhooks" do
    setup [:create_user, :log_in, :create_site]

    test "creates a webhook with valid data", %{conn: conn, site: site} do
      conn = post(conn, "/api/#{site.domain}/webhooks", %{
        webhook: %{
          url: "https://example.com/webhook",
          trigger_types: ["visitor_spike"]
        }
      })

      assert json_response(conn, 201)["url"] == "https://example.com/webhook"
    end

    test "rejects HTTP URLs", %{conn: conn, site: site} do
      conn = post(conn, "/api/#{site.domain}/webhooks", %{
        webhook: %{
          url: "http://example.com/webhook",
          trigger_types: ["visitor_spike"]
        }
      })

      assert json_response(conn, 422)
    end

    test "rejects invalid trigger types", %{conn: conn, site: site} do
      conn = post(conn, "/api/#{site.domain}/webhooks", %{
        webhook: %{
          url: "https://example.com/webhook",
          trigger_types: ["invalid"]
        }
      })

      assert json_response(conn, 422)
    end
  end

  describe "PUT /api/:domain/webhooks/:id" do
    setup [:create_user, :log_in, :create_site]

    test "updates a webhook", %{conn: conn, site: site} do
      {:ok, webhook} = Webhooks.create_webhook(site, %{
        url: "https://example.com/webhook",
        trigger_types: ["visitor_spike"]
      })

      conn = put(conn, "/api/#{site.domain}/webhooks/#{webhook.id}", %{
        webhook: %{
          url: "https://example.com/updated"
        }
      })

      assert json_response(conn, 200)["url"] == "https://example.com/updated"
    end
  end

  describe "DELETE /api/:domain/webhooks/:id" do
    setup [:create_user, :log_in, :create_site]

    test "deletes a webhook", %{conn: conn, site: site} do
      {:ok, webhook} = Webhooks.create_webhook(site, %{
        url: "https://example.com/webhook",
        trigger_types: ["visitor_spike"]
      })

      conn = delete(conn, "/api/#{site.domain}/webhooks/#{webhook.id}")

      assert response(conn, 204)

      assert_raise Ecto.NoResultsError, fn ->
        Webhooks.get_webhook!(webhook.id)
      end
    end
  end
end
