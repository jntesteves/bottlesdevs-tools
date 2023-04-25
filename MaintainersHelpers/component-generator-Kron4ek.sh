#!/usr/bin/env sh
# Set DRY_RUN=1 to test the script without doing anything
DRY_RUN=
# A regex matching a filename to stop processing (optional)
STOP_VERSION_EXPR='wine-7\.20-'
# A regex matching a filename to skip (optional)
SKIP_EXPR=

FILENAME_EXPR='wine-[^/]+-amd64'
index_yaml=''
abort() { printf '%s\n' "$*" >&2; exit 1; }

if [ ! "$DRY_RUN" ]; then
    # Python dependencies: pip3 install pyyaml requests
    pip3 install pyyaml requests || abort 'Failed to install Python dependencies'
fi

for file_url in $(curl -L -s https://api.github.com/repos/Kron4ek/Wine-Builds/releases |
        grep -Eo "https://github.com/Kron4ek/Wine-Builds/releases/download/.+/${FILENAME_EXPR}\.tar\.xz"); do
    filename="$(printf '%s' "$file_url" | grep -Eo -e "$FILENAME_EXPR")"
    name="kron4ek-${filename}"
    printf '%s - %s\n' "$file_url" "$filename"

    if [ "$STOP_VERSION_EXPR" ] && printf '%s' "$filename" | grep -Eq -e "$STOP_VERSION_EXPR"; then
        printf 'Stopping at version %s\n' "$STOP_VERSION_EXPR"
        break
    fi

    if [ "$SKIP_EXPR" ] && printf '%s' "$filename" | grep -Eq -e "$SKIP_EXPR"; then
        printf 'Skipping version %s\n' "$SKIP_EXPR"
        continue
    fi

    if [ ! "$DRY_RUN" ]; then
        # Python dependencies: pip3 install pyyaml requests
        python3 component-generator.py "components" "nobody" "${name}" "Kron4ek" "stable" "${file_url}"
        # Fix the rename action
        sed -i 's/rename: wine-/rename: kron4ek-wine-/g' "${name}.yml"
        sed -i 's/source: kron4ek-wine-/source: wine-/g' "${name}.yml"
    fi

    sub_category='wine'
    # printf '%s' "$filename" | grep -Eiq "proton" && sub_category='proton'
    index_yaml="$index_yaml$name:
  Category: runners
  Sub-category: $sub_category
  Channel: stable
"
done

printf '\n%s\n' "$index_yaml"
