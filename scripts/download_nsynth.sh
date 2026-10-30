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
FORMAT="tfrecord"
SPLITS=()
split_set=0

usage() {
  cat <<'EOF'
Usage: download_nsynth.sh [options]

Options:
  -s, --split SPLIT    test, valid, train, or all (default: all, repeatable)
  -f, --format FORMAT  tfrecord (default) or jsonwav
  -h, --help           show this help

Note:
  train tfrecord is ~69 GB, valid ~3 GB, test ~1 GB.
  jsonwav tarballs are smaller on the wire but expand to ~39 GB of WAV.
EOF
}

while (($#)); do
  case "$1" in
    -s|--split)
      if ((split_set == 0)); then SPLITS=(); split_set=1; fi
      SPLITS+=("$2"); shift 2 ;;
    -f|--format) FORMAT="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if ((split_set == 0)); then
  SPLITS=(test valid train)
elif [[ " ${SPLITS[*]} " == *" all "* ]]; then
  SPLITS=(test valid train)
fi

case "$FORMAT" in
  tfrecord) EXT="tfrecord" ;;
  jsonwav) EXT="jsonwav.tar.gz" ;;
  *) echo "unsupported format: $FORMAT" >&2; exit 2 ;;
esac

mkdir -p "$DEST"

for split in "${SPLITS[@]}"; do
  file="nsynth-${split}.${EXT}"
  url="$BASE_URL/$file"
  out="$DEST/$file"

  if [[ -f "$out" ]]; then
    echo "exists: $out"
  else
    echo "downloading: $url"
    curl -fL --retry 3 --retry-delay 5 -C - -o "$out" "$url"
  fi

  if [[ -f "$SUMS_FILE" ]]; then
    expected="$(awk -v f="$file" '$2 == f { print $1 }' "$SUMS_FILE")"
    if [[ -n "$expected" ]]; then
      actual="$(sha256sum "$out" | awk '{ print $1 }')"
      if [[ "$actual" != "$expected" ]]; then
        echo "checksum mismatch: $out" >&2
        exit 1
      fi
      echo "verified: $out"
    else
      echo "no checksum for $file (add it to $SUMS_FILE)"
    fi
  fi
done
