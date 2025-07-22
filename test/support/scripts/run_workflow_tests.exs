ExUnit.start()

# Run all workflow tests
IO.puts("Loading workflow tests...")
Enum.each(Path.wildcard("test/clinicpro/workflow/*_test.exs"), &Code.require_file/1)
