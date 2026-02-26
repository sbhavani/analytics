defmodule Plausible.Auth.SAMLConfigTest do
  use Plausible.DataCase, async: true

  on_ee do
    alias Plausible.Auth.SSO

    # Helper function to build SAML Response XML for testing
    defp build_saml_response_xml(opts) when is_list(opts) do
      issuer = Keyword.get(opts, :issuer, "https://idp.example.com/entity")
      email = Keyword.get(opts, :email, "user@example.com")
      name = Keyword.get(opts, :name, "Test User")
      name_id = Keyword.get(opts, :name_id, "user-123")
      email_attr = Keyword.get(opts, :email_attr, "email")
      name_attr = Keyword.get(opts, :name_attr, "name")
      include_attrs = Keyword.get(opts, :include_attrs, true)

      issue_instant = DateTime.utc_now() |> DateTime.to_iso8601()

      attributes_xml = if include_attrs do
        """
        <saml:AttributeStatement>
          <saml:Attribute Name="#{email_attr}" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
            <saml:AttributeValue>#{email}</saml:AttributeValue>
          </saml:Attribute>
          <saml:Attribute Name="#{name_attr}" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
            <saml:AttributeValue>#{name}</saml:AttributeValue>
          </saml:Attribute>
        </saml:AttributeStatement>
        """
      else
        ""
      end

      """
      <?xml version="1.0" encoding="UTF-8"?>
      <samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
                      xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
                      ID="_#{:crypto.strong_rand_bytes(16) |> Base.encode16()}"
                      Version="2.0"
                      IssueInstant="#{issue_instant}"
                      Destination="https://plausible.example.com/sso/saml/consume/test">
        <saml:Issuer>#{issuer}</saml:Issuer>
        <samlp:Status>
          <samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/>
        </samlp:Status>
        <saml:Assertion ID="_#{:crypto.strong_rand_bytes(16) |> Base.encode16()}"
                        Version="2.0"
                        IssueInstant="#{issue_instant}">
          <saml:Issuer>#{issuer}</saml:Issuer>
          <saml:Subject>
            <saml:NameID>#{name_id}</saml:NameID>
          </saml:Subject>
          <saml:Conditions NotBefore="#{issue_instant}" NotOnOrAfter="#{issue_instant}"/>
          #{attributes_xml}
        </saml:Assertion>
      </samlp:Response>
      """
    end

    @cert_pem """
    -----BEGIN CERTIFICATE-----
    MIIFdTCCA12gAwIBAgIUNcATm3CidmlEMMsZa9KBZpWYCVcwDQYJKoZIhvcNAQEL
    BQAwYzELMAkGA1UEBhMCQVUxEzARBgNVBAgMClNvbWUtU3RhdGUxITAfBgNVBAoM
    GEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDEcMBoGA1UEAwwTc29tZWlkcC5leGFt
    cGxlLmNvbTAeFw0yNTA1MjExMjI5MzVaFw0yNjA1MjExMjI5MzVaMGMxCzAJBgNV
    BAYTAkFVMRMwEQYDVQQIDApTb21lLVN0YXRlMSEwHwYDVQQKDBhJbnRlcm5ldCBX
    aWRnaXRzIFB0eSBMdGQxHDAaBgNVBAMME3NvbWVpZHAuZXhhbXBsZS5jb20wggIi
    MA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQC1N6Drbjed+lFXpOYvE6Efgndy
    W7kYiO8LqQTr4UwVrp9ArxgYuK4TrcNRh2rhS08xAzNTo+NqnJOm95baG97ADYk1
    TqVIKxzaFurv+L/Na0wVXyeNUtxIVKF59uElsg2YLm5eQhL9fmN8jVINCvwDPzxc
    Ihm6mQOaL/i/0DGINOqwHG9MGMZ11AeOM0wKMuXJ2+aKjHOCedhMYVuOaHZgLkcX
    Zzgiv7itm3+JpCjL474MMfibiqKHR0e3QRNcsEC13f/LD8BAGOwsKLznFC8Uctms
    48EDNbxxLG01jVbnJSxRrcDN3RUDjtCdHyaTCCFJAgmldHKKua3VQEynOwJIkFMC
    fpL1LpLvATzIt0cT1ESb1RHIlgacmESVn/TW2QjO5tp4FAu7GJK+5xY7jPvI6saG
    oUHsk0zo9obLK8WYneF19ln+Ea5ZCl9PcTi559AKGpYzpL/9uxoPT1zxxTn6c2lt
    4xkxkuHtYqi/ENHGdo4CLBL93GDZEilSVmZjD/9N9990yWbPXXQ0eNoFckYSZuls
    HaWz8W5c046/ob8mASI6wzAUCkO9Zz4WbIj9A+mNZB32hMZbMA02gU//ffvNkFjL
    DGlNbROCg2DX64rvGs/RuqhuDVCnVfid9B36Cgs76GWI8dCInEfyZMtiqUb7E8Oe
    BPVwtTscz1StlF/0cQIDAQABoyEwHzAdBgNVHQ4EFgQU9lvXH4X04v99rrwKNzsw
    pNQP/dUwDQYJKoZIhvcNAQELBQADggIBAJD0MD+OK58vlP2HEoKLQYAKYM/4NsBz
    vSK1PtZsEj0fqiuu66ceH0wlKlGquRad4Z+LXMptu1DzMNmJsf0zSQfleGFks3xI
    86hgkQ7f0qjs+YJzjJUxF9H8zX4jJk5poOqOJwStHBCDLsUmIxnT7/il3jlT0Nj4
    cVs4946pCg7rP1kR9jojFD5yvzKoRBJG3/qvFnzAi8cDv9CRjSgoDTZyzZmwdCgu
    NioW7YeFCtvYxvY7HDXinwq/w8Gn3n8zdISoAqSpYrt5Y5ygJGiEYVDWdA50a6PC
    gq5xt8RCizz1L7a5BUJFMCQ0pyAUuODTndPUGLT8i7jFgzhamFPD72zFMk2+IabE
    Dutyt2GFeTQ75wL8QvfsKm29Vd5EjAsdfmup3hCpLGqF3g8Sh0aXDrj8KPqIecuS
    gkL69M9iXfnwZhTo23zUuFjBNoAIPXkNKXiJS7p9IEpYRVnlPYLToSEnnzptoPPQ
    zMBb8x/UMMtNYkyehSLhuIPrRLvv3eth7Hq3hA7tOCRyyf78tReVm+VoRx6AK68v
    5ufxMKBFRTNoLIN3sD+DmSUNY+CaHxRMDhSESy0Ac/95J2yKi+Y1Kml2GV53pSlT
    6FPm8B0R9YXM7lHhTLyL7DYqnvklkLh2bUqCLyBowynPyGqdYV4DbFSiST14fGXR
    mNEYF78kg0IA
    -----END CERTIFICATE-----
    """

    describe "build_authn_request/2" do
      test "generates a valid SAML AuthnRequest redirect URL" do
        integration = SSO.initiate_saml_integration(new_site().team)

        {:ok, integration} =
          SSO.update_integration(integration, %{
            idp_signin_url: "https://idp.example.com/sso",
            idp_entity_id: "https://idp.example.com/entity",
            idp_cert_pem: @cert_pem
          })

        acs_url = PlausibleWeb.Endpoint.url() <> "/sso/saml/consume/#{integration.identifier}"

        {:ok, redirect_url} = SSO.SAML.build_authn_request(integration, acs_url)

        # Verify redirect URL structure
        assert redirect_url =~ "https://idp.example.com/sso"
        assert redirect_url =~ "SAMLRequest="

        # Extract and decode SAMLRequest
        %{query: query} = URI.parse(redirect_url)
        params = URI.decode_query(query)
        saml_request = Map.get(params, "SAMLRequest")

        assert saml_request != nil

        # Decode and verify XML structure
        {:ok, decoded} = Base.decode64(saml_request)

        assert decoded =~ "samlp:AuthnRequest"
        assert decoded =~ "Version=\"2.0\""
        assert decoded =~ "AssertionConsumerServiceURL=\"#{acs_url}\""
        assert decoded =~ "saml:Issuer"
      end

      test "generates unique request IDs for each request" do
        integration = SSO.initiate_saml_integration(new_site().team)

        {:ok, integration} =
          SSO.update_integration(integration, %{
            idp_signin_url: "https://idp.example.com/sso",
            idp_entity_id: "https://idp.example.com/entity",
            idp_cert_pem: @cert_pem
          })

        acs_url = PlausibleWeb.Endpoint.url() <> "/sso/saml/consume/#{integration.identifier}"

        {:ok, redirect_url1} = SSO.SAML.build_authn_request(integration, acs_url)
        {:ok, redirect_url2} = SSO.SAML.build_authn_request(integration, acs_url)

        # Extract SAMLRequest from both URLs
        %{query: query1} = URI.parse(redirect_url1)
        %{query: query2} = URI.parse(redirect_url2)

        saml_request1 = URI.decode_query(query1) |> Map.get("SAMLRequest")
        saml_request2 = URI.decode_query(query2) |> Map.get("SAMLRequest")

        # Decode and check IDs are different
        {:ok, decoded1} = Base.decode64(saml_request1)
        {:ok, decoded2} = Base.decode64(saml_request2)

        # Extract IDs using regex
        [_, id1 | _] = Regex.run(~r/ID="([^"]+)"/, decoded1)
        [_, id2 | _] = Regex.run(~r/ID="([^"]+)"/, decoded2)

        assert id1 != id2
      end

      test "includes correct IssueInstant timestamp" do
        integration = SSO.initiate_saml_integration(new_site().team)

        {:ok, integration} =
          SSO.update_integration(integration, %{
            idp_signin_url: "https://idp.example.com/sso",
            idp_entity_id: "https://idp.example.com/entity",
            idp_cert_pem: @cert_pem
          })

        acs_url = PlausibleWeb.Endpoint.url() <> "/sso/saml/consume/#{integration.identifier}"

        now = DateTime.utc_now()
        {:ok, redirect_url} = SSO.SAML.build_authn_request(integration, acs_url, now: now)

        %{query: query} = URI.parse(redirect_url)
        saml_request = URI.decode_query(query) |> Map.get("SAMLRequest")
        {:ok, decoded} = Base.decode64(saml_request)

        # IssueInstant should be close to the provided time
        assert decoded =~ "IssueInstant=\"#{now |> DateTime.to_iso8601()}"
      end

      test "returns error when integration is not configured" do
        integration = SSO.initiate_saml_integration(new_site().team)
        acs_url = PlausibleWeb.Endpoint.url() <> "/sso/saml/consume/#{integration.identifier}"

        assert {:error, :not_configured} = SSO.SAML.build_authn_request(integration, acs_url)
      end

      test "includes RelayState when provided" do
        integration = SSO.initiate_saml_integration(new_site().team)

        {:ok, integration} =
          SSO.update_integration(integration, %{
            idp_signin_url: "https://idp.example.com/sso",
            idp_entity_id: "https://idp.example.com/entity",
            idp_cert_pem: @cert_pem
          })

        acs_url = PlausibleWeb.Endpoint.url() <> "/sso/saml/consume/#{integration.identifier}"
        relay_state = "https://plausible.example.com/dashboard"

        {:ok, redirect_url} =
          SSO.SAML.build_authn_request(integration, acs_url, relay_state: relay_state)

        %{query: query} = URI.parse(redirect_url)
        params = URI.decode_query(query)

        assert Map.has_key?(params, "RelayState")
        assert params["RelayState"] == relay_state
      end
    end

    describe "parse_response/2" do
      setup do
        integration = SSO.initiate_saml_integration(new_site().team)

        {:ok, integration} =
          SSO.update_integration(integration, %{
            idp_signin_url: "https://idp.example.com/sso",
            idp_entity_id: "https://idp.example.com/entity",
            idp_cert_pem: @cert_pem
          })

        {:ok, integration: integration}
      end

      test "parses a valid SAML response and extracts attributes", %{integration: integration} do
        # Build a valid SAML response XML
        saml_response_xml = build_saml_response_xml(issuer: "https://idp.example.com/entity",
          email: "user@example.com",
          name: "Test User",
          name_id: "user-123"
        )

        # Base64 encode the response
        encoded_response = Base.encode64(saml_response_xml)

        {:ok, attrs} = SSO.SAML.parse_response(encoded_response, integration)

        assert attrs["email"] == "user@example.com"
        assert attrs["name"] == "Test User"
        assert attrs["name_id"] == "user-123"
      end

      test "returns error for invalid base64 encoding", %{integration: integration} do
        invalid_base64 = "not-valid-base64!!!"

        assert {:error, :invalid_encoding} = SSO.SAML.parse_response(invalid_base64, integration)
      end

      test "returns error when issuer does not match configured IdP", %{integration: integration} do
        # Response with wrong issuer
        saml_response_xml = build_saml_response_xml(issuer: "https://wrong-idp.example.com/entity",
          email: "user@example.com",
          name_id: "user-123"
        )

        encoded_response = Base.encode64(saml_response_xml)

        assert {:error, :invalid_issuer} = SSO.SAML.parse_response(encoded_response, integration)
      end

      test "extracts attributes with custom attribute names", %{integration: integration} do
        # Response with custom attribute names (some IdPs use different names)
        saml_response_xml = build_saml_response_xml(issuer: "https://idp.example.com/entity",
          email: "user@example.com",
          name: "Test User",
          name_id: "user-123",
          email_attr: "UserEmail",
          name_attr: "displayName"
        )

        encoded_response = Base.encode64(saml_response_xml)

        {:ok, attrs} = SSO.SAML.parse_response(encoded_response, integration)

        assert attrs["email"] == "user@example.com"
        assert attrs["name"] == "Test User"
      end

      test "handles response without attributes", %{integration: integration} do
        # Response with only NameID
        saml_response_xml = build_saml_response_xml(issuer: "https://idp.example.com/entity",
          name_id: "user-123",
          include_attrs: false
        )

        encoded_response = Base.encode64(saml_response_xml)

        {:ok, attrs} = SSO.SAML.parse_response(encoded_response, integration)

        assert attrs["name_id"] == "user-123"
      end
    end

    describe "entity_id/1" do
      test "returns correct entity ID for integration" do
        integration = SSO.initiate_saml_integration(new_site().team)
        expected_entity_id = PlausibleWeb.Endpoint.url() <> "/sso/" <> integration.identifier

        assert SSO.SAMLConfig.entity_id(integration) == expected_entity_id
      end
    end

    describe "configured?/1" do
      test "returns true when all required fields are present" do
        config = %SSO.SAMLConfig{
          idp_signin_url: "https://idp.example.com/sso",
          idp_entity_id: "https://idp.example.com/entity",
          idp_cert_pem: @cert_pem
        }

        assert SSO.SAMLConfig.configured?(config)
      end

      test "returns false when idp_signin_url is missing" do
        config = %SSO.SAMLConfig{
          idp_signin_url: nil,
          idp_entity_id: "https://idp.example.com/entity",
          idp_cert_pem: @cert_pem
        }

        refute SSO.SAMLConfig.configured?(config)
      end

      test "returns false when idp_entity_id is missing" do
        config = %SSO.SAMLConfig{
          idp_signin_url: "https://idp.example.com/sso",
          idp_entity_id: nil,
          idp_cert_pem: @cert_pem
        }

        refute SSO.SAMLConfig.configured?(config)
      end

      test "returns false when idp_cert_pem is missing" do
        config = %SSO.SAMLConfig{
          idp_signin_url: "https://idp.example.com/sso",
          idp_entity_id: "https://idp.example.com/entity",
          idp_cert_pem: nil
        }

        refute SSO.SAMLConfig.configured?(config)
      end
    end
  end
end
