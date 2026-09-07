#!/usr/bin/env node
/**
 * Launches Obsidian with remote debugging enabled (port 9222).
 * Opens sandbox vault from DEV_VAULT (.env). Use before attaching Cursor's debugger.
 *
 * Windows: C:\Program Files\Obsidian\Obsidian.exe or %LOCALAPPDATA%\Programs\obsidian\Obsidian.exe
 * macOS:   /Applications/Obsidian.app
 * Linux:   obsidian (if in PATH)
 */

import { spawn } from "child_process";
import { existsSync } from "fs";
import { platform } from "os";
import dotenv from "dotenv";

dotenv.config();

const PORT = 9222;

function getObsidianPath() {
	switch (platform()) {
		case "win32": {
			const candidates = [
				process.env.OBSIDIAN_PATH,
				"C:\\Program Files\\Obsidian\\Obsidian.exe",
				`${process.env.LOCALAPPDATA || ""}\\Programs\\obsidian\\Obsidian.exe`,
			].filter(Boolean);
			const exe = candidates.find((p) => existsSync(p));
			if (!exe) return null;
			const devVault = process.env.DEV_VAULT;
			const args = ["--enable-debug-logging", `--remote-debugging-port=${PORT}`];
			if (devVault) args.push(`obsidian://open?path=${encodeURIComponent(devVault)}`);
			return [exe, args];
		}
		case "darwin": {
			const app = "/Applications/Obsidian.app";
			if (!existsSync(app)) return null;
			const devVault = process.env.DEV_VAULT;
			const args = ["-n", app, "--args", "--enable-debug-logging", `--remote-debugging-port=${PORT}`];
			if (devVault) args.push(`obsidian://open?path=${encodeURIComponent(devVault)}`);
			return ["open", args];
		}
		case "linux": {
			const devVault = process.env.DEV_VAULT;
			const args = ["--enable-debug-logging", `--remote-debugging-port=${PORT}`];
			if (devVault) args.push(`obsidian://open?path=${encodeURIComponent(devVault)}`);
			return ["obsidian", args];
		}
	}
	return null;
}

const args = getObsidianPath();
if (!args) {
	console.error("Could not find Obsidian. On Windows try: C:\\Program Files\\Obsidian\\Obsidian.exe");
	process.exit(1);
}

const [cmd, cmdArgs] = args;
const child = spawn(cmd, cmdArgs, { stdio: "inherit" });
child.on("error", (err) => {
	console.error("Failed to start Obsidian:", err);
	process.exit(1);
});
console.log(`Obsidian launching with remote debugging on port ${PORT}. Attach in Cursor: Run > Attach to Obsidian Renderer`);
child.unref();
