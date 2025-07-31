#!/bin/bash

# LiveView + SRP Refactor Setup Script

echo "🚀 Setting up LiveView + SRP Refactor Environment"
echo "=============================================="
echo ""

# Create archived_plans directory if it doesn't exist
if [ ! -d "archived_plans" ]; then
  echo "📁 Creating archived_plans directory..."
  mkdir -p archived_plans
fi

echo "📦 Archiving existing plans..."

# Move existing plans to archived_plans (if they exist and aren't already archived)
if [ -f "REFACTOR_PLAN.md" ]; then
  mv REFACTOR_PLAN.md archived_plans/
  echo "  ✓ REFACTOR_PLAN.md archived"
fi

if [ -f "DEPLOYMENT.md" ]; then
  mv DEPLOYMENT.md archived_plans/
  echo "  ✓ DEPLOYMENT.md archived"
fi

if [ -f "RAILWAY_DEPLOYMENT.md" ]; then
  mv RAILWAY_DEPLOYMENT.md archived_plans/
  echo "  ✓ RAILWAY_DEPLOYMENT.md archived"
fi

if [ -f "RAILWAY_DEPLOYMENT_SETUP.md" ]; then
  mv RAILWAY_DEPLOYMENT_SETUP.md archived_plans/
  echo "  ✓ RAILWAY_DEPLOYMENT_SETUP.md archived"
fi

if [ -f "railway_env_setup.md" ]; then
  mv railway_env_setup.md archived_plans/
  echo "  ✓ railway_env_setup.md archived"
fi

echo ""
echo "🌿 Creating new branch for LiveView + SRP refactor..."

# Check if branch already exists
git show-ref --verify --quiet refs/heads/feature/liveview-srp-refactor
if [ $? -eq 0 ]; then
  echo "  ⚠ Branch feature/liveview-srp-refactor already exists"
  echo "  🔄 Switching to existing branch..."
  git checkout feature/liveview-srp-refactor
else
  echo "  ✨ Creating new branch feature/liveview-srp-refactor from main..."
  git checkout main
  git checkout -b feature/liveview-srp-refactor
fi

echo ""
echo "🧪 Verifying current test status..."
echo "   (This may take a moment)"

# Run a quick compilation check to establish baseline
MIX_ENV=test mix compile --warnings-as-errors > /tmp/clinicpro_compile_check.log 2>&1
if [ $? -eq 0 ]; then
  echo "  ✅ Compilation successful (no warnings as errors)"
else
  echo "  ⚠ Compilation has warnings (expected for this codebase)"
  echo "     See /tmp/clinicpro_compile_check.log for details"
fi

echo ""
echo "📊 Current branch status:"
git status

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Review the LIVEVIEW_SRP_REFACTOR_PLAN.md"
echo "2. Begin Phase 1 implementation"
echo "3. Run tests to establish baseline"
echo "4. Start creating LiveView components"
echo ""
echo "The archived plans are in the 'archived_plans' directory for reference."
echo ""
