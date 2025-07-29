#!/bin/bash

# Fix underscored variable issues in core_components.ex
sed -i 's/def translate_error({msg, _opts}) do/def translate_error({msg, opts}) do/g' lib/clinicpro_web/components/core_components.ex
sed -i 's/if count = _opts\[:count\] do/if count = opts[:count] do/g' lib/clinicpro_web/components/core_components.ex
sed -i 's/Gettext.dngettext(ClinicproWeb.Gettext, "errors", msg, msg, count, _opts)/Gettext.dngettext(ClinicproWeb.Gettext, "errors", msg, msg, count, opts)/g' lib/clinicpro_web/components/core_components.ex
sed -i 's/Gettext.dgettext(ClinicproWeb.Gettext, "errors", msg, _opts)/Gettext.dgettext(ClinicproWeb.Gettext, "errors", msg, opts)/g' lib/clinicpro_web/components/core_components.ex
sed -i 's/for {^field, {msg, _opts}} <- errors, do: translate_error({msg, _opts})/for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})/g' lib/clinicpro_web/components/core_components.ex

# Fix the _i variable in table function
sed -i 's/<span class={["relative", _i == 0 && "font-semibold text-zinc-900"]}/<span class={["relative", i == 0 && "font-semibold text-zinc-900"]}/g' lib/clinicpro_web/components/core_components.ex

# Make the script executable
chmod +x "$0"

echo "Fixed underscored variable issues in core_components.ex"
