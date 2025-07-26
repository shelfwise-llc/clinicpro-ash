#!/bin/bash

# Fix HEEx template syntax in configuration_details.html.heex
# Convert EEx interpolations to HEEx syntax

FILE="lib/clinicpro_web/templates/mpesa_admin/configuration_details.html.heex"

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

echo "HEEx syntax fixes applied to $FILE"
echo "Running mix format to verify..."
mix format "$FILE"