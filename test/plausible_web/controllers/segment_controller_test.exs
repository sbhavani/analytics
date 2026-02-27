defmodule PlausibleWeb.SegmentControllerTest do
  use PlausibleWeb.ConnCase
  use Plausible.IngestionCase

  alias Plausible.Segments
  alias Plausible.Segments.Segment

  @valid_segment_attrs %{
    "name" => "Test Segment",
    "segment_data" => %{
      "filters" => [["is", "visit:country", ["US"]]],
      "labels" => %{}
    },
    "type" => "personal"
  }

  describe "segment creation" do
    setup [:create_user, :create_site]

    test "creates a new segment", %{conn: conn, site: site, user: user} do
      conn =
        conn
        |> put_session(:user_id, user.id)
        |> get("/#{site.domain}")

      response =
        conn
        |> post("/api/sites/#{site.domain}/segments", @valid_segment_attrs)

      assert response.status == 200
      data = json_response(response, 200)
      assert data["name"] == "Test Segment"
    end
  end

  describe "segment listing" do
    setup [:create_user, :create_site]

    test "lists segments for a site", %{conn: conn, site: site, user: user} do
      # Create a segment first
      {:ok, _segment} =
        Segments.insert_one(user.id, site, :admin, %{
          "name" => "Test Segment",
          "segment_data" => %{"filters" => [["is", "visit:country", ["US"]]], "labels" => %{}},
          "type" => "personal"
        })

      conn =
        conn
        |> put_session(:user_id, user.id)
        |> get("/#{site.domain}")

      response =
        conn
        |> get("/api/sites/#{site.domain}/segments")

      assert response.status == 200
      data = json_response(response, 200)
      assert length(data["segments"]) == 1
    end
  end

  describe "segment preview" do
    setup [:create_user, :create_site]

    test "previews a segment with filter_tree", %{conn: conn, site: site, user: user} do
      conn =
        conn
        |> put_session(:user_id, user.id)
        |> get("/#{site.domain}")

      filter_tree = %{
        "version" => 1,
        "root" => %{
          "id" => "root-1",
          "type" => "group",
          "operator" => "and",
          "children" => [
            %{
              "id" => "cond-1",
              "type" => "condition",
              "attribute" => "visit:country",
              "operator" => "is",
              "value" => "US",
              "negated" => false
            }
          ]
        }
      }

      response =
        conn
        |> post("/api/sites/#{site.domain}/segments/preview", %{
          "filter_tree" => filter_tree
        })

      assert response.status == 200
      data = json_response(response, 200)
      assert data["totals"]["visitors"] == 0
    end

    test "returns error for invalid filter_tree", %{conn: conn, site: site, user: user} do
      conn =
        conn
        |> put_session(:user_id, user.id)
        |> get("/#{site.domain}")

      invalid_tree = %{
        "version" => 1,
        "root" => %{
          "id" => "root-1",
          "type" => "group",
          "operator" => "and",
          "children" => []
        }
      }

      response =
        conn
        |> post("/api/sites/#{site.domain}/segments/preview", %{
          "filter_tree" => invalid_tree
        })

      assert response.status == 400
    end
  end
end
