defmodule Plausible.Auth.SSO.ContextTest do
  use Plausible.DataCase, async: true

  @moduletag :ee_only

  on_ee do
    alias Plausible.Auth.SSO
    alias Plausible.Auth.SSO.Identity
    alias PlausibleWeb.SSO.RealSAMLAdapter

    describe "user attribute mapping from SAML assertions" do
      setup do
        team = new_site().team
        integration = SSO.initiate_saml_integration(team)

        {:ok, integration: integration}
      end

      test "maps SAML attributes to Identity struct correctly", %{
        integration: integration
      } do
        # Simulate SAML assertion attributes as they would come from the IdP
        assertion = %{
          name_id: "user123",
          attributes: %{
            "email" => ["john.doe@example.com"],
            "first_name" => ["John"],
            "last_name" => ["Doe"]
          }
        }

        {:ok, attributes} = RealSAMLAdapter.extract_attributes(assertion)

        # Map attributes to Identity struct (as done in RealSAMLAdapter.consume/5)
        identity = %Identity{
          id: assertion.name_id,
          integration_id: integration.identifier,
          name: RealSAMLAdapter.name_from_attributes(attributes),
          email: attributes.email,
          expires_at: NaiveDateTime.add(NaiveDateTime.utc_now(:second), 60, :minute)
        }

        assert identity.id == "user123"
        assert identity.integration_id == integration.identifier
        assert identity.name == "John Doe"
        assert identity.email == "john.doe@example.com"
        assert identity.expires_at
      end

      test "maps attributes with only first name", %{
        integration: integration
      } do
        assertion = %{
          name_id: "user456",
          attributes: %{
            "email" => ["jane@example.com"],
            "first_name" => ["Jane"],
            "last_name" => [""]
          }
        }

        {:ok, attributes} = RealSAMLAdapter.extract_attributes(assertion)

        identity = %Identity{
          id: assertion.name_id,
          integration_id: integration.identifier,
          name: RealSAMLAdapter.name_from_attributes(attributes),
          email: attributes.email,
          expires_at: NaiveDateTime.add(NaiveDateTime.utc_now(:second), 60, :minute)
        }

        assert identity.name == "Jane"
      end

      test "maps attributes with only last name", %{
        integration: integration
      } do
        assertion = %{
          name_id: "user789",
          attributes: %{
            "email" => ["smith@example.com"],
            "first_name" => [""],
            "last_name" => ["Smith"]
          }
        }

        {:ok, attributes} = RealSAMLAdapter.extract_attributes(assertion)

        identity = %Identity{
          id: assertion.name_id,
          integration_id: integration.identifier,
          name: RealSAMLAdapter.name_from_attributes(attributes),
          email: attributes.email,
          expires_at: NaiveDateTime.add(NaiveDateTime.utc_now(:second), 60, :minute)
        }

        assert identity.name == "Smith"
      end

      test "maps attributes with trimmed whitespace", %{
        integration: integration
      } do
        assertion = %{
          name_id: "user111",
          attributes: %{
            "email" => ["  trimmed@example.com  "],
            "first_name" => ["  John  "],
            "last_name" => ["  Doe  "]
          }
        }

        {:ok, attributes} = RealSAMLAdapter.extract_attributes(assertion)

        identity = %Identity{
          id: assertion.name_id,
          integration_id: integration.identifier,
          name: RealSAMLAdapter.name_from_attributes(attributes),
          email: attributes.email,
          expires_at: NaiveDateTime.add(NaiveDateTime.utc_now(:second), 60, :minute)
        }

        # Email and names should be trimmed
        assert identity.email == "trimmed@example.com"
        assert identity.name == "John Doe"
      end

      test "preserves email with plus addressing", %{
        integration: integration
      } do
        assertion = %{
          name_id: "user222",
          attributes: %{
            "email" => ["user+tag@company.com"],
            "first_name" => ["Test"],
            "last_name" => ["User"]
          }
        }

        {:ok, attributes} = RealSAMLAdapter.extract_attributes(assertion)

        identity = %Identity{
          id: assertion.name_id,
          integration_id: integration.identifier,
          name: RealSAMLAdapter.name_from_attributes(attributes),
          email: attributes.email,
          expires_at: NaiveDateTime.add(NaiveDateTime.utc_now(:second), 60, :minute)
        }

        assert identity.email == "user+tag@company.com"
      end

      test "uses name_id as identity id", %{
        integration: integration
      } do
        assertion = %{
          name_id: "urn:oid:0.9.2342.19200300.100.1.1:user123",
          attributes: %{
            "email" => ["user@example.com"],
            "first_name" => ["John"],
            "last_name" => ["Doe"]
          }
        }

        {:ok, attributes} = RealSAMLAdapter.extract_attributes(assertion)

        identity = %Identity{
          id: assertion.name_id,
          integration_id: integration.identifier,
          name: RealSAMLAdapter.name_from_attributes(attributes),
          email: attributes.email,
          expires_at: NaiveDateTime.add(NaiveDateTime.utc_now(:second), 60, :minute)
        }

        assert identity.id == "urn:oid:0.9.2342.19200300.100.1.1:user123"
      end
    end

    describe "Identity provisioning from mapped attributes" do
      setup do
        team = new_site().team
        integration = SSO.initiate_saml_integration(team)
        domain = "example-#{Enum.random(1..10_000)}.com"

        {:ok, sso_domain} = SSO.Domains.add(integration, domain)
        sso_domain = SSO.Domains.verify(sso_domain, skip_checks?: true)

        {:ok,
         team: team,
         integration: integration,
         domain: domain,
         sso_domain: sso_domain}
      end

      test "provisions user with mapped SAML attributes", %{
        integration: integration,
        domain: domain,
        sso_domain: sso_domain
      } do
        # Create identity with SAML-mapped attributes
        identity = %Identity{
          id: "saml-user-123",
          integration_id: integration.identifier,
          name: "John Doe",
          email: "john@" <> domain,
          expires_at: NaiveDateTime.add(NaiveDateTime.utc_now(:second), 60, :minute)
        }

        assert {:ok, :identity, team, user} = SSO.provision_user(identity)

        assert user.email == "john@" <> domain
        assert user.name == "John Doe"
        assert user.type == :sso
        assert user.sso_identity_id == "saml-user-123"
        assert user.sso_integration_id == integration.id
        assert user.sso_domain_id == sso_domain.id
        assert user.email_verified
        assert user.last_sso_login
      end

      test "updates existing SSO user with new SAML attributes", %{
        integration: integration,
        team: team,
        domain: domain,
        sso_domain: sso_domain
      } do
        # First provisioning
        identity1 = %Identity{
          id: "saml-user-456",
          integration_id: integration.identifier,
          name: "John Doe",
          email: "john@" <> domain,
          expires_at: NaiveDateTime.add(NaiveDateTime.utc_now(:second), 60, :minute)
        }

        {:ok, :identity, _team, user} = SSO.provision_user(identity1)
        original_user_id = user.id

        # Re-provisioning with updated attributes (e.g., name change in IdP)
        identity2 = %Identity{
          id: "saml-user-456",
          integration_id: integration.identifier,
          name: "John Updated Doe",
          email: "john@" <> domain,
          expires_at: NaiveDateTime.add(NaiveDateTime.utc_now(:second), 60, :minute)
        }

        assert {:ok, :sso, _team, updated_user} = SSO.provision_user(identity2)

        assert updated_user.id == original_user_id
        assert updated_user.name == "John Updated Doe"
        assert updated_user.email == "john@" <> domain
        assert updated_user.sso_identity_id == "saml-user-456"
        assert updated_user.last_sso_login
      end

      test "converts standard user to SSO user with mapped attributes", %{
        integration: integration,
        team: team,
        domain: domain,
        sso_domain: sso_domain
      } do
        # Create a standard user
        user = new_user(email: "existing@" <> domain, name: "Existing User")
        add_member(team, user: user, role: :editor)

        # Create identity from SAML attributes
        identity = %Identity{
          id: "saml-converted-123",
          integration_id: integration.identifier,
          name: "Converted Name",
          email: "existing@" <> domain,
          expires_at: NaiveDateTime.add(NaiveDateTime.utc_now(:second), 60, :minute)
        }

        assert {:ok, :standard, _team, converted_user} = SSO.provision_user(identity)

        assert converted_user.id == user.id
        assert converted_user.type == :sso
        assert converted_user.name == "Converted Name"
        assert converted_user.sso_identity_id == "saml-converted-123"
        assert converted_user.sso_integration_id == integration.id
      end

      test "preserves session timeout from team policy", %{
        integration: integration,
        domain: domain,
        sso_domain: sso_domain
      } do
        # Set custom session timeout
        {:ok, _team} =
          SSO.update_policy(integration.team, sso_session_timeout_minutes: 120)

        now = NaiveDateTime.utc_now(:second)
        expected_expires_at = NaiveDateTime.add(now, 120, :minute)

        identity = %Identity{
          id: "saml-session-123",
          integration_id: integration.identifier,
          name: "Session Test",
          email: "session@" <> domain,
          expires_at: expected_expires_at
        }

        assert {:ok, :identity, team, _user} = SSO.provision_user(identity)

        # Verify the team policy was updated with the 120 minute timeout
        assert team.policy.sso_session_timeout_minutes == 120
      end
    end
  end
end
