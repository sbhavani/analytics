defmodule Plausible.Auth.SSO.SAMLTest do
  use Plausible.DataCase, async: true

  @moduletag :ee_only

  on_ee do
    alias PlausibleWeb.SSO.RealSAMLAdapter

    describe "extract_attributes/1" do
      test "extracts email, first_name, and last_name from SAML assertion attributes" do
        assertion = %{
          attributes: %{
            "email" => ["user@example.com"],
            "first_name" => ["John"],
            "last_name" => ["Doe"]
          }
        }

        assert {:ok, attributes} = RealSAMLAdapter.extract_attributes(assertion)

        assert attributes.email == "user@example.com"
        assert attributes.first_name == "John"
        assert attributes.last_name == "Doe"
      end

      test "handles missing optional name attributes" do
        assertion = %{
          attributes: %{
            "email" => ["user@example.com"]
          }
        }

        assert {:ok, attributes} = RealSAMLAdapter.extract_attributes(assertion)

        assert attributes.email == "user@example.com"
        assert attributes.first_name == ""
        assert attributes.last_name == ""
      end

      test "handles empty attribute values" do
        assertion = %{
          attributes: %{
            "email" => [""],
            "first_name" => [""],
            "last_name" => [""]
          }
        }

        assert {:ok, attributes} = RealSAMLAdapter.extract_attributes(assertion)

        assert attributes.email == ""
        assert attributes.first_name == ""
        assert attributes.last_name == ""
      end

      test "trims whitespace from attribute values" do
        assertion = %{
          attributes: %{
            "email" => ["  user@example.com  "],
            "first_name" => ["  John  "],
            "last_name" => ["  Doe  "]
          }
        }

        assert {:ok, attributes} = RealSAMLAdapter.extract_attributes(assertion)

        assert attributes.email == "user@example.com"
        assert attributes.first_name == "John"
        assert attributes.last_name == "Doe"
      end

      test "returns error when email attribute is missing" do
        assertion = %{
          attributes: %{
            "first_name" => ["John"],
            "last_name" => ["Doe"]
          }
        }

        assert {:error, :missing_email_attribute} = RealSAMLAdapter.extract_attributes(assertion)
      end

      test "returns error when email attribute is empty string" do
        assertion = %{
          attributes: %{
            "email" => [""],
            "first_name" => ["John"],
            "last_name" => ["Doe"]
          }
        }

        assert {:error, :missing_email_attribute} = RealSAMLAdapter.extract_attributes(assertion)
      end

      test "returns error when email is invalid (no @ symbol)" do
        assertion = %{
          attributes: %{
            "email" => ["invalid-email"],
            "first_name" => ["John"],
            "last_name" => ["Doe"]
          }
        }

        assert {:error, :invalid_email_attribute} = RealSAMLAdapter.extract_attributes(assertion)
      end

      test "returns error when email is too short" do
        assertion = %{
          attributes: %{
            "email" => ["a@b"],
            "first_name" => ["John"],
            "last_name" => ["Doe"]
          }
        }

        assert {:error, :invalid_email_attribute} = RealSAMLAdapter.extract_attributes(assertion)
      end

      test "returns error when both first_name and last_name are missing" do
        assertion = %{
          attributes: %{
            "email" => ["user@example.com"]
          }
        }

        assert {:error, :missing_name_attributes} = RealSAMLAdapter.extract_attributes(assertion)
      end

      test "allows email with plus addressing" do
        assertion = %{
          attributes: %{
            "email" => ["user+tag@example.com"],
            "first_name" => ["John"],
            "last_name" => ["Doe"]
          }
        }

        assert {:ok, attributes} = RealSAMLAdapter.extract_attributes(assertion)
        assert attributes.email == "user+tag@example.com"
      end

      test "allows email with subdomain" do
        assertion = %{
          attributes: %{
            "email" => ["user@mail.example.com"],
            "first_name" => ["John"],
            "last_name" => ["Doe"]
          }
        }

        assert {:ok, attributes} = RealSAMLAdapter.extract_attributes(assertion)
        assert attributes.email == "user@mail.example.com"
      end
    end

    describe "name_from_attributes/1" do
      test "combines first and last name with a space" do
        attributes = %{first_name: "John", last_name: "Doe"}

        assert RealSAMLAdapter.name_from_attributes(attributes) == "John Doe"
      end

      test "handles only first name" do
        attributes = %{first_name: "John", last_name: ""}

        assert RealSAMLAdapter.name_from_attributes(attributes) == "John"
      end

      test "handles only last name" do
        attributes = %{first_name: "", last_name: "Doe"}

        assert RealSAMLAdapter.name_from_attributes(attributes) == "Doe"
      end

      test "handles empty names" do
        attributes = %{first_name: "", last_name: ""}

        assert RealSAMLAdapter.name_from_attributes(attributes) == ""
      end

      test "trims whitespace from names" do
        attributes = %{first_name: "  John  ", last_name: "  Doe  "}

        assert RealSAMLAdapter.name_from_attributes(attributes) == "John Doe"
      end

      test "handles nil values" do
        attributes = %{first_name: nil, last_name: nil}

        assert RealSAMLAdapter.name_from_attributes(attributes) == ""
      end

      test "handles multiple names in each field (takes first)" do
        attributes = %{first_name: "John Michael", last_name: "Doe Smith"}

        assert RealSAMLAdapter.name_from_attributes(attributes) == "John Michael Doe Smith"
      end
    end

    describe "validate_authresp/2" do
      test "validates matching relay state with 32-byte value" do
        cookie = %{relay_state: String.duplicate("a", 32)}

        assert :ok = RealSAMLAdapter.validate_authresp(cookie, cookie.relay_state)
      end

      test "returns error for mismatched relay state" do
        cookie = %{relay_state: String.duplicate("a", 32)}

        assert {:error, :invalid_relay_state} =
                 RealSAMLAdapter.validate_authresp(cookie, "different_state")
      end

      test "returns error for relay state that is too short" do
        cookie = %{relay_state: "short"}

        assert {:error, :invalid_relay_state} =
                 RealSAMLAdapter.validate_authresp(cookie, "short")
      end

      test "returns error for relay state that is too long" do
        cookie = %{relay_state: String.duplicate("a", 33)}

        assert {:error, :invalid_relay_state} =
                 RealSAMLAdapter.validate_authresp(cookie, String.duplicate("a", 33))
      end

      test "returns error for empty relay state" do
        cookie = %{relay_state: ""}

        assert {:error, :invalid_relay_state} =
                 RealSAMLAdapter.validate_authresp(cookie, "")
      end

      test "returns error when cookie is nil" do
        assert {:error, :invalid_relay_state} =
                 RealSAMLAdapter.validate_authresp(nil, "some_state")
      end

      test "returns error when relay_state is missing from cookie" do
        cookie = %{other_field: "value"}

        assert {:error, :invalid_relay_state} =
                 RealSAMLAdapter.validate_authresp(cookie, "some_state")
      end
    end
  end
end
