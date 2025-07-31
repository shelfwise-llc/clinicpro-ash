#!/usr/bin/env elixir

IO.puts("Testing ClinicPro Authentication Endpoints...")

# Test OTP endpoints
IO.puts("\n=== Testing OTP Endpoints ===")

# Test request OTP endpoint
IO.puts("Testing: GET /patient/request-otp")

{status, _} =
  System.cmd("curl", [
    "-s",
    "-o",
    "/dev/null",
    "-w",
    "%{http_code}",
    "http://localhost:4000/patient/request-otp?clinic_id=1"
  ])

IO.puts("Status: #{status}")

# Test LiveView magic link endpoints
IO.puts("\n=== Testing LiveView Magic Link Endpoints ===")

# Test patient magic link
IO.puts("Testing: GET /patient/magic-link")

{status, _} =
  System.cmd("curl", [
    "-s",
    "-o",
    "/dev/null",
    "-w",
    "%{http_code}",
    "http://localhost:4000/patient/magic-link?clinic_id=1"
  ])

IO.puts("Status: #{status}")

# Test doctor magic link
IO.puts("Testing: GET /doctor/magic-link")

{status, _} =
  System.cmd("curl", [
    "-s",
    "-o",
    "/dev/null",
    "-w",
    "%{http_code}",
    "http://localhost:4000/doctor/magic-link?clinic_id=1"
  ])

IO.puts("Status: #{status}")

# Test admin magic link
IO.puts("Testing: GET /admin/magic-link")

{status, _} =
  System.cmd("curl", [
    "-s",
    "-o",
    "/dev/null",
    "-w",
    "%{http_code}",
    "http://localhost:4000/admin/magic-link?clinic_id=1"
  ])

IO.puts("Status: #{status}")

IO.puts("\n=== Test Complete ===")
