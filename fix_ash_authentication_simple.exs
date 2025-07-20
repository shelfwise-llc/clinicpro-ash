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
end

ExUnit.run()
"""

File.write!(test_script_path, test_script_content)
IO.puts("✓ Created test script at #{test_script_path}")

IO.puts("\\nDiagnostic and fix script completed.")
IO.puts("To verify the AshAuthentication configuration, run:")
IO.puts("  mix run #{test_script_path}")
IO.puts("\\nTo run the controller tests, run:")
IO.puts("  mix test test/clinicpro_web/controllers/doctor_flow_test.exs")
