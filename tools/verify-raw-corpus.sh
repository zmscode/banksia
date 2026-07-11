#!/bin/sh
set -eu

manifest="phases/2b-real-camera-correctness/corpus.sha256"
asset_root="assets"
expected=18

if [ ! -d "$asset_root/CR2" ] || [ ! -d "$asset_root/CR3" ]; then
    echo "corpus: local assets/CR2 and assets/CR3 directories are required" >&2
    exit 1
fi

shasum -a 256 -c "$manifest"

tmp="${TMPDIR:-/tmp}/banksia-raw-corpus-previews-$$"
mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT INT TERM

count=0
find "$asset_root/CR2" "$asset_root/CR3" -type f \( -iname '*.cr2' -o -iname '*.cr3' \) \
    -print0 | while IFS= read -r -d '' path; do
    zig-out/bin/banksia inspect "$path" --decode >/dev/null
    sips -s format png --resampleHeightWidthMax 1024 "$path" --out "$tmp" >/dev/null 2>&1
    count=$((count + 1))
    printf '%s\n' "$count" > "$tmp/count"
done

actual=$(cat "$tmp/count")
if [ "$actual" -ne "$expected" ]; then
    echo "corpus: expected $expected files, decoded $actual" >&2
    exit 1
fi

echo "corpus: $actual hashes verified; $actual LibRaw mosaics + ImageIO previews decoded"
