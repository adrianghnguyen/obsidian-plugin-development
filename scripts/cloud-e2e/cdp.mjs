#!/usr/bin/env node
/**
 * Tiny Chrome DevTools Protocol helper for the Cloud E2E vault.
 * Talks to localhost only. Never prints secret values.
 */
import { flattenBindings } from "./load-bindings.mjs";

const PORT = process.env.CLOUD_E2E_CDP_PORT || "9222";
const ORIGIN = `http://127.0.0.1:${PORT}`;

async function listTargets() {
	const res = await fetch(`${ORIGIN}/json/list`);
	if (!res.ok) {
		throw new Error(`CDP list failed: ${res.status} (is Obsidian up on ${PORT}?)`);
	}
	return res.json();
}

function pickPage(targets) {
	const pages = targets.filter((t) => t.type === "page" && t.webSocketDebuggerUrl);
	return (
		pages.find((t) => /obsidian/i.test(t.title || "") || /obsidian/i.test(t.url || "")) ||
		pages[0]
	);
}

function cdpSession(wsUrl) {
	return new Promise((resolve, reject) => {
		const ws = new WebSocket(wsUrl);
		let nextId = 1;
		const pending = new Map();
		ws.addEventListener("open", () => resolve({ ws, send }));
		ws.addEventListener("error", (err) => reject(err));
		ws.addEventListener("message", (ev) => {
			const msg = JSON.parse(String(ev.data));
			if (msg.id && pending.has(msg.id)) {
				const { resolve: ok, reject: fail } = pending.get(msg.id);
				pending.delete(msg.id);
				if (msg.error) fail(new Error(msg.error.message || JSON.stringify(msg.error)));
				else ok(msg.result);
			}
		});
		function send(method, params) {
			const id = nextId++;
			return new Promise((ok, fail) => {
				pending.set(id, { resolve: ok, reject: fail });
				ws.send(JSON.stringify({ id, method, params }));
			});
		}
	});
}

export async function evaluate(expression, { awaitPromise = false } = {}) {
	const targets = await listTargets();
	const page = pickPage(targets);
	if (!page) throw new Error("No CDP page target");
	const { ws, send } = await cdpSession(page.webSocketDebuggerUrl);
	try {
		const result = await send("Runtime.evaluate", {
			expression,
			returnByValue: true,
			awaitPromise,
		});
		if (result.exceptionDetails) {
			const text =
				result.exceptionDetails.exception?.description ||
				result.exceptionDetails.text ||
				"evaluate failed";
			throw new Error(text);
		}
		return result.result?.value;
	} finally {
		ws.close();
	}
}

export async function waitForApp(timeoutMs = 60000) {
	const start = Date.now();
	let lastErr;
	while (Date.now() - start < timeoutMs) {
		try {
			const ready = await evaluate(
				`typeof app !== 'undefined' && !!(app.vault && app.secretStorage && app.workspace)`,
			);
			if (ready) return;
		} catch (err) {
			lastErr = err;
		}
		await new Promise((r) => setTimeout(r, 500));
	}
	throw lastErr || new Error("Timed out waiting for Obsidian app");
}

export async function injectSecrets() {
	const rows = flattenBindings();
	const report = [];
	const wroteIds = new Set();
	for (const row of rows) {
		const value = process.env[row.cursorEnv];
		if (!value) {
			report.push({
				pluginId: row.pluginId,
				env: row.cursorEnv,
				id: row.secretStorageId,
				skipped: true,
				reason: "unset",
			});
			continue;
		}
		if (!wroteIds.has(row.secretStorageId)) {
			await evaluate(
				`(function(id,value){app.secretStorage.setSecret(id,value);return 1})(${JSON.stringify(row.secretStorageId)}, ${JSON.stringify(value)})`,
			);
			wroteIds.add(row.secretStorageId);
		}
		const len = await evaluate(
			`(function(id){const v=app.secretStorage.getSecret(id);return v?String(v.length):"0"})(${JSON.stringify(row.secretStorageId)})`,
		);
		let pointer = null;
		if (row.pointer?.pluginId && row.pointer.path) {
			pointer = await evaluate(
				`(function(pluginId,path,id){
  const p=app.plugins.plugins[pluginId];
  if(!p||!p.settings) return {ok:false,reason:"plugin-not-loaded"};
  let cur=p.settings;
  for(let i=0;i<path.length-1;i++){
    const k=path[i];
    if(cur[k]==null||typeof cur[k]!=="object") cur[k]={};
    cur=cur[k];
  }
  cur[path[path.length-1]]=id;
  if(typeof p.saveSettings==="function") p.saveSettings();
  else if(p.settingsService&&typeof p.settingsService.updateSettings==="function") p.settingsService.updateSettings(p.settings);
  return {ok:true};
})(${JSON.stringify(row.pointer.pluginId)}, ${JSON.stringify(row.pointer.path)}, ${JSON.stringify(row.secretStorageId)})`,
			);
		}
		report.push({
			pluginId: row.pluginId,
			env: row.cursorEnv,
			id: row.secretStorageId,
			len: Number(len),
			pointer,
		});
	}
	return report;
}

export async function probeSecrets() {
	const rows = flattenBindings();
	const out = [];
	for (const row of rows) {
		const envLen = process.env[row.cursorEnv] ? String(process.env[row.cursorEnv].length) : "0";
		let idLen = 0;
		let pointerValue = null;
		try {
			idLen = Number(
				await evaluate(
					`(function(id){const v=app.secretStorage.getSecret(id);return v?String(v.length):"0"})(${JSON.stringify(row.secretStorageId)})`,
				),
			);
			if (row.pointer?.pluginId && row.pointer.path) {
				pointerValue = await evaluate(
					`(function(pluginId,path){
  const p=app.plugins.plugins[pluginId];
  if(!p||!p.settings) return null;
  return path.reduce((a,k)=>a==null?null:a[k], p.settings);
})(${JSON.stringify(row.pointer.pluginId)}, ${JSON.stringify(row.pointer.path)})`,
				);
			}
		} catch {
			idLen = -1;
		}
		out.push({
			pluginId: row.pluginId,
			env: row.cursorEnv,
			envSet: Number(envLen) > 0,
			id: row.secretStorageId,
			idLen,
			pointer: row.pointer ? { path: row.pointer.path, value: pointerValue } : null,
		});
	}
	return out;
}

const cmd = process.argv[2];
if (cmd === "wait") {
	await waitForApp();
	console.log("obsidian-app-ready");
} else if (cmd === "inject") {
	await waitForApp();
	const report = await injectSecrets();
	console.log(JSON.stringify(report));
} else if (cmd === "probe") {
	await waitForApp();
	const report = await probeSecrets();
	console.log(JSON.stringify(report, null, 2));
} else if (cmd === "dismiss-starter") {
	const ready = await evaluate(
		`typeof app !== 'undefined' && !!(app.vault && app.workspace)`,
	).catch(() => false);
	if (ready) {
		console.log("obsidian-app-ready");
	} else {
		await evaluate(
			`[...document.querySelectorAll("button")].find(b=>/^(Open|Quick start)$/i.test(b.innerText.trim()))?.click()`,
		);
		await waitForApp(90000);
		console.log("obsidian-app-ready");
	}
} else if (cmd === "enable-plugins") {
	await waitForApp();
	const report = await evaluate(
		`(async () => {
			const before = app.plugins.isEnabled();
			if (!before) await app.plugins.setEnable(true);
			await app.plugins.loadManifests();
			const wanted = Array.from(app.plugins.enabledPlugins || []);
			for (const id of wanted) {
				try { await app.plugins.enablePlugin(id); } catch {}
			}
			return JSON.stringify({
				wasRestricted: !before,
				enabled: app.plugins.isEnabled(),
				loaded: Object.keys(app.plugins.plugins),
			});
		})()`,
		{ awaitPromise: true },
	);
	console.log(typeof report === "string" ? report : JSON.stringify(report));
} else if (cmd === "eval-raw") {
	const code = process.argv[3];
	if (!code) {
		console.error("usage: cdp.mjs eval-raw <expression>");
		process.exit(1);
	}
	const value = await evaluate(code, { awaitPromise: true });
	console.log(typeof value === "string" ? value : JSON.stringify(value));
} else if (cmd === "eval") {
	await waitForApp();
	const code = process.argv[3];
	if (!code) {
		console.error("usage: cdp.mjs eval <expression>");
		process.exit(1);
	}
	const value = await evaluate(code, { awaitPromise: true });
	console.log(typeof value === "string" ? value : JSON.stringify(value));
} else if (import.meta.url === `file://${process.argv[1]}`) {
	console.error("usage: cdp.mjs wait|inject|probe|dismiss-starter|enable-plugins|eval|eval-raw");
	process.exit(1);
}
