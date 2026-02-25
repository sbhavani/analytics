defmodule Plausible.Auth.SAML.Response do
  @moduledoc """
  Parses and validates SAML 2.0 responses from the IdP.
  """

  alias Plausible.Auth.SAML.Configuration

  defmodule Assertion do
    @moduledoc """
    Struct representing parsed SAML assertion.
    """
    defstruct [:email, :name, :session_index, :assertion_id, :issuer, :recipient]

    @type t :: %__MODULE__{
            email: String.t() | nil,
            name: String.t() | nil,
            session_index: String.t() | nil,
            assertion_id: String.t() | nil,
            issuer: String.t() | nil,
            recipient: String.t() | nil
          }
  end

  @doc """
  Parses and validates a SAML response.
  """
  def parse(%Configuration{} = config, saml_response) do
    # Decode the base64 response
    decoded =
      case Base.decode64(saml_response) do
        {:ok, decoded} -> decoded
        :error -> {:error, :invalid_base64}
      end

    with {:ok, xml} <- decoded,
         {:ok, assertion} <- extract_assertion(xml, config) do
      {:ok, assertion}
    else
      {:error, reason} -> {:error, reason}
      error when is_atom(error) -> {:error, error}
    end
  end

  defp extract_assertion(xml, config) do
    # Parse the SAML response XML
    # In a real implementation, we would:
    # 1. Verify the signature using the IdP certificate
    # 2. Check the issuer matches config.idp_entity_id
    # 3. Verify the destination matches our ACS URL
    # 4. Check not_on_or_after condition
    # 5. Check replay attacks

    with {:ok, doc} <- parse_xml(xml),
         {:ok, issuer} <- extract_issuer(doc),
         :ok <- verify_issuer(issuer, config),
         {:ok, name_id} <- extract_name_id(doc),
         {:ok, attributes} <- extract_attributes(doc) do
      {:ok,
       %Assertion{
         email: name_id,
         name: Map.get(attributes, "displayName") || Map.get(attributes, "name"),
         session_index: Map.get(attributes, "sessionIndex"),
         assertion_id: get_assertion_id(doc),
         issuer: issuer,
         recipient: get_acs_url(doc)
       }}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp parse_xml(xml) do
    # Simple XML parsing - in production use a proper XML library
    {:ok, xml}
  rescue
    _ -> {:error, :invalid_xml}
  end

  defp extract_issuer(doc) do
    # Extract issuer from the response
    # Using regex for simplicity - in production use xmerl or similar
    case Regex.run(~r/<saml:Issuer[^>]*>([^<]+)<\/saml:Issuer>/, doc) do
      [_, issuer] -> {:ok, String.trim(issuer)}
      _ -> {:error, :issuer_not_found}
    end
  end

  defp verify_issuer(issuer, %Configuration{idp_entity_id: expected}) do
    if issuer == expected do
      :ok
    else
      {:error, {:issuer_mismatch, issuer, expected}}
    end
  end

  defp extract_name_id(doc) do
    case Regex.run(~r/<saml:NameID[^>]*>([^<]+)<\/saml:NameID>/, doc) do
      [_, name_id] -> {:ok, String.trim(name_id)}
      _ -> {:error, :name_id_not_found}
    end
  end

  defp extract_attributes(_doc) do
    # Extract attributes from the response
    # In a real implementation, parse the AttributeStatement
    {:ok, %{}}
  end

  defp get_assertion_id(doc) do
    case Regex.run(~r/ID="([^"]+)"/, doc) do
      [_, id] -> id
      _ -> nil
    end
  end

  defp get_acs_url(doc) do
    case Regex.run(~r/Destination="([^"]+)"/, doc) do
      [_, url] -> url
      _ -> nil
    end
  end
end
