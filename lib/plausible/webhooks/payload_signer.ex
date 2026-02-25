defmodule Plausible.Webhooks.PayloadSigner do
  @moduledoc """
  HMAC-SHA256 payload signing for webhooks.
  """

  @doc """
  Signs a payload map using HMAC-SHA256 with the given secret.
  Returns the hex-encoded signature.
  """
  def sign(payload, secret) when is_map(payload) do
    payload
    |> Jason.encode!()
    |> sign(secret)
  end

  def sign(payload_string, secret) when is_binary(payload_string) do
    :crypto.mac(:hmac, :sha256, secret, payload_string)
    |> Base.encode16(case: :lower)
  end

  @doc """
  Verifies a signature against a payload.
  """
  def verify(payload, secret, signature) do
    expected = sign(payload, secret)
    Plug.Crypto.secure_compare(expected, signature)
  end
end
