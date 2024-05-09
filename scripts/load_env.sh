#!/bin/bash

env_file="${1:-.env}"

if [ ! -f "$env_file" ]; then
    echo "Error: Environment file '$env_file' not found." >&2
    exit 1
fi

while IFS="" read -r line; do
  # Skip lines that begin with a '#' symbol.
  if [[ "$line" =~ \#.* ]]; then
    #echo "skipping line: $line"
    continue
  else
    line="${line%%}"
    if [ -n "$line" ]; then
      export "$line" || {
        echo "Error exporting: $line" >&2
        exit 1
      }
    fi
  fi
done <"$env_file"
