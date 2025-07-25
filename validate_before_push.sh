#!/bin/bash

echo "🚀 Pre-Push Validation for ClinicPro"
echo "===================================="

# Check formatting
echo "1. Checking code formatting..."
if mix format --check-formatted; then
    echo "✅ Code formatting is correct"
else
    echo "❌ Code formatting issues found"
    echo "💡 Run 'mix format' to fix formatting"
    exit 1
fi

# Basic compilation check (without warnings-as-errors for now)
echo "2. Testing basic compilation..."
if mix compile; then
    echo "✅ Basic compilation successful"
else
    echo "❌ Compilation failed"
    echo "💡 Fix compilation errors before pushing"
    exit 1
fi

# Run tests
echo "3. Running tests..."
if mix test; then
    echo "✅ All tests passed"
else
    echo "❌ Tests failed"
    echo "💡 Fix failing tests before pushing"
    exit 1
fi

# Optional: Check if Docker build works
echo "4. Testing Docker build (optional)..."
if command -v docker &> /dev/null; then
    if docker build -t clinicpro-test . > /dev/null 2>&1; then
        echo "✅ Docker build successful"
        docker rmi clinicpro-test > /dev/null 2>&1
    else
        echo "⚠️  Docker build failed (non-critical for local development)"
    fi
else
    echo "⚠️  Docker not available (skipping Docker build test)"
fi

echo ""
echo "🎉 All checks passed! Safe to push to GitHub."
echo "   Run: git push origin main"
echo ""
echo "💡 The GitHub Actions CI/CD will:"
echo "   - Run tests with PostgreSQL"
echo "   - Build Docker image"
echo "   - Deploy with Kamal to Railway"
