defmodule PlausibleWeb.Api.WebhookControllerTest do
  @moduledoc """
  Tests for Webhook API endpoints.
  """
  use PlausibleWeb.ConnCase
  use Plausible.Repo

  on_ee do
    setup :create_user

    setup %{conn: conn, user: user} do
      api_key = insert(:api_key, user: user, scopes: ["sites:provision:*"])
      conn = Plug.Conn.put_req_header(conn, "authorization", "Bearer #{api_key.key}")
      {:ok, api_key: api_key, conn: conn}
    end

    describe "GET /api/v1/sites/:site_id/webhooks" do
      setup %{user: user} do
        site = insert(:site, members: [user])
        {:ok, site: site}
      end

      test "returns empty list when no webhooks exist", %{conn: conn, site: site} do
        conn = get(conn, "/api/v1/sites/#{site.domain}/webhooks")

        response = json_response(conn, 200)
        assert response["webhooks"] == []
      end

      test "returns webhooks for site", %{conn: conn, site: site} do
        webhook = insert(:webhook, site: site, url: "https://example.com/hook")

        conn = get(conn, "/api/v1/sites/#{site.domain}/webhooks")

        response = json_response(conn, 200)
        assert length(response["webhooks"]) == 1
        assert hd(response["webhooks"])["url"] == "https://example.com/hook"
      end
    end

    describe "POST /api/v1/sites/:site_id/webhooks" do
      setup %{user: user} do
        site = insert(:site, members: [user])
        {:ok, site: site}
      end

      test "creates webhook with valid URL", %{conn: conn, site: site} do
        conn =
          post(conn, "/api/v1/sites/#{site.domain}/webhooks", %{
            "url" => "https://example.com/webhook",
            "triggers" => ["goal.completed"]
          })

        response = json_response(conn, 201)
        assert response["url"] == "https://example.com/webhook"
        assert response["triggers"] == ["goal.completed"]
        assert response["active"] == true
        assert response["id"] != nil
      end

      test "fails with HTTP URL", %{conn: conn, site: site} do
        conn =
          post(conn, "/api/v1/sites/#{site.domain}/webhooks", %{
            "url" => "http://example.com/webhook",
            "triggers" => ["goal.completed"]
          })

        assert json_response(conn, 422)
      end

      test "fails without triggers", %{conn: conn, site: site} do
        conn =
          post(conn, "/api/v1/sites/#{site.domain}/webhooks", %{
            "url" => "https://example.com/webhook"
          })

        assert json_response(conn, 422)
      end
    end

    describe "GET /api/v1/sites/:site_id/webhooks/:webhook_id" do
      setup %{user: user} do
        site = insert(:site, members: [user])
        webhook = insert(:webhook, site: site, url: "https://example.com/hook")
        {:ok, site: site, webhook: webhook}
      end

      test "returns webhook by id", %{conn: conn, site: site, webhook: webhook} do
        conn = get(conn, "/api/v1/sites/#{site.domain}/webhooks/#{webhook.id}")

        response = json_response(conn, 200)
        assert response["url"] == "https://example.com/hook"
      end

      test "returns 404 for non-existent webhook", %{conn: conn, site: site} do
        conn = get(conn, "/api/v1/sites/#{site.domain}/webhooks/#{UUID.uuid4()}")

        assert json_response(conn, 404)
      end
    end

    describe "PATCH /api/v1/sites/:site_id/webhooks/:webhook_id" do
      setup %{user: user} do
        site = insert(:site, members: [user])
        webhook = insert(:webhook, site: site, url: "https://example.com/hook")
        {:ok, site: site, webhook: webhook}
      end

      test "updates webhook URL", %{conn: conn, site: site, webhook: webhook} do
        conn =
          patch(conn, "/api/v1/sites/#{site.domain}/webhooks/#{webhook.id}", %{
            "url" => "https://example.com/new-hook"
          })

        response = json_response(conn, 200)
        assert response["url"] == "https://example.com/new-hook"
      end

      test "updates webhook active status", %{conn: conn, site: site, webhook: webhook} do
        conn =
          patch(conn, "/api/v1/sites/#{site.domain}/webhooks/#{webhook.id}", %{
            "active" => false
          })

        response = json_response(conn, 200)
        assert response["active"] == false
      end
    end

    describe "DELETE /api/v1/sites/:site_id/webhooks/:webhook_id" do
      setup %{user: user} do
        site = insert(:site, members: [user])
        webhook = insert(:webhook, site: site)
        {:ok, site: site, webhook: webhook}
      end

      test "deletes webhook", %{conn: conn, site: site, webhook: webhook} do
        conn = delete(conn, "/api/v1/sites/#{site.domain}/webhooks/#{webhook.id}")

        assert response(conn, 204)
      end

      test "returns 404 for non-existent webhook", %{conn: conn, site: site} do
        conn = delete(conn, "/api/v1/sites/#{site.domain}/webhooks/#{UUID.uuid4()}")

        assert json_response(conn, 404)
      end
    end
  end
end
