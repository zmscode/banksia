#!/bin/sh
set -eu

if [ "$#" -ne 3 ]; then
    echo "usage: $0 INPUT.raw ROTATION_CW OUTPUT_DIRECTORY" >&2
    exit 2
fi

input=$1
rotation=$2
output_directory=$3
recipe="phases/2b-real-camera-correctness/neutral-v2.json"
name=$(basename "$input")
actual="$output_directory/$name-banksia.png"
reference="$output_directory/$name-imageio.png"
oriented="$output_directory/$name-imageio-oriented.png"
metric="$output_directory/perceptual-report"

mkdir -p "$output_directory"
zig build -Doptimize=ReleaseFast
zig-out/bin/banksia render "$input" "$recipe" "$actual"
sips -s format png "$input" --out "$reference" >/dev/null
if [ "$rotation" -eq 0 ]; then
    cp "$reference" "$oriented"
else
    sips -r "$rotation" "$reference" --out "$oriented" >/dev/null
fi
swiftc -O tools/perceptual-report.swift -o "$metric"
"$metric" "$actual" "$oriented"
