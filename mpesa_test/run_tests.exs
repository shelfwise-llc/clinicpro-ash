# Simple script to run M-Pesa integration tests
# Run with: elixir mpesa_test/run_tests.exs

Code.require_file("mpesa_test/test_mpesa.ex")
MPesaTest.run()
