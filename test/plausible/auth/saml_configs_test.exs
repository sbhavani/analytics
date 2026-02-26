defmodule Plausible.Auth.SAMLConfigsTest do
  use Plausible.DataCase, async: true

  on_ee do
    alias Plausible.Auth.SSO

    describe "validate_config/1" do
      test "returns :ok for valid config" do
        config = %{
          idp_entity_id: "https://idp.example.com/metadata",
          idp_sso_url: "https://idp.example.com/sso",
          idp_certificate: "-----BEGIN CERTIFICATE-----\nMIID...\n-----END CERTIFICATE-----"
        }

        assert SSO.validate_config(config) == :ok
      end

      test "returns :ok with atom keys" do
        config = %{
          idp_entity_id: "https://idp.example.com/metadata",
          idp_sso_url: "https://idp.example.com/sso",
          idp_certificate: "-----BEGIN CERTIFICATE-----\nMIID...\n-----END CERTIFICATE-----"
        }

        assert SSO.validate_config(config) == :ok
      end

      test "returns error for missing idp_entity_id" do
        config = %{
          idp_entity_id: nil,
          idp_sso_url: "https://idp.example.com/sso",
          idp_certificate: "-----BEGIN CERTIFICATE-----\nMIID...\n-----END CERTIFICATE-----"
        }

        assert {:error, errors} = SSO.validate_config(config)
        assert {:idp_entity_id, "must be present"} in errors
      end

      test "returns error for missing idp_sso_url" do
        config = %{
          idp_entity_id: "https://idp.example.com/metadata",
          idp_sso_url: nil,
          idp_certificate: "-----BEGIN CERTIFICATE-----\nMIID...\n-----END CERTIFICATE-----"
        }

        assert {:error, errors} = SSO.validate_config(config)
        assert {:idp_sso_url, "must be present"} in errors
      end

      test "returns error for missing idp_certificate" do
        config = %{
          idp_entity_id: "https://idp.example.com/metadata",
          idp_sso_url: "https://idp.example.com/sso",
          idp_certificate: nil
        }

        assert {:error, errors} = SSO.validate_config(config)
        assert {:idp_certificate, "must be present"} in errors
      end

      test "returns error for empty idp_entity_id" do
        config = %{
          idp_entity_id: "",
          idp_sso_url: "https://idp.example.com/sso",
          idp_certificate: "-----BEGIN CERTIFICATE-----\nMIID...\n-----END CERTIFICATE-----"
        }

        assert {:error, errors} = SSO.validate_config(config)
        assert {:idp_entity_id, "must be present"} in errors
      end

      test "returns error for empty idp_sso_url" do
        config = %{
          idp_entity_id: "https://idp.example.com/metadata",
          idp_sso_url: "",
          idp_certificate: "-----BEGIN CERTIFICATE-----\nMIID...\n-----END CERTIFICATE-----"
        }

        assert {:error, errors} = SSO.validate_config(config)
        assert {:idp_sso_url, "must be present"} in errors
      end

      test "returns error for empty idp_certificate" do
        config = %{
          idp_entity_id: "https://idp.example.com/metadata",
          idp_sso_url: "https://idp.example.com/sso",
          idp_certificate: ""
        }

        assert {:error, errors} = SSO.validate_config(config)
        assert {:idp_certificate, "must be present"} in errors
      end

      test "returns multiple errors when multiple fields are missing" do
        config = %{
          idp_entity_id: nil,
          idp_sso_url: nil,
          idp_certificate: nil
        }

        assert {:error, errors} = SSO.validate_config(config)
        assert length(errors) == 3
        assert {:idp_entity_id, "must be present"} in errors
        assert {:idp_sso_url, "must be present"} in errors
        assert {:idp_certificate, "must be present"} in errors
      end
    end
  end
end
