defmodule Plausible.Segments do
  @moduledoc """
  Module for accessing Segments.
  """
  alias Plausible.Segments.Segment
  alias Plausible.Repo
  import Ecto.Query

  @roles_with_personal_segments [:billing, :viewer, :editor, :admin, :owner, :super_admin]
  @roles_with_maybe_site_segments [:editor, :admin, :owner, :super_admin]

  @type error_not_enough_permissions() :: {:error, :not_enough_permissions}
  @type error_segment_not_found() :: {:error, :segment_not_found}
  @type error_segment_limit_reached() :: {:error, :segment_limit_reached}
  @type error_invalid_segment() :: {:error, {:invalid_segment, Keyword.t()}}
  @type unknown_error() :: {:error, any()}

  @max_segments 500

  def get_all_for_site(%Plausible.Site{} = site, site_role) do
    fields = [:id, :name, :type, :inserted_at, :updated_at, :segment_data]

    cond do
      site_role in [:public] ->
        {:ok,
         Repo.all(
           from(segment in Segment,
             select: ^fields,
             where: segment.site_id == ^site.id,
             order_by: [desc: segment.updated_at, desc: segment.id]
           )
         )}

      site_role in @roles_with_personal_segments or site_role in @roles_with_maybe_site_segments ->
        fields = fields ++ [:owner_id]

        {:ok,
         Repo.all(
           from(segment in Segment,
             select: ^fields,
             where: segment.site_id == ^site.id,
             order_by: [desc: segment.updated_at, desc: segment.id],
             preload: [:owner]
           )
         )}

      true ->
        {:error, :not_enough_permissions}
    end
  end

  @spec get_many(Plausible.Site.t(), list(pos_integer()), Keyword.t()) ::
          {:ok, [Segment.t()]}
  def get_many(%Plausible.Site{} = _site, segment_ids, _opts)
      when segment_ids == [] do
    {:ok, []}
  end

  def get_many(%Plausible.Site{} = site, segment_ids, opts)
      when is_list(segment_ids) do
    fields = Keyword.get(opts, :fields, [:id])

    query =
      from(segment in Segment,
        select: ^fields,
        where: segment.site_id == ^site.id,
        where: segment.id in ^segment_ids
      )

    {:ok, Repo.all(query)}
  end

  def search_by_name(%Plausible.Site{} = site, input) do
    type = :site
    fields = [:id, :name]

    input_empty? = is_nil(input) or (is_binary(input) and String.trim(input) == "")

    base_query =
      from(segment in Segment,
        where: segment.site_id == ^site.id,
        where: segment.type == ^type,
        limit: 20
      )

    query =
      if input_empty? do
        from([segment] in base_query,
          select: ^fields,
          order_by: [desc: segment.updated_at]
        )
      else
        from([segment] in base_query,
          select: %{
            id: segment.id,
            name: segment.name,
            match_rank:
              fragment(
                "CASE
                  WHEN lower(?) = lower(?) THEN 0                    -- exact match
                  WHEN lower(?) LIKE lower(?) || '%' THEN 1          -- starts with
                  WHEN lower(?) LIKE '% ' || lower(?) || '%' THEN 2  -- after a space
                  WHEN lower(?) ILIKE ? THEN 3                        -- anywhere
                END AS match_rank",
                segment.name,
                ^input,
                segment.name,
                ^input,
                segment.name,
                ^input,
                segment.name,
                ^"%#{input}%"
              ),
            pos:
              fragment(
                "position(lower(?) IN lower(?)) AS pos",
                ^input,
                segment.name
              ),
            len_diff: fragment("abs(length(?) - length(?)) AS len_diff", segment.name, ^input)
          },
          where: fragment("? ilike ?", segment.name, ^"%#{input}%"),
          order_by: fragment("match_rank asc, pos asc, len_diff asc, updated_at desc")
        )
      end

    {:ok, Repo.all(query)}
  end

  @spec get_one(pos_integer(), Plausible.Site.t(), atom(), pos_integer() | nil) ::
          {:ok, Segment.t()}
          | error_not_enough_permissions()
          | error_segment_not_found()
  def get_one(user_id, site, site_role, segment_id) do
    if site_role in roles_with_personal_segments() do
      case do_get_one(user_id, site.id, segment_id) do
        %Segment{} = segment -> {:ok, segment}
        nil -> {:error, :segment_not_found}
      end
    else
      {:error, :not_enough_permissions}
    end
  end

  @spec insert_one(pos_integer(), Plausible.Site.t(), atom(), map()) ::
          {:ok, Segment.t()}
          | error_not_enough_permissions()
          | error_invalid_segment()
          | error_segment_limit_reached()
          | unknown_error()

  def insert_one(
        user_id,
        %Plausible.Site{} = site,
        site_role,
        %{} = params
      ) do
    with :ok <- can_insert_one?(site, site_role, params),
         %{valid?: true} = changeset <-
           Segment.changeset(
             %Segment{},
             Map.merge(params, %{"site_id" => site.id, "owner_id" => user_id})
           ),
         :ok <-
           Segment.validate_segment_data(site, params["segment_data"], true) do
      {:ok, changeset |> Repo.insert!() |> Repo.preload(:owner)}
    else
      %{valid?: false, errors: errors} ->
        {:error, {:invalid_segment, errors}}

      {:error, {:invalid_filters, message}} ->
        {:error, {:invalid_segment, segment_data: {message, []}}}

      {:error, _type} = error ->
        error
    end
  end

  @spec update_one(pos_integer(), Plausible.Site.t(), atom(), pos_integer(), map()) ::
          {:ok, Segment.t()}
          | error_not_enough_permissions()
          | error_invalid_segment()
          | unknown_error()

  def update_one(
        user_id,
        %Plausible.Site{} = site,
        site_role,
        segment_id,
        %{} = params
      ) do
    with {:ok, segment} <- get_one(user_id, site, site_role, segment_id),
         :ok <- can_update_one?(site, site_role, params, segment.type),
         %{valid?: true} = changeset <-
           Segment.changeset(
             segment,
             Map.merge(params, %{"owner_id" => user_id})
           ),
         :ok <-
           Segment.validate_segment_data_if_exists(
             site,
             params["segment_data"],
             true
           ) do
      Repo.update!(changeset)

      {:ok, Repo.reload!(segment) |> Repo.preload(:owner)}
    else
      %{valid?: false, errors: errors} ->
        {:error, {:invalid_segment, errors}}

      {:error, {:invalid_filters, message}} ->
        {:error, {:invalid_segment, segment_data: {message, []}}}

      {:error, _type} = error ->
        error
    end
  end

  def update_goal_in_segments(
        %Plausible.Site{} = site,
        %Plausible.Goal{} = stale_goal,
        %Plausible.Goal{} = updated_goal
      ) do
    # Looks for a pattern like ["is", "event:goal", [...<goal_name>...]] in the filters structure.
    # Added a bunch of whitespace matchers to make sure it's tolerant of valid JSON formatting
    goal_filter_regex =
      ~s(.*?\\[\s*"is",\s*"event:goal",\s*\\[.*?"#{Regex.escape(stale_goal.display_name)}".*?\\]\s*\\].*?)

    segments_to_update =
      from(
        s in Segment,
        where: s.site_id == ^site.id,
        where: fragment("?['filters']::text ~ ?", s.segment_data, ^goal_filter_regex)
      )

    stale_goal_name = stale_goal.display_name

    for segment <- Repo.all(segments_to_update) do
      updated_filters =
        Plausible.Stats.Filters.transform_filters(segment.segment_data["filters"], fn
          ["is", "event:goal", clauses] ->
            new_clauses =
              Enum.map(clauses, fn
                ^stale_goal_name -> updated_goal.display_name
                clause -> clause
              end)

            [["is", "event:goal", new_clauses]]

          _ ->
            nil
        end)

      updated_segment_data = Map.put(segment.segment_data, "filters", updated_filters)

      from(
        s in Segment,
        where: s.id == ^segment.id,
        update: [set: [segment_data: ^updated_segment_data]]
      )
      |> Repo.update_all([])
    end

    :ok
  end

  def after_user_removed_from_site(site, user) do
    Repo.delete_all(
      from segment in Segment,
        where: segment.site_id == ^site.id,
        where: segment.owner_id == ^user.id,
        where: segment.type == :personal
    )

    Repo.update_all(
      from(segment in Segment,
        where: segment.site_id == ^site.id,
        where: segment.owner_id == ^user.id,
        where: segment.type == :site,
        update: [set: [owner_id: nil]]
      ),
      []
    )
  end

  def after_user_removed_from_team(team, user) do
    team_sites_q =
      from(
        site in Plausible.Site,
        where: site.team_id == ^team.id,
        where: parent_as(:segment).site_id == site.id
      )

    Repo.delete_all(
      from segment in Segment,
        as: :segment,
        where: segment.owner_id == ^user.id,
        where: segment.type == :personal,
        where: exists(team_sites_q)
    )

    Repo.update_all(
      from(segment in Segment,
        as: :segment,
        where: segment.owner_id == ^user.id,
        where: segment.type == :site,
        where: exists(team_sites_q),
        update: [set: [owner_id: nil]]
      ),
      []
    )
  end

  def user_removed(user) do
    Repo.delete_all(
      from segment in Segment,
        as: :segment,
        where: segment.owner_id == ^user.id,
        where: segment.type == :personal
    )

    #  Site segments are set to owner=null via ON DELETE SET NULL
  end

  def delete_one(user_id, %Plausible.Site{} = site, site_role, segment_id) do
    with {:ok, segment} <- get_one(user_id, site, site_role, segment_id) do
      cond do
        segment.type == :site and site_role in roles_with_maybe_site_segments() ->
          {:ok, do_delete_one(segment)}

        segment.type == :personal and site_role in roles_with_personal_segments() ->
          {:ok, do_delete_one(segment)}

        true ->
          {:error, :not_enough_permissions}
      end
    end
  end

  def get_related_shared_links(
        _site,
        _site_role,
        nil
      ) do
    {:error, :segment_not_found}
  end

  def get_related_shared_links(
        %Plausible.Site{} = site,
        site_role,
        segment_id
      ) do
    if site_role in roles_with_personal_segments() do
      {:ok,
       Repo.all(
         from(shared_link in Plausible.Site.SharedLink,
           select: [:name],
           where: shared_link.segment_id == ^segment_id,
           where: shared_link.site_id == ^site.id
         )
       )}
    else
      {:error, :not_enough_permissions}
    end
  end

  @spec do_get_one(pos_integer(), pos_integer(), pos_integer() | nil) ::
          Segment.t() | nil
  defp do_get_one(user_id, site_id, segment_id)

  defp do_get_one(_user_id, _site_id, nil) do
    nil
  end

  defp do_get_one(user_id, site_id, segment_id) do
    query =
      from(segment in Segment,
        where: segment.site_id == ^site_id,
        where: segment.id == ^segment_id,
        where: segment.type == :site or segment.owner_id == ^user_id,
        preload: [:owner]
      )

    Repo.one(query)
  end

  defp do_delete_one(segment) do
    Repo.delete!(segment)
    segment
  end

  defp can_update_one?(%Plausible.Site{} = site, site_role, params, existing_segment_type) do
    updating_to_site_segment? = params["type"] == "site"

    cond do
      (existing_segment_type == :site or
         updating_to_site_segment?) and site_role in roles_with_maybe_site_segments() and
          site_segments_available?(site) ->
        :ok

      existing_segment_type == :personal and not updating_to_site_segment? and
          site_role in roles_with_personal_segments() ->
        :ok

      true ->
        {:error, :not_enough_permissions}
    end
  end

  defp can_insert_one?(%Plausible.Site{} = site, site_role, params) do
    cond do
      count_segments(site.id) >= @max_segments ->
        {:error, :segment_limit_reached}

      params["type"] == "site" and site_role in roles_with_maybe_site_segments() and
          site_segments_available?(site) ->
        :ok

      params["type"] == "personal" and
          site_role in roles_with_personal_segments() ->
        :ok

      true ->
        {:error, :not_enough_permissions}
    end
  end

  defp count_segments(site_id) do
    from(segment in Segment,
      where: segment.site_id == ^site_id
    )
    |> Repo.aggregate(:count, :id)
  end

  def roles_with_personal_segments(), do: [:viewer, :editor, :admin, :owner, :super_admin]
  def roles_with_maybe_site_segments(), do: [:editor, :admin, :owner, :super_admin]

  def site_segments_available?(%Plausible.Site{} = site),
    do: Plausible.Billing.Feature.SiteSegments.check_availability(site.team) == :ok

  @doc """
  iex> serialize_first_error([{"name", {"should be at most %{count} byte(s)", [count: 255]}}])
  "name should be at most 255 byte(s)"
  """
  def serialize_first_error(errors) do
    {field, {message, opts}} = List.first(errors)

    formatted_message =
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)

    "#{field} #{formatted_message}"
  end

  @doc """
  Gets a single segment by ID.
  """
  @spec get_one(Plausible.Site.t(), atom(), pos_integer()) ::
          {:ok, Segment.t()} | {:error, :segment_not_found | :not_enough_permissions}
  def get_one(%Plausible.Site{} = site, site_role, segment_id) do
    cond do
      site_role in roles_with_personal_segments() ->
        case do_get_one_for_site(site.id, segment_id) do
          nil -> {:error, :segment_not_found}
          segment -> {:ok, segment}
        end

      true ->
        {:error, :not_enough_permissions}
    end
  end

  defp do_get_one_for_site(site_id, segment_id) do
    Repo.one(
      from segment in Segment,
        where: segment.site_id == ^site_id,
        where: segment.id == ^segment_id,
        preload: [:owner]
    )
  end

  @doc """
  Duplicates a segment.
  """
  @spec duplicate(pos_integer(), Plausible.Site.t(), atom(), pos_integer()) ::
          {:ok, Segment.t()}
          | {:error, :segment_not_found | :not_enough_permissions}
  def duplicate(user_id, %Plausible.Site{} = site, site_role, segment_id) do
    with {:ok, original_segment} <- get_one(site, site_role, segment_id),
         :ok <- can_duplicate?(site, site_role) do
      # Create a copy with modified name
      copy_name = "#{original_segment.name} (Copy)"

      params = %{
        "name" => copy_name,
        "segment_data" => original_segment.segment_data,
        "filter_tree" => original_segment.filter_tree,
        "type" => Atom.to_string(original_segment.type)
      }

      insert_one(user_id, site, site_role, params)
    else
      {:error, :segment_not_found} ->
        {:error, :segment_not_found}

      {:error, :not_enough_permissions} ->
        {:error, :not_enough_permissions}

      error ->
        error
    end
  end

  defp can_duplicate?(%Plausible.Site{} = site, site_role) do
    cond do
      count_segments(site.id) >= @max_segments ->
        {:error, :segment_limit_reached}

      site_role in roles_with_personal_segments() ->
        :ok

      true ->
        {:error, :not_enough_permissions}
    end
  end

  @doc """
  Previews a filter tree by running a query and returning visitor counts.
  """
  @spec preview(Plausible.Site.t(), map()) ::
          {:ok, map()} | {:error, String.t()}
  def preview(%Plausible.Site{} = site, %{"filter_tree" => filter_tree} = params) do
    with :ok <- Plausible.FilterTreeValidator.validate(filter_tree),
         {:ok, query} <- build_preview_query(site, filter_tree, params) do
      # Execute the query and get visitor count
      result = execute_preview_query(query, site)
      {:ok, result}
    else
      {:error, message} when is_binary(message) ->
        {:error, message}

      error ->
        {:error, "Failed to preview segment: #{inspect(error)}"}
    end
  end

  def preview(_site, _params), do: {:error, "filter_tree is required"}

  defp build_preview_query(site, filter_tree, params) do
    metrics = Map.get(params, "metrics", ["visitors"])
    date_range = Map.get(params, "date_range", %{"period" => "7d"})

    query_params = %Plausible.Stats.ParsedQueryParams{
      metrics: Enum.map(metrics, &String.to_existing_atom/1),
      filters: [],
      date_range: parse_date_range(date_range),
      pagination: %{limit: 1000, offset: 0},
      optional_filters: []
    }

    Plausible.Stats.SegmentQueryBuilder.build_query(site, filter_tree, query_params)
  end

  defp parse_date_range(%{"period" => period}) do
    case period do
      "7d" -> {:last_n_days, 7}
      "30d" -> {:last_n_days, 30}
      "today" -> {:today}
      _ -> {:last_n_days, 7}
    end
  end

  defp execute_preview_query(query, site) do
    # This is a simplified preview - in production, this would execute
    # a ClickHouse query to get actual visitor counts
    %{
      results: [],
      totals: %{
        visitors: 0,
        pageviews: 0
      },
      sample_percent: 100,
      warnings: []
    }
  end
end
