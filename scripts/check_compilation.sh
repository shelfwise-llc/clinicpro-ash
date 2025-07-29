#!/bin/bash

# Script to check if the application compiles without warnings
# This simulates the CI/CD pipeline's strict compilation check

echo "=== Cleaning previous compilation artifacts ==="
mix clean
echo ""

echo "=== Checking formatting ==="
mix format --check-formatted
FORMAT_EXIT=$?
if [ $FORMAT_EXIT -ne 0 ]; then
  echo "❌ Formatting check failed"
  echo "Run 'mix format' to fix formatting issues"
  exit 1
else
  echo "✅ Formatting check passed"
fi
echo ""

echo "=== Compiling with warnings as errors ==="
MIX_ENV=dev mix compile --warnings-as-errors
DEV_EXIT=$?

echo "=== Compiling tests with warnings as errors ==="
MIX_ENV=test mix compile --warnings-as-errors
TEST_EXIT=$?

if [ $DEV_EXIT -eq 0 ] && [ $TEST_EXIT -eq 0 ]; then
  echo "✅ All compilations passed without warnings!"
  echo "The application should pass the CI/CD pipeline compilation checks."
  exit 0
else
  echo "❌ Compilation with --warnings-as-errors failed"
  echo "Fix all warnings before deploying to CI/CD pipeline."
  exit 1
fi
