#!/usr/bin/env bash
set -euo pipefail

BASE_URL="http://download.magenta.tensorflow.org/datasets/nsynth"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
if [[ "$(pwd -P)" != "$REPO_ROOT" ]]; then
  echo "run this from the repo root: $REPO_ROOT" >&2
  exit 2
fi
SUMS_FILE="$SCRIPT_DIR/nsynth.sha256"
DEST="data"
EXTRACT=1
SPLITS=()
split_set=0

usage() {
  cat <<'EOF'
Usage: download_nsynth.sh [options]

Options:
  -s, --split SPLIT    test, valid, train, or all (default: all, repeatable)
      --no-extract     keep tarballs packed, do not unpack
  -h, --help           show this help

Sizes (download -> unpacked):
  test   349 MB ->  524 MB
  valid  1.1 GB ->  1.5 GB
  train   24 GB ->   37 GB
EOF
}

while (($#)); do
  case "$1" in
    -s|--split)
      if ((split_set == 0)); then SPLITS=(); split_set=1; fi
      SPLITS+=("$2"); shift 2 ;;
    --no-extract) EXTRACT=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if ((split_set == 0)); then
  SPLITS=(test valid train)
elif [[ " ${SPLITS[*]} " == *" all "* ]]; then
  SPLITS=(test valid train)
fi

mkdir -p "$DEST"

verify() {
  local file="$1" out="$2" expected actual
  [[ -f "$SUMS_FILE" ]] || return 0
  expected="$(awk -v f="$file" '$2 == f { print $1 }' "$SUMS_FILE")"
  if [[ -z "$expected" ]]; then
    echo "no checksum for $file (add it to $SUMS_FILE)"
    return 0
  fi
  actual="$(sha256sum "$out" | awk '{ print $1 }')"
  if [[ "$actual" != "$expected" ]]; then
    echo "checksum mismatch: $out" >&2
    exit 1
  fi
  echo "verified: $out"
}

for split in "${SPLITS[@]}"; do
  file="nsynth-${split}.jsonwav.tar.gz"
  url="$BASE_URL/$file"
  out="$DEST/$file"
  unpacked="$DEST/nsynth-${split}"

  if ((EXTRACT)) && [[ -f "$unpacked/examples.json" ]]; then
    echo "unpacked: $unpacked"
    verify "$file" "$out"
    continue
  fi

  if [[ -f "$out" ]]; then
    echo "exists: $out"
  else
    echo "downloading: $url"
    curl -fL --retry 3 --retry-delay 5 -C - -o "$out" "$url"
  fi
  verify "$file" "$out"

  if ((EXTRACT)); then
    echo "unpacking: $out -> $DEST/"
    tar -xzf "$out" -C "$DEST"
    echo "unpacked: $unpacked"
  fi
done
