ExUnit.start()

# Run all admin bypass tests
IO.puts("Loading admin bypass tests...")
Enum.each(Path.wildcard("test/clinicpro/admin_bypass/*_test.exs"), &Code.require_file/1)
