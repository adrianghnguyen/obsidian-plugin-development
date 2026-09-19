#!/usr/bin/env bash
# Install Cursor CLI and Google Antigravity ACP bridge for Cloud Agent E2E.
# Idempotent: safe to re-run from env-install.sh.
set -euo pipefail

export PATH="${HOME}/.local/bin:${PATH}"

ensure_nobody_group() {
	if getent group nobody >/dev/null 2>&1; then
		return 0
	fi
	if command -v groupadd >/dev/null 2>&1; then
		sudo groupadd -r nobody 2>/dev/null || sudo groupadd nobody 2>/dev/null || true
	fi
	if ! getent group nobody >/dev/null 2>&1; then
		echo "install-acp-agents: warning — group 'nobody' missing; Antigravity bridge may fail" >&2
	fi
}

install_cursor_cli() {
	if command -v agent >/dev/null 2>&1; then
		echo "install-acp-agents: cursor CLI already present ($(command -v agent))"
		return 0
	fi
	echo "install-acp-agents: installing Cursor CLI"
	curl -fsSL https://cursor.com/install | bash
}

install_antigravity_bridge() {
	local dest="${HOME}/.local/bin/agy_acp_server.par"
	if [[ -x "${dest}" ]]; then
		echo "install-acp-agents: antigravity bridge already present (${dest})"
		return 0
	fi
	mkdir -p "${HOME}/.local/bin"
	local tmp archive url par
	tmp="$(mktemp -d)"
	url="$(
		curl -fsSL https://cdn.agentclientprotocol.com/registry/v1/latest/registry.json \
			| python3 -c "
import json, sys
data = json.load(sys.stdin)
for agent in data.get('agents', []):
    if agent.get('id') == 'antigravity-acp':
        print(agent['distribution']['binary']['linux-x86_64']['archive'])
        break
"
	)"
	if [[ -z "${url}" ]]; then
		echo "install-acp-agents: could not resolve antigravity linux-x86_64 archive URL" >&2
		exit 1
	fi
	echo "install-acp-agents: downloading antigravity bridge"
	curl -fsSL -o "${tmp}/agy.zip" "${url}"
	unzip -q -o "${tmp}/agy.zip" -d "${tmp}/extract"
	par="$(find "${tmp}/extract" -name 'agy_acp_server.par' -print -quit)"
	if [[ -z "${par}" ]]; then
		rm -rf "${tmp}"
		echo "install-acp-agents: agy_acp_server.par not found in archive" >&2
		exit 1
	fi
	install -m 755 "${par}" "${dest}"
	rm -rf "${tmp}"
	echo "install-acp-agents: installed ${dest}"
}

ensure_antigravity_gemini_settings() {
	# Headless cloud: GEMINI_API_KEY from environment + gemini provider mode.
	local dir="${HOME}/.gemini/antigravity-cli"
	local settings="${dir}/settings.json"
	if [[ -n "${GEMINI_API_KEY:-}" ]] && [[ ! -f "${settings}" ]]; then
		mkdir -p "${dir}"
		printf '%s\n' '{"modelProvider":"gemini"}' >"${settings}"
		echo "install-acp-agents: wrote ${settings} for API-key auth"
	fi
}

ensure_nobody_group
install_cursor_cli
install_antigravity_bridge
ensure_antigravity_gemini_settings

echo "install-acp-agents: done (agent=$(command -v agent 2>/dev/null || echo missing), bridge=${HOME}/.local/bin/agy_acp_server.par)"
