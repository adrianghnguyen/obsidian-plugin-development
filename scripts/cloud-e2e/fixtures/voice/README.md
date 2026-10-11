# Shared sandbox voice clip

| File | Role |
| --- | --- |
| `smoke-hello.wav` | Short spoken phrase (~2 s, 22 kHz source; ffmpeg resamples in plugin smokes). Copied to vault `Attachments/voice-smoke-hello.wav` on materialize. |

Used by `run-voice-clip-smoke.sh` when no audio path is passed. Plugins should accept `CLOUD_E2E_VOICE_CLIP` or a CLI path and not depend on plugin-local copies only.

To regenerate (optional):

```bash
espeak-ng -w smoke-hello.wav "Hello, this is a voice clip smoke test."
```
