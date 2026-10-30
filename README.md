# music_embeddings

## Download the data

This pulls all three splits into `data/`. About 73 GB, so check free space first.
On a fast connection that is roughly 1.5-2 hours.

1. Run the downloader from the repo root.

   ```bash
   ./scripts/download_nsynth.sh
   ```

2. Check it landed.

   ```bash
   ls -lh data/
   ```

Re-running is safe. Files you already have are skipped.

### Want less data first?

Test split is about 1 GB, roughly 1-2 minutes.

```bash
./scripts/download_nsynth.sh --split test
```

Other choices:

```bash
./scripts/download_nsynth.sh --split valid   # ~3 GB
./scripts/download_nsynth.sh --split train   # ~69 GB
```

### Format

```bash
./scripts/download_nsynth.sh --format jsonwav   # tarballs, ~23 GB; unpack to ~39 GB
```

### Checksums

None are pinned yet. Add `scripts/nsynth.sha256`, one line per file:

```
<sha256>  nsynth-test.tfrecord
```

The script checks a file when its entry exists.

`data/` is gitignored. Keep the dataset out of git.

