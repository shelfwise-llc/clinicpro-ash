#!/bin/bash

# Conservative HEEx template syntax fix
# Only fix attribute interpolations, not control flow

echo "Finding files that need conservative HEEx fixes..."

# Find files that were broken by the aggressive script
BROKEN_FILES=$(find lib -name "*.heex" -exec grep -l "^\s*end\s*$" {} \; 2>/dev/null)

if [ -n "$BROKEN_FILES" ]; then
    echo "Restoring broken files from previous commit..."
    for FILE in $BROKEN_FILES; do
        echo "  Restoring $FILE"
        git checkout HEAD~1 -- "$FILE"
    done
fi

# Now find files that actually need HEEx attribute fixes
FILES_NEEDING_FIXES=$(find lib -name "*.heex" -exec grep -l 'href="<%= \|class="<%= \|onclick="[^"]*<%= ' {} \; 2>/dev/null)

if [ -z "$FILES_NEEDING_FIXES" ]; then
    echo "No files need HEEx attribute fixes."
else
    echo "Files needing conservative fixes:"
    echo "$FILES_NEEDING_FIXES"
    echo ""
    
    for FILE in $FILES_NEEDING_FIXES; do
        echo "Fixing attributes in $FILE..."
        
        # Only fix href attributes - convert href="<%= ... %>" to href={...}
        sed -i 's/href="<%= \([^%]*\) %>"/href={\1}/g' "$FILE"
        
        # Only fix simple class attributes - convert class="<%= ... %>" to class={...}
        sed -i 's/class="<%= \([^%]*\) %>"/class={\1}/g' "$FILE"
        
        # Fix onclick with interpolation - convert onclick="...('<%= ... %>')..." to onclick={"...('#{...}')..."}
        sed -i 's/onclick="\([^"]*\)<%= \([^%]*\) %>\([^"]*\)"/onclick={"\1#{\2}\3"}/g' "$FILE"
        
        echo "  Fixed $FILE"
    done
fi

echo ""
echo "Running mix format to verify fixes..."
mix format --check-formatted

if [ $? -eq 0 ]; then
    echo "✅ All HEEx template issues fixed!"
else
    echo "❌ Some formatting issues remain."
fi