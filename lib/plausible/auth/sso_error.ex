defmodule Plausible.Auth.SSOError do
  @moduledoc """
  SAML authentication error handling with user-friendly messages.

  This module provides a comprehensive error handling system for SAML
  authentication flows, mapping technical SAML errors to user-friendly
  messages while maintaining detailed logs for administrators.
  """

  require Logger

  # Error categories for better organization
  @category_request "Request"
  @category_response "Response"
  @category_config "Configuration"
  @category_identity "Identity"
  @category_session "Session"

  # Error types with metadata
  @error_types %{
    # Request errors
    invalid_request: %{
      category: @category_request,
      user_message: "There was a problem starting the login process. Please try again or contact your administrator.",
      log_level: :warning,
      details: "The SAML authentication request could not be generated."
    },
    missing_idp_config: %{
      category: @category_config,
      user_message: "Single Sign-On is not configured for this organization. Please contact your administrator.",
      log_level: :warning,
      details: "No SAML identity provider configuration found."
    },
    invalid_idp: %{
      category: @category_config,
      user_message: "The identity provider configuration is invalid. Please contact your administrator.",
      log_level: :error,
      details: "Invalid or missing IdP configuration."
    },
    idp_unreachable: %{
      category: @category_config,
      user_message: "Unable to connect to your organization's identity provider. Please try again later or contact your administrator.",
      log_level: :error,
      details: "The IdP SSO endpoint is unreachable."
    },

    # Response errors
    invalid_response_encoding: %{
      category: @category_response,
      user_message: "The authentication response could not be processed. Please try again.",
      log_level: :warning,
      details: "SAML response has invalid encoding."
    },
    invalid_response_signature: %{
      category: @category_response,
      user_message: "The authentication response could not be verified. Please contact your administrator.",
      log_level: :error,
      details: "SAML response signature verification failed."
    },
    invalid_response_issuer: %{
      category: @category_response,
      user_message: "The authentication response came from an unexpected identity provider. Please contact your administrator.",
      log_level: :error,
      details: "SAML response issuer does not match configured IdP."
    },
    response_expired: %{
      category: @category_response,
      user_message: "Your authentication session has expired. Please try logging in again.",
      log_level: :warning,
      details: "SAML assertion is outside its valid time window."
    },
    missing_assertion: %{
      category: @category_response,
      user_message: "The authentication response did not contain the expected information. Please contact your administrator.",
      log_level: :error,
      details: "SAML response is missing required assertion."
    },
    invalid_assertion_attributes: %{
      category: @category_response,
      user_message: "Your account is missing required information. Please contact your administrator.",
      log_level: :warning,
      details: "SAML assertion does not contain required user attributes."
    },

    # Identity errors
    missing_email: %{
      category: @category_identity,
      user_message: "Your account information is incomplete. Please contact your administrator.",
      log_level: :warning,
      details: "SAML assertion does not contain email address."
    },
    email_mismatch: %{
      category: @category_identity,
      user_message: "The email address in the authentication response does not match your account. Please contact your administrator.",
      log_level: :warning,
      details: "SAML email does not match expected value."
    },
    user_not_found: %{
      category: @category_identity,
      user_message: "No account was found for your email address. Please contact your administrator to set up your account.",
      log_level: :info,
      details: "User does not exist in the system."
    },
    user_disabled: %{
      category: @category_identity,
      user_message: "Your account has been disabled. Please contact your administrator.",
      log_level: :warning,
      details: "User account is disabled."
    },
    user_not_sso: %{
      category: @category_identity,
      user_message: "This account is not configured for Single Sign-On. Please use your email and password to log in.",
      log_level: :info,
      details: "User exists but is not an SSO user."
    },

    # Session errors
    session_creation_failed: %{
      category: @category_session,
      user_message: "There was a problem creating your session. Please try again.",
      log_level: :error,
      details: "Failed to create user session after SAML authentication."
    },
    session_expired: %{
      category: @category_session,
      user_message: "Your session has expired. Please log in again.",
      log_level: :info,
      details: "User session has expired."
    },

    # Generic fallback
    unknown: %{
      category: "Unknown",
      user_message: "An unexpected error occurred during authentication. Please try again or contact your administrator.",
      log_level: :error,
      details: "Unknown SAML authentication error."
    }
  }

  @doc """
  Create an error tuple with user-friendly message and logging.

  ## Examples

      iex> SSOError.error(:invalid_response_signature, %{integration_id: "123"})
      {:error, :invalid_response_signature}

  """
  def error(error_type, metadata \\ %{}) do
    error_info = Map.get(@error_types, error_type, @error_types[:unknown])
    log_error(error_type, error_info, metadata)
    {:error, error_type, error_info.user_message, metadata}
  end

  @doc """
  Create an error tuple compatible with existing code patterns.

  Returns a simple error tuple for backwards compatibility.
  """
  def error_tuple(error_type, metadata \\ %{}) do
    error_info = Map.get(@error_types, error_type, @error_types[:unknown])
    log_error(error_type, error_info, metadata)
    {:error, error_type}
  end

  @doc """
  Get the user-friendly message for an error type.
  """
  def user_message(error_type) do
    error_info = Map.get(@error_types, error_type, @error_types[:unknown])
    error_info.user_message
  end

  @doc """
  Get detailed information about an error type (for admin logs).
  """
  def error_details(error_type) do
    error_info = Map.get(@error_types, error_type, @error_types[:unknown])
    %{
      category: error_info.category,
      user_message: error_info.user_message,
      technical_details: error_info.details,
      log_level: error_info.log_level
    }
  end

  @doc """
  Check if an error is retryable (user can try again).
  """
  def retryable?(:invalid_request), do: true
  def retryable?(:invalid_response_encoding), do: true
  def retryable?(:response_expired), do: true
  def retryable?(:idp_unreachable), do: true
  def retryable?(:session_creation_failed), do: true
  def retryable?(_), do: false

  @doc """
  Check if an error requires admin intervention.
  """
  def requires_admin?(:missing_idp_config), do: true
  def requires_admin?(:invalid_idp), do: true
  def requires_admin?(:invalid_response_signature), do: true
  def requires_admin?(:invalid_response_issuer), do: true
  def requires_admin?(:missing_assertion), do: true
  def requires_admin?(:invalid_assertion_attributes), do: true
  def requires_admin?(:user_not_found), do: true
  def requires_admin?(:user_disabled), do: true
  def requires_admin?(_), do: false

  @doc """
  Extract flash message options from an error.
  """
  def flash_options(error_type) do
    error_info = Map.get(@error_types, error_type, @error_types[:unknown])

    [
      title: error_title(error_type),
      message: error_info.user_message,
      retry: retryable?(error_type),
      requires_admin: requires_admin?(error_type)
    ]
  end

  defp error_title(:invalid_request), do: "Login Request Failed"
  defp error_title(:missing_idp_config), do: "SSO Not Configured"
  defp error_title(:invalid_idp), do: "Identity Provider Error"
  defp error_title(:idp_unreachable), do: "Connection Failed"
  defp error_title(:invalid_response_encoding), do: "Response Error"
  defp error_title(:invalid_response_signature), do: "Verification Failed"
  defp error_title(:invalid_response_issuer), do: "Invalid Identity Provider"
  defp error_title(:response_expired), do: "Session Expired"
  defp error_title(:missing_assertion), do: "Incomplete Response"
  defp error_title(:invalid_assertion_attributes), do: "Missing Information"
  defp error_title(:missing_email), do: "Missing Email"
  defp error_title(:email_mismatch), do: "Email Mismatch"
  defp error_title(:user_not_found), do: "Account Not Found"
  defp error_title(:user_disabled), do: "Account Disabled"
  defp error_title(:user_not_sso), do: "Wrong Login Method"
  defp error_title(:session_creation_failed), do: "Session Error"
  defp error_title(:session_expired), do: "Session Expired"
  defp error_title(_), do: "Authentication Failed"

  defp log_error(error_type, error_info, metadata) do
    logger_metadata = %{
      error_type: error_type,
      category: error_info.category,
      integration_id: metadata[:integration_id],
      email: metadata[:email],
      user_id: metadata[:user_id]
    }

    case error_info.log_level do
      :debug ->
        Logger.debug("SAML error: #{error_info.details}", logger_metadata)
      :info ->
        Logger.info("SAML error: #{error_info.details}", logger_metadata)
      :warning ->
        Logger.warning("SAML error: #{error_info.details}", logger_metadata)
      :error ->
        Logger.error("SAML error: #{error_info.details}", logger_metadata)
      _ ->
        Logger.info("SAML error: #{error_info.details}", logger_metadata)
    end
  end

  @doc """
  Convert a raw SAML library error to our standardized error type.
  """
  def standardize_error(raw_error) when is_atom(raw_error) do
    case raw_error do
      # SAML library errors
      :invalid_signature -> :invalid_response_signature
      :invalid_issuer -> :invalid_response_issuer
      :expired -> :response_expired
      :invalid_assertion -> :invalid_assertion_attributes
      :missing_email -> :missing_email
      :missing_nameid -> :missing_assertion

      # Network/connection errors
      :connection_refused -> :idp_unreachable
      :timeout -> :idp_unreachable
      :nxdomain -> :idp_unreachable

      # Generic
      _ -> :unknown
    end
  end

  def standardize_error(_), do: :unknown
end
