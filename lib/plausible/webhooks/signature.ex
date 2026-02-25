defmodule Plausible.Webhooks.Signature do
  @moduledoc """
  HMAC-SHA256 signature generation for webhook payloads.
  """

  @doc """
  Generates an HMAC-SHA256 signature for the given payload using the secret.

  ## Examples

      iex> Plausible.Webhooks.Signature.generate("my_secret", ~s({"event":"test"}))
      "f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8"
  """
  @spec generate(String.t(), String.t()) :: String.t()
  def generate(secret, payload) when is_binary(secret) and is_binary(payload) do
    signature = :crypto.mac(:hmac, :sha256, secret, payload)
    Base.encode16(signature, case: :lower)
  end

  @doc """
  Verifies that the given signature matches the payload.

  ## Examples

      iex> Plausible.Webhooks.Signature.verify("my_secret", ~s({"event":"test"}), "f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8")
      true
  """
  @spec verify(String.t(), String.t(), String.t()) :: boolean()
  def verify(secret, payload, expected_signature) when is_binary(secret) do
    generated = generate(secret, payload)
    Plug.Crypto.secure_compare(generated, expected_signature)
  end

  @doc """
  Creates a signed payload with the signature included.
  """
  @spec sign_payload(String.t(), map() | String.t()) :: map()
  def sign_payload(secret, payload) when is_binary(secret) and is_map(payload) do
    payload_json = Jason.encode!(payload)
    signature = generate(secret, payload_json)

    Map.put(payload, :signature, signature)
    |> Map.put(:signature_algorithm, "HMAC-SHA256")
  end

  def sign_payload(_secret, payload), do: payload
end
