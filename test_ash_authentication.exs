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
end

ExUnit.run()
