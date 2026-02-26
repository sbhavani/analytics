defmodule Plausible.Segments.VisitorSegmentTest do
  use ExUnit.Case, async: false
  alias Plausible.Segments.VisitorSegment
  alias Plausible.Segments.FilterGroup
  alias Plausible.Segments.FilterCondition
  import Plausible.Factory
  import Plausible.DataCase

  describe "VisitorSegment.create/3" do
    test "creates a segment with valid attributes" do
      site = insert(:site)
      user = insert(:user)

      attrs = %{
        name: "My Test Segment"
      }

      assert {:ok, segment} = VisitorSegment.create(site, attrs, user)

      assert segment.name == "My Test Segment"
      assert segment.site_id == site.id
      assert segment.owner_id == user.id
      assert segment.type == "site"
    end

    test "creates a segment with root_group_id" do
      site = insert(:site)
      user = insert(:user)

      root_group = insert(:filter_group, segment: nil)

      attrs = %{
        name: "Segment with Group",
        root_group_id: root_group.id
      }

      assert {:ok, segment} = VisitorSegment.create(site, attrs, user)

      assert segment.root_group_id == root_group.id
    end

    test "creates a segment with segment_data" do
      site = insert(:site)
      user = insert(:user)

      segment_data = %{
        "filters" => [["is", "visit:country", ["US"]]]
      }

      attrs = %{
        name: "Segment with Data",
        segment_data: segment_data
      }

      assert {:ok, segment} = VisitorSegment.create(site, attrs, user)

      assert segment.segment_data == segment_data
    end

    test "returns error for missing name" do
      site = insert(:site)
      user = insert(:user)

      attrs = %{}

      assert {:error, changeset} = VisitorSegment.create(site, attrs, user)

      assert changeset.errors[:name] == {"can't be blank", [validation: :required]}
    end

    test "returns error for name too long" do
      site = insert(:site)
      user = insert(:user)

      attrs = %{
        name: String.duplicate("a", 256)
      }

      assert {:error, changeset} = VisitorSegment.create(site, attrs, user)

      assert {:name, {"should be at most %{count} byte(s)",
               [{:count, 255}, {:validation, :length}, {:kind, :max}, {:type, :binary}]}}} in changeset.errors
    end
  end

  describe "VisitorSegment.changeset/2" do
    test "valid changeset with required fields" do
      site = insert(:site)
      user = insert(:user)

      segment = %VisitorSegment{}

      attrs = %{
        name: "Valid Segment",
        site_id: site.id,
        owner_id: user.id,
        type: "site"
      }

      changeset = VisitorSegment.changeset(segment, attrs)
      assert changeset.valid?
    end

    test "invalid changeset without required fields" do
      segment = %VisitorSegment{}
      attrs = %{}

      changeset = VisitorSegment.changeset(segment, attrs)

      refute changeset.valid?
      assert changeset.errors[:name] == {"can't be blank", [validation: :required]}
      assert changeset.errors[:site_id] == {"can't be blank", [validation: :required]}
      assert changeset.errors[:type] == {"can't be blank", [validation: :required]}
    end

    test "validates unique constraint on name per site" do
      site = insert(:site)
      user = insert(:user)

      # Create first segment
      attrs = %{
        name: "Duplicate Name",
        site_id: site.id,
        owner_id: user.id,
        type: "site"
      }

      assert {:ok, _} = %VisitorSegment{} |> VisitorSegment.changeset(attrs) |> Plausible.Repo.insert()

      # Try to create second with same name
      assert {:error, changeset} = %VisitorSegment{} |> VisitorSegment.changeset(attrs) |> Plausible.Repo.insert()

      assert {:name, {_msg, [constraint: :unique, constraint_name: _]}} = changeset.errors[:name]
    end

    test "allows duplicate names across different sites" do
      site1 = insert(:site)
      site2 = insert(:site)
      user = insert(:user)

      attrs1 = %{
        name: "Same Name",
        site_id: site1.id,
        owner_id: user.id,
        type: "site"
      }

      attrs2 = %{
        name: "Same Name",
        site_id: site2.id,
        owner_id: user.id,
        type: "site"
      }

      assert {:ok, _} = %VisitorSegment{} |> VisitorSegment.changeset(attrs1) |> Plausible.Repo.insert()
      assert {:ok, _} = %VisitorSegment{} |> VisitorSegment.changeset(attrs2) |> Plausible.Repo.insert()
    end
  end

  describe "VisitorSegment.has_filters?/1" do
    test "returns false for segment without root_group_id" do
      segment = %VisitorSegment{root_group_id: nil}
      refute VisitorSegment.has_filters?(segment)
    end

    test "returns true for segment with root_group_id" do
      root_group = insert(:filter_group)
      segment = %VisitorSegment{root_group_id: root_group.id}
      assert VisitorSegment.has_filters?(segment)
    end
  end
end
