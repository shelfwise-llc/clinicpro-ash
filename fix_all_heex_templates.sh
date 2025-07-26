#!/bin/bash

# Fix HEEx template syntax in all template files
# Convert EEx interpolations to HEEx syntax

echo "Finding all .heex template files with EEx syntax issues..."

# Find all .heex files that contain EEx syntax
FILES=$(find lib -name "*.heex" -exec grep -l "<%= " {} \;)

if [ -z "$FILES" ]; then
    echo "No .heex files with EEx syntax found."
    exit 0
fi

echo "Found files with EEx syntax:"
echo "$FILES"
echo ""

for FILE in $FILES; do
    echo "Fixing HEEx syntax in $FILE..."
    
    # Fix href attributes - convert <%= ... %> to {...}
    sed -i 's/href="<%= \([^%]*\) %>"/href={\1}/g' "$FILE"
    
    # Fix class attributes with interpolation - convert class="... <%= ... %> ..." to class={"... #{...} ..."}
    sed -i 's/class="\([^"]*\)<%= \([^%]*\) %>\([^"]*\)"/class={"\1#{\2}\3"}/g' "$FILE"
    
    # Fix simple class attributes - convert class="<%= ... %>" to class={...}
    sed -i 's/class="<%= \([^%]*\) %>"/class={\1}/g' "$FILE"
    
    # Fix value attributes - convert value="<%= ... %>" to value={...}
    sed -i 's/value="<%= \([^%]*\) %>"/value={\1}/g' "$FILE"
    
    # Fix id attributes - convert id="<%= ... %>" to id={...}
    sed -i 's/id="<%= \([^%]*\) %>"/id={\1}/g' "$FILE"
    
    # Fix action attributes - convert action="<%= ... %>" to action={...}
    sed -i 's/action="<%= \([^%]*\) %>"/action={\1}/g' "$FILE"
    
    # Fix src attributes - convert src="<%= ... %>" to src={...}
    sed -i 's/src="<%= \([^%]*\) %>"/src={\1}/g' "$FILE"
    
    # Fix data attributes - convert data-*="<%= ... %>" to data-*={...}
    sed -i 's/data-\([^=]*\)="<%= \([^%]*\) %>"/data-\1={\2}/g' "$FILE"
    
    # Fix onclick attributes - convert onclick="...('<%= ... %>')..." to onclick={"...('#{...}')..."}
    sed -i 's/onclick="\([^"]*\)<%= \([^%]*\) %>\([^"]*\)"/onclick={"\1#{\2}\3"}/g' "$FILE"
    
    # Fix standalone EEx interpolations - convert <%= ... %> to {...}
    sed -i 's/<%= \([^%]*\) %>/{\1}/g' "$FILE"
    
    echo "  Fixed $FILE"
done

echo ""
echo "Running mix format to verify all fixes..."
mix format --check-formatted

if [ $? -eq 0 ]; then
    echo "✅ All HEEx template syntax issues fixed!"
else
    echo "❌ Some issues remain. Check the output above."
fi
