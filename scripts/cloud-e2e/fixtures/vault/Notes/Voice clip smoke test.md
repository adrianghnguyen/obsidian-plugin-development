# Voice clip smoke test (sandbox)

Shared **speech clip** for offline smokes that feed real audio into a plugin (STT, voice features, etc.). Not Vitest — each plugin registers its own runner.

## Shared clip

| Location | Path |
| --- | --- |
| Cloud E2E fixture | `obsidian-plugin-development/scripts/cloud-e2e/fixtures/voice/smoke-hello.wav` |
| This vault | `Attachments/voice-smoke-hello.wav` |

Override with a second argument or `CLOUD_E2E_VOICE_CLIP`.

## Run a registered smoke

```bash
bash /agent/repos/obsidian-plugin-development/scripts/cloud-e2e/run-voice-clip-smoke.sh <plugin-key> [audio-path]
```

Registered keys live in `voice-clip-smokes.sh` (e.g. `whistle` → Whisper plugin Whistle / Needle WASM batch transcribe).

Example:

```bash
bash /agent/repos/obsidian-plugin-development/scripts/cloud-e2e/run-voice-clip-smoke.sh whistle
```

Expect exit code **0** and non-empty output from that plugin’s smoke (for Whistle: transcript text).

## Add a plugin

1. Commit or reuse `fixtures/voice/smoke-hello.wav` (or pass custom audio).
2. In your repo: npm script that accepts an audio path (and honors `CLOUD_E2E_VOICE_CLIP` when argv is omitted).
3. Add a `case` arm in `voice-clip-smokes.sh` and append the key to `VOICE_CLIP_SMOKE_KEYS`.
