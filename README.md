# music_embeddings

## Data

NSynth, jsonwav format: one `examples.json` plus an `audio/` folder per split.
16 kHz, 4 s, int16 mono WAV. ~39 GB unpacked for all splits.

```bash
./scripts/download_nsynth.sh --split test   # 349 MB, ~20 s
./scripts/download_nsynth.sh                # all splits, ~24 GB
ls data/nsynth-test/                        # examples.json + audio/
```

| Split | Download | Unpacked |
| ----- | -------- | -------- |
| test  | 349 MB   | 524 MB   |
| valid | 1.1 GB   | 1.5 GB   |
| train | 24 GB    | 37 GB    |

Re-running skips archives and unpacked splits. `--no-extract` leaves tarballs
packed. Checksums are optional: add `scripts/nsynth.sha256` with one
`<sha256>  <filename>` per line.

## Dev

```bash
uv sync
uv run python -c "import music_embeddings"
```
