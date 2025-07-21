# M-Pesa Integration Test Runner
# Run with: elixir -S mix run mpesa_test/run_integration_tests.exs

# Load the test module
Code.require_file("mpesa_test/mpesa_integration_test.ex")

# Run all tests
Clinicpro.MPesaIntegrationTest.run_all_tests()

# You can also run individual tests:
# Clinicpro.MPesaIntegrationTest.run_stk_push_test()
# Clinicpro.MPesaIntegrationTest.run_c2b_registration_test()
