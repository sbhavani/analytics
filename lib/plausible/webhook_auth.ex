defmodule Plausible.WebhookAuth do
  @moduledoc """
  Helper module for webhook signature generation and verification.
  Uses HMAC-SHA256 for payload signing.
  """

  @internal_domains ~w[localhost 127.0.0.1 0.0.0.0]
  @private_ip_ranges ~w[10. 172.16. 172.17. 172.18. 172.19. 172.2 172.30. 172.31. 192.168.]

  @doc """
  Generate HMAC-SHA256 signature for a webhook payload.

  ## Examples

      iex> sign_payload(%{event_type: "spike", site_id: "123"}, "my-secret")
      "abc123..."

  """
  @spec sign_payload(map(), String.t()) :: String.t()
  def sign_payload(payload, secret) when is_map(payload) do
    payload_json = Jason.encode!(payload)
    sign_payload(payload_json, secret)
  end

  def sign_payload(payload_json, secret) when is_binary(payload_json) do
    :crypto.mac(:hmac, :sha256, secret, payload_json)
    |> Base.encode16(case: :lower)
  end

  @doc """
  Verify a webhook signature.

  ## Examples

      iex> verify_signature(signature, payload, "my-secret")
      true

  """
  @spec verify_signature(String.t(), map() | String.t(), String.t()) :: boolean()
  def verify_signature(signature, payload, secret) do
    expected = sign_payload(payload, secret)
    Plug.Crypto.secure_compare(signature, expected)
  end

  @doc """
  Generate a test payload for webhook testing.
  """
  @spec test_payload(String.t(), String.t()) :: map()
  def test_payload(site_id, site_domain) do
    %{
      event_type: "test",
      site_id: site_id,
      site_domain: site_domain,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      message: "This is a test webhook from Plausible"
    }
  end

  @doc """
  Validate webhook URL - ensures it's a valid external URL.
  Rejects localhost, private IPs, and internal addresses.
  """
  @spec validate_url(String.t()) :: :ok | {:error, String.t()}
  def validate_url(url) do
    case URI.parse(url) do
      %URI{scheme: scheme, host: host} when scheme in ["http", "https"] ->
        cond do
          host in @internal_domains ->
            {:error, "Cannot use localhost or loopback addresses"}

          is_private_ip?(host) ->
            {:error, "Cannot use private IP addresses"}

          true ->
            :ok
        end

      %URI{scheme: nil} ->
        {:error, "URL must include http:// or https://"}

      _ ->
        {:error, "Invalid URL format"}
    end
  end

  defp is_private_ip?(host) do
    # Check for private IP ranges
    Enum.any?(@private_ip_ranges, fn prefix ->
      String.starts_with?(host, prefix)
    end) || host in @internal_domains
  end
end
