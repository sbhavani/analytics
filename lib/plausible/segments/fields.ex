defmodule Plausible.Segments.Fields do
  @moduledoc """
  Configuration module for available visitor filter fields.
  These correspond to fields in the ClickHouse sessions_v2 table.
  """

  @type field_type :: :string | :number | :boolean | :set

  @type t :: %__MODULE__{
          name: String.t(),
          key: String.t(),
          type: field_type(),
          label: String.t(),
          operators: [String.t()]
        }

  defstruct [:name, :key, :type, :label, :operators]

  @fields [
    %__MODULE__{
      name: "Country",
      key: "country",
      type: :string,
      label: "Country",
      operators: ["equals", "does_not_equal", "contains", "is_one_of"]
    },
    %__MODULE__{
      name: "Region",
      key: "region",
      type: :string,
      label: "Region",
      operators: ["equals", "does_not_equal", "contains"]
    },
    %__MODULE__{
      name: "City",
      key: "city",
      type: :string,
      label: "City",
      operators: ["equals", "does_not_equal", "contains"]
    },
    %__MODULE__{
      name: "Device",
      key: "device",
      type: :set,
      label: "Device",
      operators: ["equals", "does_not_equal", "is_one_of"]
    },
    %__MODULE__{
      name: "Browser",
      key: "browser",
      type: :string,
      label: "Browser",
      operators: ["equals", "does_not_equal", "contains", "is_one_of"]
    },
    %__MODULE__{
      name: "Operating System",
      key: "os",
      type: :string,
      label: "Operating System",
      operators: ["equals", "does_not_equal", "contains", "is_one_of"]
    },
    %__MODULE__{
      name: "Source",
      key: "source",
      type: :string,
      label: "Traffic Source",
      operators: ["equals", "does_not_equal", "contains", "is_one_of"]
    },
    %__MODULE__{
      name: "UTM Medium",
      key: "utm_medium",
      type: :string,
      label: "UTM Medium",
      operators: ["equals", "does_not_equal", "contains", "is_one_of"]
    },
    %__MODULE__{
      name: "UTM Source",
      key: "utm_source",
      type: :string,
      label: "UTM Source",
      operators: ["equals", "does_not_equal", "contains", "is_one_of"]
    },
    %__MODULE__{
      name: "UTM Campaign",
      key: "utm_campaign",
      type: :string,
      label: "UTM Campaign",
      operators: ["equals", "does_not_equal", "contains", "is_one_of"]
    },
    %__MODULE__{
      name: "UTM Content",
      key: "utm_content",
      type: :string,
      label: "UTM Content",
      operators: ["equals", "does_not_equal", "contains"]
    },
    %__MODULE__{
      name: "UTM Term",
      key: "utm_term",
      type: :string,
      label: "UTM Term",
      operators: ["equals", "does_not_equal", "contains"]
    },
    %__MODULE__{
      name: "Hostname",
      key: "hostname",
      type: :string,
      label: "Hostname",
      operators: ["equals", "does_not_equal", "contains"]
    },
    %__MODULE__{
      name: "Entry Page",
      key: "entry_page",
      type: :string,
      label: "Entry Page",
      operators: ["equals", "does_not_equal", "contains"]
    },
    %__MODULE__{
      name: "Exit Page",
      key: "exit_page",
      type: :string,
      label: "Exit Page",
      operators: ["equals", "does_not_equal", "contains"]
    },
    %__MODULE__{
      name: "Pageviews",
      key: "pageviews",
      type: :number,
      label: "Pageviews",
      operators: ["equals", "not_equals", "greater_than", "less_than", "greater_or_equal", "less_or_equal"]
    },
    %__MODULE__{
      name: "Events",
      key: "events",
      type: :number,
      label: "Events",
      operators: ["equals", "not_equals", "greater_than", "less_than", "greater_or_equal", "less_or_equal"]
    },
    %__MODULE__{
      name: "Duration",
      key: "duration",
      type: :number,
      label: "Session Duration (seconds)",
      operators: ["equals", "not_equals", "greater_than", "less_than", "greater_or_equal", "less_or_equal"]
    },
    %__MODULE__{
      name: "Bounce",
      key: "is_bounce",
      type: :boolean,
      label: "Is Bounce",
      operators: ["is_true", "is_false"]
    },
    %__MODULE__{
      name: "Channel",
      key: "channel",
      type: :string,
      label: "Traffic Channel",
      operators: ["equals", "does_not_equal", "is_one_of"]
    }
  ]

  @doc """
  Returns all available filter fields.
  """
  @spec all() :: [t()]
  def all, do: @fields

  @doc """
  Returns field by key.
  """
  @spec get_by_key(String.t()) :: t() | nil
  def get_by_key(key) do
    Enum.find(@fields, fn field -> field.key == key end)
  end

  @doc """
  Returns operators for a given field key.
  """
  @spec operators_for(String.t()) :: [String.t()]
  def operators_for(key) do
    case get_by_key(key) do
      nil -> []
      field -> field.operators
    end
  end

  @doc """
  Returns the type of a field.
  """
  @spec type_for(String.t()) :: field_type() | nil
  def type_for(key) do
    case get_by_key(key) do
      nil -> nil
      field -> field.type
    end
  end

  @doc """
  Returns labels for all fields (for UI dropdowns).
  """
  @spec labels() :: [{String.t(), String.t()}]
  def labels do
    Enum.map(@fields, fn field -> {field.key, field.label} end)
  end
end
