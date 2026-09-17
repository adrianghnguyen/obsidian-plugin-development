---
name: obsidian-secret-mapping
description: >-
  Map Cursor environment variables to Obsidian secretStorage ids and plugin
  settings pointers. Use when API keys work in Cursor but not in a plugin,
  Cloud E2E inject looks skipped, Keychain looks empty, or troubleshooting
  Whisper / Agent Client / Seek credentials.
---

# Obsidian secret mapping (Cursor env → plugin)

Two layers. Mixing them up is the usual failure.

| Layer | Where | Holds |
| --- | --- | --- |
| **Value** | `app.secretStorage` (OS keychain) | The API key |
| **Pointer** | vault `data.json` (synced settings) | Which secret **id** to read |

Never put the key in `data.json`. Never interpolate a key into `obsidian eval` argv.

Cursor Cloud / environment secrets show up as **process env vars** on the agent (`GEMINI_API_KEY`, …). Injection copies that value into `secretStorage` over localhost CDP (`scripts/cloud-e2e/cdp.mjs inject`). Probe with **length only**.

Per-plugin maps: `<plugin-repo>/.cloud-e2e/secret-bindings.json`. Harness merges those files.

## How each plugin actually reads

### Seek (`seek`)

No `secretStorage`. Nothing to map.

### Whisper (`whisper`)

Source: `SettingsManager.loadKeysFromSecretStorage`, `SECRET_IDS`, `resolveWhisperApiKey`.

| Feature | Pointer in `data.json` | Id it `getSecret`s | Cursor env |
| --- | --- | --- | --- |
| Gemini REST + Live | none (hardcoded) | `gemini-api-key` → `settings.geminiApiKey` | `GEMINI_API_KEY` |
| OpenAI field / post-process OpenAI | none (hardcoded) | `openai-api-key` → `settings.openAiApiKey` | `OPENAI_API_KEY` |
| Anthropic post-process | none (hardcoded) | `anthropic-api-key` | `ANTHROPIC_API_KEY` |
| Custom post-process | none (hardcoded) | `post-processing-api-key` | none unless you add one |
| OpenAI Whisper **endpoint** | `whisperApiKeySecretId` | whatever that string is → `settings.apiKey` | usually `OPENAI_API_KEY` into `openai-api-key`, **and** set the pointer to `openai-api-key` |

Empty `whisperApiKeySecretId` → OpenAI Whisper transcribe has no Bearer token even if `openai-api-key` is populated. Gemini Live does **not** use that pointer.

Probe (lengths only):

```javascript
(() => {
  const p = app.plugins.plugins.whisper;
  const s = p?.settings;
  const get = (id) => (app.secretStorage.getSecret(id) || "").length;
  return JSON.stringify({
    loaded: !!p,
    whisperApiKeySecretId: s?.whisperApiKeySecretId || "",
    apiKeyLen: (s?.apiKey || "").length,
    geminiSettingsLen: (s?.geminiApiKey || "").length,
    ids: {
      gemini: get("gemini-api-key"),
      openai: get("openai-api-key"),
      anthropic: get("anthropic-api-key"),
    },
  });
})()
```

### Agent Client (`agent-client`)

**Presets** (`session-helpers.buildAgentConfigWithApiKey` → `AcpClient` spawn):

- Registry says which **env var name** to export (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GEMINI_API_KEY`, `MISTRAL_API_KEY`, `KIRO_API_KEY`).
- The **id** is `settings.presetAgents[presetId].apiKeySecretId` from `data.json`.
- If that string is **empty**, spawn does **not** attach a key (account login). Filling `secretStorage` alone is not enough.

Fresh-vault E2E must write those pointers (fixture `data.json` or CDP `saveSettings`). Prefer the **default** ids from legacy migration so they can share Whisper’s ids:

| Preset | Env exported at spawn | Default id to point at |
| --- | --- | --- |
| `claude-code-acp` | `ANTHROPIC_API_KEY` | `claude-api-key` (fallback `agent-client-claude-api-key`) |
| `codex-acp` | `OPENAI_API_KEY` | `openai-api-key` (same id as Whisper) |
| `gemini-cli` | `GEMINI_API_KEY` | `gemini-api-key` (same id as Whisper) |
| `mistral-vibe` | `MISTRAL_API_KEY` | `mistral-api-key` |
| `kiro-cli` | `KIRO_API_KEY` | no shipped default — E2E uses `agent-client-kiro-api-key` |
| `opencode`, `hermes-agent` | none | CLI login only |

**Voice** (`VoiceInputModule.resolveApiKey`):

```text
settings.voiceInput.geminiApiKeySecretId || "agent-client-gemini-live-api-key"
```

Empty pointer still reads `agent-client-gemini-live-api-key`. Same Cursor `GEMINI_API_KEY` must be copied here **and** to `gemini-api-key` (Whisper / Gemini CLI).

Probe:

```javascript
(() => {
  const p = app.plugins.plugins["agent-client"];
  const presets = p?.settings?.presetAgents || {};
  const get = (id) => (app.secretStorage.getSecret(id) || "").length;
  const rows = {};
  for (const [id, a] of Object.entries(presets)) {
    const sid = a.apiKeySecretId || "";
    rows[id] = { apiKeySecretId: sid, len: sid ? get(sid) : 0 };
  }
  const voiceId =
    p?.settings?.voiceInput?.geminiApiKeySecretId ||
    "agent-client-gemini-live-api-key";
  return JSON.stringify({
    loaded: !!p,
    presets: rows,
    voice: { id: voiceId, len: get(voiceId) },
  });
})()
```

## Troubleshooting order

1. Cursor env present? `echo ${#GEMINI_API_KEY}` (not the value).
2. Plugin loaded? Probe `loaded`.
3. Pointer set? Empty `apiKeySecretId` / `whisperApiKeySecretId` is the Agent Client / Whisper-OpenAI footgun.
4. Value at that id? `getSecret(id).length`.
5. In-memory hydrate? Whisper Gemini uses `settings.geminiApiKey` after `loadSettings`. Reload the plugin if you injected after onload.
6. Shared ids: one `setSecret("gemini-api-key")` feeds Whisper and Gemini CLI if the CLI pointer matches. Voice is a **different** id.

## Inject vs eval

`node scripts/cloud-e2e/cdp.mjs inject` — CDP, not argv.  
`node scripts/cloud-e2e/cdp.mjs probe` — lengths + pointers from merged bindings.

See [obsidian-cloud-e2e](../obsidian-cloud-e2e/SKILL.md), [obsidian-settings-secrets](../obsidian-settings-secrets/SKILL.md).
