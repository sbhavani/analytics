defmodule PlausibleGraphql.Types.PageviewTypeTest do
  use ExUnit.Case, async: true

  alias PlausibleGraphql.Types.PageviewType
  alias PlausibleGraphql.Types.PageviewTypes

  describe "Pageview object type" do
    test "defines the expected fields" do
      # Verify that all expected fields are defined on the Pageview type
      # id - unique identifier
      assert_has_field(:id, non_null: true)

      # timestamp - when the pageview occurred
      assert_has_field(:timestamp, non_null: true)

      # url - page URL that was viewed
      assert_has_field(:url, non_null: true)

      # referrer - referring URL (optional)
      assert_has_field(:referrer)

      # browser - browser name
      assert_has_field(:browser)

      # device - device type (desktop/mobile/tablet)
      assert_has_field(:device)

      # country - country code
      assert_has_field(:country)
    end
  end

  describe "PageviewFilter input type" do
    test "defines siteId as required field" do
      # siteId is required on all queries
      input_type = PageviewTypes.pageview_filter()

      assert has_field(input_type, :siteId, non_null: true)
    end

    test "defines optional dateRange field" do
      input_type = PageviewTypes.pageview_filter()

      assert has_field(input_type, :dateRange)
    end

    test "defines optional urlPattern field" do
      input_type = PageviewTypes.pageview_filter()

      assert has_field(input_type, :urlPattern)
    end
  end

  describe "DateRange input type" do
    test "defines required from and to date fields" do
      date_range_type = PageviewTypes.date_range()

      assert has_field(date_range_type, :from, non_null: true)
      assert has_field(date_range_type, :to, non_null: true)
    end
  end

  describe "Pageview serialization" do
    test "correctly serializes pageview map to GraphQL format" do
      pageview = %{
        "id" => "pv_abc123",
        "timestamp" => ~U[2026-01-15T10:30:00Z],
        "url" => "https://example.com/blog/post-1",
        "referrer" => "https://google.com",
        "browser" => "Chrome",
        "device" => "desktop",
        "country" => "US"
      }

      # Verify the serialization produces expected output
      assert PageviewType.serialize(pageview) == %{
               id: "pv_abc123",
               timestamp: ~U[2026-01-15T10:30:00Z],
               url: "https://example.com/blog/post-1",
               referrer: "https://google.com",
               browser: "Chrome",
               device: "desktop",
               country: "US"
             }
    end

    test "handles optional fields as nil when not present" do
      pageview = %{
        "id" => "pv_abc123",
        "timestamp" => ~U[2026-01-15T10:30:00Z],
        "url" => "https://example.com/blog/post-1"
      }

      serialized = PageviewType.serialize(pageview)

      assert serialized.id == "pv_abc123"
      assert serialized.url == "https://example.com/blog/post-1"
      assert serialized.referrer == nil
      assert serialized.browser == nil
      assert serialized.device == nil
      assert serialized.country == nil
    end
  end

  # Helper functions to check field definitions

  defp assert_has_field(field_name, opts \\ []) do
    is_non_null = Keyword.get(opts, :non_null, false)

    # Get all fields from the Pageview type
    fields = Absinthe.Type.object(PageviewType, :pageview).__absinthe_field_map__()

    field_def = Map.get(fields, field_name)

    assert field_def != nil, "Expected field #{field_name} to be defined on Pageview type"

    if is_non_null do
      assert field_def.type |> Absinthe.Type.non_null?() == true,
             "Expected field #{field_name} to be non-null"
    end
  end

  defp has_field(type, field_name, opts \\ []) do
    is_non_null = Keyword.get(opts, :non_null, false)

    case type do
      %{__struct__: module} when module in [Absinthe.Type.InputObjectType, Absinthe.Type.ObjectType] ->
        fields = type |> Map.get(:fields, %{})

        field_def = Map.get(fields, field_name)

        if is_non_null do
          field_def != nil && (field_def.type |> Absinthe.Type.non_null?() == true)
        else
          field_def != nil
        end

      _ ->
        false
    end
  end
end
