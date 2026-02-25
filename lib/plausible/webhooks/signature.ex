defmodule Plausible.Webhooks.Signature do
  @moduledoc """
  HMAC-SHA256 signature generation for webhook payloads.
  """

  @doc """
  Generate HMAC-SHA256 signature for a payload using the shared secret.
  """
  def generate(payload, secret) when is_binary(payload) and is_binary(secret) do
    :crypto.mac(:hmac, :sha256, secret, payload)
    |> Base.encode16(case: :lower)
  end

  @doc """
  Generate signature from a map (will be encoded as JSON).
  """
  def generate(payload_map, secret) when is_map(payload_map) do
    payload_map
    |> Jason.encode!()
    |> generate(secret)
  end

  @doc """
  Verify a signature against a payload.
  """
  def verify(payload, secret, signature) do
    expected = generate(payload, secret)
    Plug.Crypto.secure_compare(expected, signature)
  end
end
