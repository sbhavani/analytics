defmodule Plausible.WebhookNotifications.Delivery do
  @moduledoc """
  Module for handling webhook delivery and signature generation.

  This module provides functions for:
  - Generating HMAC-SHA256 signatures for webhook payloads
  - Verifying signatures sent by webhook receivers
  - Delivering webhooks via HTTP POST
  """

  @timeout 30_000

  @doc """
  Generates an HMAC-SHA256 signature for a webhook payload.

  The signature is formatted as `sha256=<hex-encoded-hmac>` and should be
  sent in the `X-Webhook-Signature` header for verification by the receiver.

  ## Examples

      iex> signature = Plausible.WebhookNotifications.Delivery.generate_signature(~s({"event":"test"}), "my-secret-key")
      iex> String.starts_with?(signature, "sha256=")
      true
  """
  @spec generate_signature(String.t(), String.t()) :: String.t()
  def generate_signature(payload, secret) when is_binary(payload) and is_binary(secret) do
    :crypto.hmac(:sha256, secret, payload)
    |> Base.encode16(case: :lower)
    |> then(&"sha256=#{&1}")
  end

  @doc """
  Generates a raw HMAC-SHA256 signature without the algorithm prefix.

  Returns just the hex-encoded signature for cases where the prefix
  is added separately.
  """
  @spec generate_signature_raw(String.t(), String.t()) :: String.t()
  def generate_signature_raw(payload, secret) when is_binary(payload) and is_binary(secret) do
    :crypto.hmac(:sha256, secret, payload)
    |> Base.encode16(case: :lower)
  end

  @doc """
  Verifies an HMAC-SHA256 signature against a payload and secret.

  Returns true if the signature matches, false otherwise.
  Uses constant-time comparison to prevent timing attacks.

  ## Examples

      iex> payload = ~s({"event":"test"})
      iex> secret = "my-secret-key"
      iex> signature = Plausible.WebhookNotifications.Delivery.generate_signature(payload, secret)
      iex> Plausible.WebhookNotifications.Delivery.verify_signature(payload, secret, signature)
      true

      iex> Plausible.WebhookNotifications.Delivery.verify_signature("payload", "secret", "sha256=invalid")
      false
  """
  @spec verify_signature(String.t(), String.t(), String.t()) :: boolean()
  def verify_signature(payload, secret, signature) when is_binary(payload) and is_binary(secret) and is_binary(signature) do
    expected_signature = generate_signature(payload, secret)
    Plug.Crypto.secure_compare(expected_signature, signature)
  end

  @doc """
  Parses the signature header value and returns the algorithm and signature.

  ## Examples

      iex> Plausible.WebhookNotifications.Delivery.parse_signature_header("sha256=abc123")
      {:ok, :sha256, "abc123"}

      iex> Plausible.WebhookNotifications.Delivery.parse_signature_header("invalid")
      {:error, :invalid_format}
  """
  @spec parse_signature_header(String.t()) :: {:ok, atom(), String.t()} | {:error, atom()}
  def parse_signature_header(header) do
    case String.split(header, "=", parts: 2) do
      [algorithm, signature] ->
        case algorithm do
          "sha256" -> {:ok, :sha256, signature}
          _ -> {:error, :unsupported_algorithm}
        end

      _ ->
        {:error, :invalid_format}
    end
  end

  @doc """
  Delivers a webhook payload to the configured endpoint.

  ## Parameters

    - webhook: The WebhookConfig schema
    - payload: The map payload to send

  ## Returns

    - {:ok, response} on success
    - {:error, reason} on failure
  """
  def deliver_webhook(%Plausible.WebhookNotifications.WebhookConfig{} = webhook, payload) do
    endpoint_url = webhook.endpoint_url
    secret = webhook.secret
    event_type = Map.get(payload, :event, "unknown")

    # Build the JSON payload
    json_payload = Jason.encode!(payload)

    # Generate HMAC-SHA256 signature
    signature = generate_signature(json_payload, secret)

    # Build headers
    headers = [
      {"Content-Type", "application/json"},
      {"X-Webhook-Signature", signature},
      {"X-Webhook-Event", event_type}
    ]

    # Make the HTTP POST request
    case Req.post(endpoint_url,
           body: json_payload,
           headers: headers,
           timeout: @timeout,
           receive_timeout: @timeout
         ) do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        {:ok, %{status: status, body: body}}

      {:ok, %{status: status, body: body}} ->
        {:error, %{status: status, body: body, reason: "HTTP #{status}"}}

      {:error, %{reason: reason}} ->
        {:error, %{reason: reason}}

      {:error, reason} ->
        {:error, %{reason: reason}}
    end
  end
end
