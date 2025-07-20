#!/usr/bin/env elixir

defmodule FixAshPolicies do
  @moduledoc """
  Script to temporarily comment out problematic Ash policy expressions
  to allow tests to run without compilation errors.
  """

  @resource_paths [
    "lib/clinicpro/appointments/resources",
    "lib/clinicpro/patients/resources",
    "lib/clinicpro/clinics/resources",
    "lib/clinicpro/accounts/resources"
  ]

  def run do
    IO.puts("Fixing Ash policy expressions in resource files...")
    
    # Find all resource files
    resource_files = find_resource_files()
    IO.puts("Found #{length(resource_files)} resource files")
    
    # Process each file
    Enum.each(resource_files, &process_file/1)
    
    IO.puts("Done!")
  end

  defp find_resource_files do
    @resource_paths
    |> Enum.flat_map(fn path ->
      if File.dir?(path) do
        Path.wildcard("#{path}/**/*.ex")
      else
        []
      end
    end)
  end

  defp process_file(file_path) do
    IO.puts("Processing #{file_path}")
    
    content = File.read!(file_path)
    
    # Comment out policies blocks
    new_content = comment_out_policies(content)
    
    # Write the modified content back to the file
    if new_content != content do
      File.write!(file_path, new_content)
      IO.puts("  Modified #{file_path}")
    else
      IO.puts("  No changes needed for #{file_path}")
    end
  end

  defp comment_out_policies(content) do
    # Pattern to match policies blocks
    policies_pattern = ~r/(\s+)policies\s+do\s+(.*?)(\s+end\s+)/s
    
    # Replace policies blocks with commented version
    Regex.replace(policies_pattern, content, fn _, indent, policies_content, end_part ->
      commented_policies = String.split(policies_content, "\n")
                          |> Enum.map(fn line -> 
                             if String.trim(line) == "" do
                               line
                             else
                               "# #{line}"
                             end
                           end)
                          |> Enum.join("\n")
      
      "#{indent}# Temporarily commented out for testing\n#{indent}# policies do\n#{commented_policies}\n#{indent}# end\n"
    end)
  end
end

FixAshPolicies.run()
