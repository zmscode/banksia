#!/bin/sh
set -eu

if [ "$#" -ne 2 ]; then
    echo "usage: $0 INPUT.cop OUTPUT.jpg" >&2
    exit 2
fi

description=$(file -b "$1")
case "$description" in
    *"JPEG XL"*) ;;
    *)
        echo "unsupported Capture One proxy: $description" >&2
        echo "this converter supports the JPEG XL .cop format used by Capture One 16.7" >&2
        exit 1
        ;;
esac

sips -s format jpeg -s formatOptions 95 "$1" --out "$2" >/dev/null
echo "wrote $2"
