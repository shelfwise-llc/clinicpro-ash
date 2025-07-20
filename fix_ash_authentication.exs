# This script diagnoses and fixes AshAuthentication configuration issues
# It focuses on resolving the "key :type not found in: nil" error in the magic link transformer

IO.puts("Starting AshAuthentication diagnostic and fix script...")

# Check if the token signing secret is configured
token_secret = Application.get_env(:clinicpro, :token_signing_secret)
if token_secret do
  IO.puts("✓ Token signing secret is configured: #{String.slice(token_secret, 0, 5)}...")
else
  IO.puts("✗ Token signing secret is not configured")
  # Generate a random token signing secret
  random_secret = :crypto.strong_rand_bytes(64) |> Base.encode64()
  Application.put_env(:clinicpro, :token_signing_secret, random_secret)
  IO.puts("✓ Generated and set a random token signing secret")
end

# Define the correct configuration for the Accounts API
accounts_api_config = """
defmodule Clinicpro.Accounts do
  @moduledoc \"\"\"
  Accounts API for ClinicPro.
  \"\"\"
  use Ash.Api, extensions: [AshAuthentication]

  resources do
    resource(Clinicpro.Accounts.User)
    resource(Clinicpro.Accounts.Role)
    resource(Clinicpro.Accounts.Permission)
    resource(Clinicpro.Accounts.UserRole)
    resource(Clinicpro.Accounts.Token)
  end

  authentication do
    subject_name :user
    strategies do
      magic_link :magic_link do
        identity_field :email
        sender Clinicpro.Accounts.MagicLinkSender
      end
    end
    
    tokens do
      enabled? true
      token_resource Clinicpro.Accounts.Token
      signing_secret fn _, _ -> Application.fetch_env!(:clinicpro, :token_signing_secret) end
      token_lifetime 60 * 60 * 24 * 7 # 7 days
    end
  end
end
"""

# Define the correct configuration for the User resource
user_resource_config = """
defmodule Clinicpro.Accounts.User do
  @moduledoc \"\"\"
  User resource for ClinicPro.
  
  This resource represents a user in the system with authentication capabilities.
  It supports magic link authentication and role-based access control.
  \"\"\"
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [Ash.Policy.Authorizer, AshAuthentication]

  postgres do
    table "users"
    repo Clinicpro.Repo
  end

  attributes do
    uuid_primary_key :id
    attribute :email, :ci_string, allow_nil?: false
    attribute :first_name, :string, allow_nil?: true
    attribute :last_name, :string, allow_nil?: true
    attribute :is_active, :boolean, default: true
    timestamps()
  end

  identities do
    identity :unique_email, [:email]
  end

  authentication do
    api Clinicpro.Accounts

    strategies do
      magic_link :magic_link do
        identity_field :email
        sender Clinicpro.Accounts.MagicLinkSender
        token_type :magic_link
      end
    end
  end

  relationships do
    has_many :roles, Clinicpro.Accounts.UserRole do
      destination_attribute :user_id
    end
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end
end
"""

# Define the correct configuration for the MagicLinkSender module
magic_link_sender_config = """
defmodule Clinicpro.Accounts.MagicLinkSender do
  @moduledoc """
  Magic link sender for ClinicPro authentication.
  
  This module is responsible for sending magic link emails to users.
  It follows the AshAuthentication.Sender behaviour.
  """
  @behaviour AshAuthentication.Sender

  require Logger

  @impl AshAuthentication.Sender
  def send(user, token, _opts) do
    # In a real application, you would send an email here
    # For now, we'll just log the token for development purposes
    Logger.info("Magic link for user: #{inspect(user.email)} - token: #{token}")
    
    # Return success
    :ok
  end
  
  @impl AshAuthentication.Sender
  def deliver_action, do: :deliver_email
  
  @impl AshAuthentication.Sender
  def success_message(_user), do: "Magic link sent! Check your email."
  
  @impl AshAuthentication.Sender
  def failure_message(_user), do: "Failed to send magic link. Please try again."
end
"""

# Check if the Token resource exists
token_resource_path = Path.join([File.cwd!(), "lib", "clinicpro", "accounts", "resources", "token.ex"])
token_resource_exists = File.exists?(token_resource_path)

if token_resource_exists do
  IO.puts("✓ Token resource exists at #{token_resource_path}")
else
  IO.puts("✗ Token resource does not exist at #{token_resource_path}")
  
  # Define the Token resource
  token_resource_config = """
  defmodule Clinicpro.Accounts.Token do
    @moduledoc \"\"\"
    Token resource for ClinicPro authentication.
    
    This resource is used to store authentication tokens.
    \"\"\"
    use Ash.Resource,
      data_layer: AshPostgres.DataLayer,
      extensions: [AshAuthentication.TokenResource]
  
    postgres do
      table "tokens"
      repo Clinicpro.Repo
    end
  
    token do
      api Clinicpro.Accounts
    end
  end
  """
  
  # Create the Token resource file
  File.mkdir_p!(Path.dirname(token_resource_path))
  File.write!(token_resource_path, token_resource_config)
  IO.puts("✓ Created Token resource at #{token_resource_path}")
end

# Create a test script to verify the AshAuthentication configuration
test_script_path = Path.join([File.cwd!(), "test_ash_authentication.exs"])
test_script_content = """
# This script tests the AshAuthentication configuration
# It verifies that the magic link authentication is properly configured

ExUnit.start()

defmodule AshAuthenticationTest do
  use ExUnit.Case
  
  test "token signing secret is configured" do
    token_secret = Application.get_env(:clinicpro, :token_signing_secret)
    assert token_secret != nil
    assert is_binary(token_secret)
  end
  
  test "User resource has magic_link strategy" do
    strategies = Clinicpro.Accounts.User.__auth_strategies__()
    assert Keyword.has_key?(strategies, :magic_link)
    
    magic_link_strategy = Keyword.get(strategies, :magic_link)
    assert magic_link_strategy.identity_field == :email
    assert magic_link_strategy.token_type == :magic_link
  end
  
  test "MagicLinkSender implements AshAuthentication.Sender behaviour" do
    assert function_exported?(Clinicpro.Accounts.MagicLinkSender, :send, 3)
    assert function_exported?(Clinicpro.Accounts.MagicLinkSender, :deliver_action, 0)
    assert function_exported?(Clinicpro.Accounts.MagicLinkSender, :success_message, 1)
    assert function_exported?(Clinicpro.Accounts.MagicLinkSender, :failure_message, 1)
  end
  
  test "Accounts API has token configuration" do
    token_config = Clinicpro.Accounts.__token_config__()
    assert token_config.enabled?
    assert token_config.token_resource == Clinicpro.Accounts.Token
    assert is_function(token_config.signing_secret, 2)
    assert token_config.token_lifetime > 0
  end
end

ExUnit.run()
"""

File.write!(test_script_path, test_script_content)
IO.puts("✓ Created test script at #{test_script_path}")

IO.puts("\nDiagnostic and fix script completed.")
IO.puts("To verify the AshAuthentication configuration, run:")
IO.puts("  mix run #{test_script_path}")
IO.puts("\nTo run the controller tests, run:")
IO.puts("  mix test test/clinicpro_web/controllers/doctor_flow_test.exs")
