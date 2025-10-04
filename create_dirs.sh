#!/bin/bash

input_file="development_structure.txt"

# Stack for parent directories
declare -a parents
last_indent=0

while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines
    [[ -z "$line" ]] && continue

    # Count leading spaces (indent level)
    indent=$(echo "$line" | sed -E 's/^( *).*/\1/' | awk '{ print length }')

    # Trim leading spaces
    folder=$(echo "$line" | sed -E 's/^ *//')

    if (( indent > last_indent )); then
        # Went deeper -> push last folder to stack
        parents+=("$last_folder")
    elif (( indent < last_indent )); then
        # Went shallower -> pop from stack
        diff=$(( (last_indent - indent) / 4 ))   # assume 4 spaces per indent
        parents=("${parents[@]:0:${#parents[@]}-$diff}")
    fi

    # Build path
    path=""
    for p in "${parents[@]}"; do
        path="$path/$p"
    done
    path="$path/$folder"

    # Create directory
    mkdir -p ".$path"

    # Update trackers
    last_indent=$indent
    last_folder=$folder
done < "$input_file"

