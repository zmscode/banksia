#!/bin/sh
set -eu

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    echo "usage: $0 INPUT.raw OUTPUT.jpg [QUALITY]" >&2
    exit 2
fi

input=$1
output=$2
quality=${3:-95}

case "$quality" in
    ''|*[!0-9]*) echo "quality must be an integer from 0 to 100" >&2; exit 2 ;;
esac
if [ "$quality" -gt 100 ]; then
    echo "quality must be an integer from 0 to 100" >&2
    exit 2
fi
case "$output" in
    *.jpg|*.JPG) ;;
    *) echo "output filename must end in .jpg" >&2; exit 2 ;;
esac
if [ ! -f "$input" ]; then
    echo "input file does not exist: $input" >&2
    exit 1
fi

input_directory=$(CDPATH= cd -- "$(dirname -- "$input")" && pwd)
input_path=$input_directory/$(basename -- "$input")
output_directory=$(dirname -- "$output")
mkdir -p "$output_directory"
output_directory=$(CDPATH= cd -- "$output_directory" && pwd)
output_filename=$(basename -- "$output")
output_name=${output_filename%.*}
output_path=$output_directory/$output_filename

session_root=$(mktemp -d "${TMPDIR:-/tmp}/banksia-c1-render.XXXXXX")
session_name="Banksia Render $$"
render_path=$session_root/$session_name/Output/$output_filename
mkdir -p "$session_root/input"
render_input=$session_root/input/$(basename -- "$input_path")
cp -p "$input_path" "$render_input"
cleanup() {
    osascript -e 'on run argv' \
        -e 'tell application "Capture One" to close document (item 1 of argv) saving no' \
        -e 'end run' "$session_name.cosessiondb" >/dev/null 2>&1 || true
    rm -rf "$session_root"
}
trap cleanup EXIT HUP INT TERM

osascript "$(dirname -- "$0")/capture-one-raw-to-jpeg.applescript" \
    "$render_input" "$output_name" "$quality" "$session_root" "$session_name" >/dev/null

elapsed=0
previous_size=-1
stable_checks=0
while [ "$elapsed" -lt 600 ]; do
    if [ -f "$render_path" ]; then
        current_size=$(stat -f %z "$render_path")
        if [ "$current_size" -gt 0 ] && [ "$current_size" -eq "$previous_size" ]; then
            stable_checks=$((stable_checks + 1))
            if [ "$stable_checks" -ge 2 ]; then
                mv -f "$render_path" "$output_path"
                echo "wrote $output_path"
                exit 0
            fi
        else
            stable_checks=0
        fi
        previous_size=$current_size
    fi
    sleep 1
    elapsed=$((elapsed + 1))
done

echo "timed out waiting for Capture One to render $render_path" >&2
exit 1
