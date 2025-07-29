#!/bin/bash

# Fix undefined variable _opts in paystack_admin_html.ex
sed -i 's/field, _opts)/field, opts)/g' lib/clinicpro_web/controllers/paystack_admin_html.ex
sed -i 's/options, _opts)/options, opts)/g' lib/clinicpro_web/controllers/paystack_admin_html.ex
sed -i 's/text, _opts)/text, opts)/g' lib/clinicpro_web/controllers/paystack_admin_html.ex
sed -i 's/value, _opts)/value, opts)/g' lib/clinicpro_web/controllers/paystack_admin_html.ex

# Fix the select function in admin_bypass_html.ex
sed -i 's/options, _opts)/options, opts)/g' lib/clinicpro_web/controllers/admin_bypass_html.ex
sed -i 's/field, _opts)/field, opts)/g' lib/clinicpro_web/controllers/admin_bypass_html.ex

# Fix the link function in paystack_admin_html.ex
sed -i 's/def link(text, _opts), do: Phoenix.HTML.Link.link(text, _opts)/def link(text, opts), do: Phoenix.HTML.Link.link(text, opts)/g' lib/clinicpro_web/controllers/paystack_admin_html.ex

# Make the script executable
chmod +x "$0"

echo "Fixed undefined variable _opts in paystack_admin_html.ex and admin_bypass_html.ex"
