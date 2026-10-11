# Whistle smoke test (sandbox)

Offline check that the **real** Cactus Whistle / Needle WASM engine transcribes a voice clip (outside Obsidian and outside Vitest mocks).

## CLI smoke (recommended)

From any Cloud Agent pod with sibling checkouts under `/agent/repos`:

```bash
bash /agent/repos/obsidian-plugin-development/scripts/cloud-e2e/run-whistle-smoke.sh
```

Optional custom audio:

```bash
bash /agent/repos/obsidian-plugin-development/scripts/cloud-e2e/run-whistle-smoke.sh \
  /agent/repos/whisper-obsidian-plugin/tests/fixtures/smoke-whistle-hello.wav
```

Model cache defaults to `$HOME/.whistle-smoke-cache` (`WHISTLE_CACHE_DIR` to override). First run downloads wasm + weights from Hugging Face (~17 MB).

## Vault attachment

This vault includes `Attachments/whistle-smoke-hello.wav` (same clip as the Whisper repo fixture) for future in-app tests (file upload → Whistle provider).

Expect exit code **0** and non-empty transcript text from the CLI smoke.
