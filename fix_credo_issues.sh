#!/bin/bash

echo "🔧 Fixing Credo style and consistency issues..."
echo "=============================================="

# Fix unused variables with meaningful names (replace _ with _unused)
echo "1. Fixing unused variable naming consistency..."
find lib test -name "*.ex" -o -name "*.exs" | xargs sed -i 's/\b_\b/_unused/g'

# Fix multi-alias syntax to single line aliases
echo "2. Fixing alias formatting..."
# This is more complex and might need manual review, so we'll just identify them
echo "   → Multi-alias issues found in these files:"
grep -r "alias.*{" lib test --include="*.ex" --include="*.exs" | cut -d: -f1 | sort -u

echo ""
echo "3. Running Credo to check improvements..."
mix credo --strict | head -20

echo ""
echo "4. Running mix format to fix formatting issues..."
mix format

echo ""
echo "✅ Automatic fixes applied!"
echo ""
echo "📋 Manual fixes needed:"
echo "   1. Review multi-alias usage in files listed above"
echo "   2. Address any remaining function complexity issues"
echo "   3. Review software design suggestions"
echo ""
echo "🚀 Run 'mix credo --strict' again to see remaining issues"
