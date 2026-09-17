import { existsSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));

function reposRoot() {
	if (process.env.CLOUD_E2E_REPOS) return process.env.CLOUD_E2E_REPOS;
	if (existsSync("/agent/repos")) return "/agent/repos";
	return join(HERE, "../../..");
}

const PLUGIN_FILES = [
	["whisper-obsidian-plugin", "whisper"],
	["obsidian-agent-client", "agent-client"],
];

function readJson(path) {
	return JSON.parse(readFileSync(path, "utf8"));
}

/**
 * Merge plugin-owned `.cloud-e2e/secret-bindings.json` files.
 * Falls back to copies under scripts/cloud-e2e/bindings/.
 */
export function loadSecretBindings() {
	const root = reposRoot();
	const docs = [];
	for (const [repo, pluginId] of PLUGIN_FILES) {
		const owned = join(root, repo, ".cloud-e2e", "secret-bindings.json");
		const fallback = join(HERE, "bindings", `${pluginId}.json`);
		const path = existsSync(owned) ? owned : fallback;
		if (!existsSync(path)) continue;
		docs.push(readJson(path));
	}
	const seekFallback = join(HERE, "bindings", "seek.json");
	if (existsSync(seekFallback)) docs.push(readJson(seekFallback));
	return docs;
}

export function flattenBindings(docs = loadSecretBindings()) {
	const rows = [];
	for (const doc of docs) {
		for (const b of doc.bindings || []) {
			rows.push({ pluginId: doc.pluginId, ...b });
		}
	}
	return rows;
}
