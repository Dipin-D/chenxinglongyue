#!/bin/zsh

set -euo pipefail

if (( $# < 2 || $# > 3 )) || [[ ${3:-} != '' && ${3:-} != '--replace' ]]; then
  print -u2 "Usage: prepare-gallery-images.sh INPUT_DIRECTORY OUTPUT_DIRECTORY [--replace]"
  exit 1
fi

input_root=${1:A}
output_root=${2:A}
replace_existing=${3:-}

if [[ ! -d $input_root ]]; then
  print -u2 "Input directory does not exist: $input_root"
  exit 1
fi

mkdir -p "$output_root"

integer prepared=0
integer skipped=0

while IFS= read -r -d '' source_file; do
  relative_path=${source_file#"$input_root"/}
  destination_file="$output_root/${relative_path:r}.jpg"

  if [[ -f $destination_file && $replace_existing != '--replace' ]]; then
    (( skipped += 1 ))
    continue
  fi

  mkdir -p "${destination_file:h}"

  if [[ ${source_file:e:l} == 'heic' || ${source_file:e:l} == 'heif' ]]; then
    temporary_dir=$(mktemp -d /private/tmp/long-yue-heic.XXXXXX)
    thumbnail_file="$temporary_dir/${source_file:t}.png"
    qlmanage -t -s 1800 -o "$temporary_dir" "$source_file" >/dev/null
    if [[ ! -f $thumbnail_file ]]; then
      print -u2 "Could not render HEIC image: $source_file"
      exit 1
    fi
    sips -s format jpeg \
      -s formatOptions 84 \
      "$thumbnail_file" \
      --out "$destination_file" >/dev/null
    rm "$thumbnail_file"
    rmdir "$temporary_dir"
  else
    sips -Z 1800 \
      -s format jpeg \
      -s formatOptions 84 \
      "$source_file" \
      --out "$destination_file" >/dev/null
  fi
  (( prepared += 1 ))
done < <(find "$input_root" -type f \( \
  -iname '*.heic' -o \
  -iname '*.heif' -o \
  -iname '*.jpg' -o \
  -iname '*.jpeg' -o \
  -iname '*.png' \
\) -print0)

print "Prepared $prepared images; skipped $skipped existing files."
