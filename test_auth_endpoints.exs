#!/usr/bin/env elixir

# Test script for ClinicPro authentication endpoints

IO.puts("=== Testing ClinicPro Authentication Endpoints ===")

base_url = "http://localhost:4000"

endpoints = [
  # Patient OTP endpoints
  {"GET", "/patient/request-otp?clinic_id=1"},
  {"POST", "/patient/send-otp?clinic_id=1"},
  {"GET", "/patient/verify-otp?clinic_id=1"},

  # Patient LiveView endpoints
  {"GET", "/patient/magic-link"},

  # Doctor endpoints
  {"GET", "/doctor/magic-link"},

  # Admin endpoints
  {"GET", "/admin/magic-link"},

  # General endpoints
  {"GET", "/admin"},
  {"GET", "/doctor"},
  {"GET", "/patient/dashboard"}
]

for {method, path} <- endpoints do
  url = base_url <> path
  IO.puts("\nTesting #{method} #{path}")

  case method do
    "GET" ->
      case System.cmd("curl", ["-s", "-o", "/dev/null", "-w", "%{http_code}", url]) do
        {output, 0} -> IO.puts("  Status: #{output}")
        {error, _} -> IO.puts("  Error: #{error}")
      end

    "POST" ->
      # For POST requests, we'll just check if the endpoint exists
      case System.cmd("curl", ["-s", "-o", "/dev/null", "-w", "%{http_code}", "-X", "POST", url]) do
        {output, 0} -> IO.puts("  Status: #{output}")
        {error, _} -> IO.puts("  Error: #{error}")
      end
  end
end

IO.puts("\n=== Test Complete ===")
