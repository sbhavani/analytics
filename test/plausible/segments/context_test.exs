defmodule Plausible.Segments.ContextTest do
  use ExUnit.Case, async: false
  alias Plausible.Segments.Context
  alias Plausible.Segments.VisitorSegment
  alias Plausible.Segments.FilterGroup
  alias Plausible.Segments.FilterCondition
  import Plausible.Factory
  import Plausible.DataCase

  setup [:create_user, :create_site]

  describe "list_segments/1" do
    test "returns empty list when no segments exist", %{site: site} do
      assert Context.list_segments(site) == []
    end

    test "returns all segments for a site", %{site: site, user: user} do
      segment1 = insert(:visitor_segment, name: "Segment 1", site: site, owner: user)
      segment2 = insert(:visitor_segment, name: "Segment 2", site: site, owner: user)
      _other_site_segment = insert(:visitor_segment, name: "Other Site")

      segments = Context.list_segments(site)

      assert length(segments) == 2
      assert Enum.map(segments, & &1.id) |> Enum.sort() ==
               [segment1.id, segment2.id] |> Enum.sort()
    end
  end

  describe "get_segment!/1" do
    test "returns segment by id with preloaded associations", %{site: site, user: user} do
      segment =
        insert(:visitor_segment, name: "Test Segment", site: site, owner: user)
        |> with_filter_group()

      fetched = Context.get_segment!(segment.id)

      assert fetched.id == segment.id
      assert fetched.name == "Test Segment"
    end

    test "raises Ecto.NoResultsError for non-existent id" do
      assert_raise Ecto.NoResultsError, fn ->
        Context.get_segment!(Ecto.UUID.generate())
      end
    end

    test "preloads filter_groups and root_group", %{site: site, user: user} do
      segment =
        insert(:visitor_segment, name: "Test Segment", site: site, owner: user)
        |> with_filter_group()

      fetched = Context.get_segment!(segment.id)

      assert is_list(fetched.filter_groups)
      assert fetched.root_group != nil
    end
  end

  describe "create_segment/3" do
    test "creates a segment without filter tree", %{site: site, user: user} do
      attrs = %{
        "name" => "Simple Segment"
      }

      assert {:ok, segment} = Context.create_segment(site, attrs, user)

      assert segment.name == "Simple Segment"
      assert segment.site_id == site.id
      assert segment.owner_id == user.id
      assert segment.type == "site"
    end

    test "creates a segment with filter tree", %{site: site, user: user} do
      filter_tree = %{
        "operator" => "AND",
        "conditions" => [
          %{
            "field" => "visit:country",
            "operator" => "equals",
            "value" => "US"
          }
        ]
      }

      attrs = %{
        "name" => "US Visitors",
        "filter_tree" => filter_tree
      }

      assert {:ok, segment} = Context.create_segment(site, attrs, user)

      assert segment.name == "US Visitors"

      # Verify filter group was created
      assert segment.root_group != nil
      assert segment.root_group.operator == "AND"
    end

    test "creates a segment with multiple conditions", %{site: site, user: user} do
      filter_tree = %{
        "operator" => "AND",
        "conditions" => [
          %{
            "field" => "visit:country",
            "operator" => "equals",
            "value" => "US"
          },
          %{
            "field" => "visit:device",
            "operator" => "equals",
            "value" => "desktop"
          }
        ]
      }

      attrs = %{
        "name" => "US Desktop Users",
        "filter_tree" => filter_tree
      }

      assert {:ok, segment} = Context.create_segment(site, attrs, user)

      # Verify conditions were created
      segment = segment |> Plausible.Repo.preload([:root_group, root_group: :conditions])
      conditions = segment.root_group.conditions

      assert length(conditions) == 2
    end

    test "creates a segment with nested filter groups", %{site: site, user: user} do
      filter_tree = %{
        "operator" => "AND",
        "conditions" => [
          %{
            "field" => "visit:country",
            "operator" => "equals",
            "value" => "US"
          }
        ],
        "groups" => [
          %{
            "operator" => "OR",
            "conditions" => [
              %{
                "field" => "visit:page",
                "operator" => "equals",
                "value" => "/blog"
              },
              %{
                "field" => "visit:page",
                "operator" => "equals",
                "value" => "/docs"
              }
            ]
          }
        ]
      }

      attrs = %{
        "name" => "US with Blog or Docs",
        "filter_tree" => filter_tree
      }

      assert {:ok, segment} = Context.create_segment(site, attrs, user)

      segment =
        segment
        |> Plausible.Repo.preload([
          :root_group,
          root_group: [:conditions, :nested_groups, nested_groups: :conditions]
        ])

      assert length(segment.root_group.nested_groups) == 1
      nested_group = hd(segment.root_group.nested_groups)
      assert nested_group.operator == "OR"
      assert length(nested_group.conditions) == 2
    end

    test "returns error for missing name", %{site: site, user: user} do
      attrs = %{}

      assert {:error, _} = Context.create_segment(site, attrs, user)
    end
  end

  describe "update_segment/2" do
    test "updates segment name", %{site: site, user: user} do
      segment =
        insert(:visitor_segment, name: "Original Name", site: site, owner: user)
        |> with_filter_group()

      attrs = %{
        "name" => "Updated Name"
      }

      assert {:ok, updated} = Context.update_segment(segment, attrs)

      assert updated.name == "Updated Name"
    end

    test "replaces filter tree", %{site: site, user: user} do
      segment =
        insert(:visitor_segment, name: "Test", site: site, owner: user)
        |> with_filter_group(%{
          conditions: [
            %{field: "visit:country", operator: "equals", value: "US"}
          ]
        })

      new_filter_tree = %{
        "operator" => "AND",
        "conditions" => [
          %{
            "field" => "visit:country",
            "operator" => "equals",
            "value" => "DE"
          }
        ]
      }

      attrs = %{
        "filter_tree" => new_filter_tree
      }

      assert {:ok, updated} = Context.update_segment(segment, attrs)

      updated =
        updated
        |> Plausible.Repo.preload([:root_group, root_group: :conditions])

      assert length(updated.root_group.conditions) == 1
      assert hd(updated.root_group.conditions).value == "DE"
    end

    test "removes old filter groups when updating", %{site: site, user: user} do
      segment =
        insert(:visitor_segment, name: "Test", site: site, owner: user)
        |> with_filter_group(%{
          conditions: [
            %{field: "visit:country", operator: "equals", value: "US"}
          ]
        })

      old_group_id = segment.root_group_id

      # Update with empty filter tree
      attrs = %{
        "filter_tree" => %{"operator" => "AND", "conditions" => []}
      }

      assert {:ok, updated} = Context.update_segment(segment, attrs)

      # Old group should be deleted
      refute Plausible.Repo.get(FilterGroup, old_group_id)
    end
  end

  describe "delete_segment/1" do
    test "deletes segment and associated filter groups", %{site: site, user: user} do
      segment =
        insert(:visitor_segment, name: "To Delete", site: site, owner: user)
        |> with_filter_group()

      group_id = segment.root_group_id

      assert {:ok, _} = Context.delete_segment(segment)

      refute Plausible.Repo.get(VisitorSegment, segment.id)
      refute Plausible.Repo.get(FilterGroup, group_id)
    end

    test "returns deleted segment", %{site: site, user: user} do
      segment =
        insert(:visitor_segment, name: "To Delete", site: site, owner: user)

      assert {:ok, deleted} = Context.delete_segment(segment)

      assert deleted.id == segment.id
    end
  end

  describe "preview_segment/2" do
    test "returns error for invalid filter tree", %{site: _site} do
      invalid_tree = %{
        "operator" => "INVALID"
      }

      assert {:error, _} = Context.preview_segment(%Plausible.Site{}, invalid_tree)
    end

    test "returns error for invalid field", %{site: site} do
      invalid_tree = %{
        "operator" => "AND",
        "conditions" => [
          %{
            "field" => "invalid:field",
            "operator" => "equals",
            "value" => "test"
          }
        ]
      }

      assert {:error, _} = Context.preview_segment(site, invalid_tree)
    end
  end

  # Helper function to create filter groups for tests
  defp with_filter_group(segment, opts \\ []) do
    conditions = Keyword.get(opts, :conditions, [])

    {:ok, group} =
      %FilterGroup{}
      |> FilterGroup.changeset(%{
        operator: "AND",
        segment_id: segment.id
      })
      |> Plausible.Repo.insert()

    Enum.each(conditions, fn cond_attrs ->
      %FilterCondition{}
      |> FilterCondition.changeset(Map.put(cond_attrs, :group_id, group.id))
      |> Plausible.Repo.insert!()
    end)

    segment
    |> VisitorSegment.changeset(%{root_group_id: group.id})
    |> Plausible.Repo.update!()
    |> Plausible.Repo.preload([:root_group])
  end
end
