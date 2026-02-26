defmodule PlausibleWeb.Plugs.SecureSSO do
  @moduledoc """
  Plug to secure SSO-related routes and handle security for SAML authentication.
  """

  use Plausible
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    # Security headers for SSO endpoints
    conn
    |> put_resp_header("X-Frame-Options", "DENY")
    |> put_resp_header("X-Content-Type-Options", "nosniff")
    |> put_resp_header("Referrer-Policy", "strict-origin-when-cross-origin")
  end
end
