ExUnit.start()

# Run all M-Pesa tests
IO.puts("Loading M-Pesa tests...")
Enum.each(Path.wildcard("test/clinicpro/mpesa/*_test.exs"), &Code.require_file/1)
