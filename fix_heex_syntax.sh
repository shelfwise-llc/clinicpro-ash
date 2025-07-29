#!/bin/bash

echo "🔧 Fixing HEEx template syntax errors..."
echo "======================================="

# Fix href attributes with EEx interpolation
echo "1. Fixing href attributes..."
find lib -name "*.heex" | xargs sed -i 's/href="<%= \([^%]*\) %>"/href={\1}/g'

# Fix class attributes with EEx interpolation
echo "2. Fixing class attributes with interpolation..."
find lib -name "*.heex" | xargs sed -i 's/class="[^"]*<%= \([^%]*\) %>[^"]*"/class={"#{&}"}/g'

echo "3. Running mix format to check syntax..."
mix format

echo "✅ HEEx syntax fixes applied!"
echo "📋 Check if any manual fixes are still needed."
