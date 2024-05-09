#!/bin/zsh

# Generates an env file from the supabase status of the locally running supabase.

env_file="${1:-.env}"
supabase_status=("${(@f)$(supabase status)}")

[ -n "$supabase_status" ] || exit 1

for line in ${supabase_status[@]}; do
  stripped="$(echo "$line" | sed -e 's/^[[:space:]]*//')"

  [[ "$stripped" =~ "API URL:" ]] \
    && echo "SUPABASE_URL=${stripped:s/API URL: /}" > $env_file

  [[ "$stripped" =~ "anon key:" ]] \
    && echo "SUPABASE_ANON_KEY=${stripped:s/anon key: /}" >> $env_file

  [[ "$stripped" =~ "service_role key:" ]] \
    && echo "SUPABASE_SERVICE_ROLE_KEY=${stripped:s/service_role key: /}" >> $env_file
done
