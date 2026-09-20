#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=paths.env
source "$SCRIPT_DIR/paths.env"

VAULT="${CLOUD_E2E_VAULT:-$HOME/plugin-sandbox-Obsidian}"
# Custom AI21 trivia corpus (not the small Notes/ fixture set).
CORPUS_ROOT="$VAULT/Seinfeld (custom)"
DEST="$CORPUS_ROOT/episodes"
TRIVIA_DIR="$CORPUS_ROOT/trivia"
CACHE="${CLOUD_E2E_SEINFELD_CACHE:-$HOME/.cache/cloud-e2e-seinfeld}"
REPO="${CLOUD_E2E_SEINFELD_REPO:-https://github.com/AI21Labs/multi-window-chunk-size.git}"
REF="${CLOUD_E2E_SEINFELD_REF:-master}"
EVAL_JSON="${CLOUD_E2E_SEINFELD_EVAL_JSON:-$SCRIPT_DIR/fixtures/seinfeld-eval.json}"

mkdir -p "$DEST" "$TRIVIA_DIR" "$CACHE"

if [ ! -d "$CACHE/.git" ]; then
  echo "Cloning Seinfeld trivia corpus (shallow)…"
  git clone --depth 1 --branch "$REF" "$REPO" "$CACHE"
else
  echo "Updating Seinfeld corpus cache…"
  git -C "$CACHE" fetch --depth 1 origin "$REF" 2>/dev/null || true
  git -C "$CACHE" checkout "$REF" 2>/dev/null || true
  git -C "$CACHE" pull --ff-only origin "$REF" 2>/dev/null || true
fi

SRC="$CACHE/seinfeld_trivia/documents_content"
if [ ! -d "$SRC" ]; then
  echo "Missing $SRC in AI21 repo" >&2
  exit 1
fi

cp -a "$SRC/." "$DEST/"
COUNT="$(find "$DEST" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')"
echo "Seinfeld episodes materialized: $COUNT files under $DEST"

# Remove legacy path from earlier cloud-e2e layouts (episodes only lived here).
if [ -d "$VAULT/Seinfeld/episodes" ] && [ "$VAULT/Seinfeld/episodes" != "$DEST" ]; then
  rm -rf "$VAULT/Seinfeld"
fi

# Write vault-native Q&A notes from the curated eval fixture (same 34 questions as AI21 data.json).
if [ -f "$EVAL_JSON" ]; then
  python3 - "$EVAL_JSON" "$TRIVIA_DIR" "$CORPUS_ROOT" <<'PY'
import json, pathlib, re, sys

eval_path, trivia_dir, corpus_root = map(pathlib.Path, sys.argv[1:])
doc = json.loads(eval_path.read_text(encoding="utf-8"))
examples = doc.get("examples") or []
trivia_dir.mkdir(parents=True, exist_ok=True)

# Clear prior generated trivia notes (keep folder).
for old in trivia_dir.glob("Q*.md"):
    old.unlink()

def slug(text: str, n: int = 48) -> str:
    s = re.sub(r"[^\w\s-]", "", text, flags=re.UNICODE)
    s = re.sub(r"\s+", "-", s.strip()).strip("-")
    return (s[:n] or "question").rstrip("-")

index_lines = [
    "# Seinfeld (custom) — AI21 trivia",
    "",
    "In-house AI21 trivia over TV episode transcripts.",
    "Corpus and questions live in the [AI21Labs/multi-window-chunk-size](https://github.com/AI21Labs/multi-window-chunk-size) demo repo (`seinfeld_trivia/`), not a standalone dataset project.",
    "",
    "## Layout",
    "",
    "| Path | Role |",
    "| --- | --- |",
    "| `episodes/` | 174 episode markdown transcripts (`documents_content`) |",
    "| `trivia/` | Curated Q&A notes (one note per eval question) |",
    "",
    "## How Q&A maps to files",
    "",
    "Each trivia note is one **query** (question). The note body holds the gold **answer** and a wikilink to the gold **episode** under `episodes/` (filename like `S09E10.md`).",
    "",
    "Upstream `data.json` shape: `examples[].query` + `examples[].answer` + `examples[].targets[].file_name`.",
    "Sandbox fixture: `scripts/cloud-e2e/fixtures/seinfeld-eval.json` → `expectedEpisode` (= `targets[0].file_name`).",
    "",
    "Skill: `seek-seinfeld-eval`.",
    "",
    f"Source: {doc.get('source', '')}",
    "",
    "## Questions",
    "",
]

for i, ex in enumerate(examples, start=1):
    qid = ex.get("id") or f"q-{i}"
    query = (ex.get("query") or "").strip()
    answer = (ex.get("answer") or "").strip()
    episode = (ex.get("expectedEpisode") or "").strip()
    ep_stem = episode[:-3] if episode.endswith(".md") else episode
    fname = f"Q{i:02d}-{slug(query)}.md"
    body = "\n".join(
        [
            "---",
            f"id: {qid}",
            "corpus: seinfeld-custom",
            "type: seinfeld-trivia",
            f"expected_episode: {episode}",
            "---",
            "",
            f"# {query}",
            "",
            f"**Answer:** {answer}",
            "",
            f"**Gold episode:** [[../episodes/{ep_stem}|{episode}]]",
            "",
            "Ask Seek this question in the sandbox vault; rank-1 should be the gold episode note.",
            "",
        ]
    )
    (trivia_dir / fname).write_text(body, encoding="utf-8")
    index_lines.append(f"{i}. [[{fname[:-3]}|{query}]] → `{episode}`")

index_lines.append("")
(corpus_root / "README.md").write_text("\n".join(index_lines) + "\n", encoding="utf-8")
print(f"Seinfeld trivia notes: {len(examples)} under {trivia_dir}")
PY
else
  echo "WARNING: eval fixture missing at $EVAL_JSON; skipped trivia notes" >&2
fi
