#!/bin/sh
set -eu

manifest="phases/2b-real-camera-correctness/corpus.sha256"
inventory="phases/2b-real-camera-correctness/corpus.tsv"
asset_root="assets"
expected_supported=18
expected_linear=9

if [ ! -d "$asset_root/CR2" ] || [ ! -d "$asset_root/CR3" ] || \
    [ ! -d "$asset_root/DNG" ]; then
    echo "corpus: local assets/CR2, assets/CR3, and assets/DNG are required" >&2
    exit 1
fi

shasum -a 256 -c "$manifest"

tmp="${TMPDIR:-/tmp}/banksia-raw-corpus-previews-$$"
mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT INT TERM

# Every hashed original must have exactly one inventory row, and vice versa.
sed 's/^[0123456789abcdef]*  //' "$manifest" | LC_ALL=C sort > "$tmp/hash-paths"
sed -n '/^#/d; /^$/d; s/|.*//p' "$inventory" | LC_ALL=C sort > "$tmp/inventory-paths"
if ! diff -u "$tmp/hash-paths" "$tmp/inventory-paths"; then
    echo "corpus: hash manifest and metadata inventory disagree" >&2
    exit 1
fi

count=0
find "$asset_root/CR2" "$asset_root/CR3" -type f \( -iname '*.cr2' -o -iname '*.cr3' \) \
    -print0 | while IFS= read -r -d '' path; do
    zig-out/bin/banksia inspect "$path" --render >/dev/null
    sips -s format png --resampleHeightWidthMax 1024 "$path" --out "$tmp" >/dev/null 2>&1
    count=$((count + 1))
    printf '%s\n' "$count" > "$tmp/count"
done

actual_supported=$(cat "$tmp/count")
if [ "$actual_supported" -ne "$expected_supported" ]; then
    echo "corpus: expected $expected_supported supported files, decoded $actual_supported" >&2
    exit 1
fi

# Pin the metadata that affects rendering. This makes the inventory executable:
# a LibRaw upgrade cannot silently change camera identity, crop, or orientation.
while IFS='|' read -r path support camera lens iso width height orientation \
    crop_x crop_y crop_width crop_height captured scene features provenance licence; do
    case "$path" in ''|'#'*) continue ;; esac
    [ "$support" = optional ] || continue
    output=$(zig-out/bin/banksia inspect "$path")
    case "$output" in
        *"${width}x${height}, proprietary, orientation=${orientation}"*) ;;
        *) echo "corpus: geometry drift for $path" >&2; exit 1 ;;
    esac
    crop="default crop (active-relative): x=${crop_x} y=${crop_y}"
    crop="$crop width=${crop_width} height=${crop_height}"
    case "$output" in
        *"$crop"*) ;;
        *) echo "corpus: crop drift for $path" >&2; exit 1 ;;
    esac
    case "$output" in
        *"camera: ${camera}; lens=${lens}"*) ;;
        *) echo "corpus: camera or lens drift for $path" >&2; exit 1 ;;
    esac
    case "$output" in
        *"ISO: ${iso}"*) ;;
        *) echo "corpus: ISO drift for $path" >&2; exit 1 ;;
    esac
done < "$inventory"

count=0
find "$asset_root/DNG" -type f -iname '*.dng' -print0 | while IFS= read -r -d '' path; do
    if output=$(zig-out/bin/banksia inspect "$path" 2>&1); then
        echo "corpus: expected LinearRaw rejection for $path" >&2
        exit 1
    fi
    case "$output" in
        *UnsupportedLinearRaw*) ;;
        *)
            printf '%s\n' "$output" >&2
            echo "corpus: wrong rejection for $path" >&2
            exit 1
            ;;
    esac
    sips -s format png --resampleHeightWidthMax 1024 "$path" --out "$tmp" >/dev/null 2>&1
    count=$((count + 1))
    printf '%s\n' "$count" > "$tmp/linear-count"
done

actual_linear=$(cat "$tmp/linear-count")
if [ "$actual_linear" -ne "$expected_linear" ]; then
    echo "corpus: expected $expected_linear LinearRaw files, checked $actual_linear" >&2
    exit 1
fi

actual=$((actual_supported + actual_linear))
printf 'corpus: %d hashes verified; %d full v2 renders; ' "$actual" "$actual_supported"
printf '%d metadata rows checked; %d LinearRaw files rejected by name; ' \
    "$actual_supported" "$actual_linear"
printf '%d ImageIO previews decoded\n' "$actual"
