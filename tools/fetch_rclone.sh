#!/bin/sh
# Fetches the pinned rclone for a 64-bit Raspberry Pi (Pi 4 / CM4) and checks it
# against a pinned SHA-256, as bootstrap_dependencies.sh does for minimp4.
# Usage: fetch_rclone.sh [destination]  (default build/deps/rclone)
# Result: <destination>/rclone.
set -eu

destination=${1:-build/deps/rclone}
version=v1.75.2
archive=rclone-$version-linux-arm64.zip
url=https://github.com/rclone/rclone/releases/download/$version/$archive
sha256=7e1e8d69654941b7b7df84ee74c5f7fb09cce7d5496947fb7bf16b55ff427d10

for command in curl unzip mkdir mktemp mv rm sha256sum chmod; do
    command -v "$command" >/dev/null 2>&1 || {
        echo "Missing tool: $command" >&2
        exit 1
    }
done

mkdir -p "$destination"
if [ -x "$destination/rclone" ] && [ "$(cat "$destination/VERSION" 2>/dev/null)" = "$version $sha256" ]; then
    echo "rclone $version is ready in $destination"
    exit 0
fi

work=$(mktemp -d "$destination/fetch.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
curl -L --fail --silent --show-error "$url" -o "$work/$archive"
printf '%s  %s\n' "$sha256" "$work/$archive" | sha256sum -c - >/dev/null || {
    echo "rclone download does not match the pinned SHA-256" >&2
    exit 1
}
unzip -q -j "$work/$archive" "rclone-$version-linux-arm64/rclone" -d "$work"
chmod 755 "$work/rclone"
mv "$work/rclone" "$destination/rclone"
printf '%s %s\n' "$version" "$sha256" > "$destination/VERSION"
echo "rclone $version is ready in $destination"
