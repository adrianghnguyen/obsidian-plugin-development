# Refresh Cursor marketplace mirror for this plugin to current main (unpins stale SHA).
# Known Cursor bug: personal /add-plugin marketplaces stay on the first indexed commit;
# `plugin marketplace update` reindexes without advancing the pin. Remove + wipe + re-add.
$ErrorActionPreference = 'Stop'

$RepoUrl = 'https://github.com/adrianghnguyen/obsidian-plugin-development'
$MarketplaceName = 'adrianghnguyen-obsidian-plugins'
$PluginId = 'obsidian-plugin-development'
$RepoRoot = if ($PSScriptRoot) {
  (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
} else {
  (Get-Location).Path
}

$cursorAgent = Join-Path $env:LOCALAPPDATA 'cursor-agent\cursor-agent.cmd'
if (-not (Test-Path $cursorAgent)) {
  $cmd = Get-Command cursor-agent -ErrorAction SilentlyContinue
  if ($cmd) { $cursorAgent = $cmd.Source } else { throw 'cursor-agent not found' }
}

function Invoke-CursorAgent {
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$AgentArgs)
  # -f: non-interactive trust for scripted marketplace add/remove
  $all = @('-f') + $AgentArgs
  $argLine = ($all | ForEach-Object {
    if ($_ -match '[\s"]') { '"' + ($_ -replace '"', '\"') + '"' } else { $_ }
  }) -join ' '
  cmd.exe /c "`"$cursorAgent`" $argLine"
  if ($LASTEXITCODE -ne 0) { throw "cursor-agent failed: $argLine" }
}

Write-Host "Removing marketplace $MarketplaceName (if present)…"
$ErrorActionPreference = 'Continue'
cmd.exe /c "`"$cursorAgent`" plugin marketplace remove $MarketplaceName" 2>&1 | Out-Host
cmd.exe /c "`"$cursorAgent`" plugin marketplace remove `"$RepoUrl`"" 2>&1 | Out-Host
$ErrorActionPreference = 'Stop'

$marketplaceDir = Join-Path $env:USERPROFILE '.cursor\plugins\marketplaces\github.com\adrianghnguyen\obsidian-plugin-development'
$cacheDir = Join-Path $env:USERPROFILE '.cursor\plugins\cache\adrianghnguyen-obsidian-plugins'
foreach ($dir in @($marketplaceDir, $cacheDir)) {
  if (Test-Path $dir) {
    Write-Host "Deleting $dir"
    Remove-Item -LiteralPath $dir -Recurse -Force
  }
}

Write-Host "Re-adding marketplace at git-ref main…"
Invoke-CursorAgent @('plugin', 'marketplace', 'add', '--git-ref', 'main', $RepoUrl)

# Ensure local :latest junction still points at this working tree (not a marketplace SHA).
$localPlugin = Join-Path $env:USERPROFILE ".cursor\plugins\local\$PluginId"
$needLink = $true
if (Test-Path $localPlugin) {
  $item = Get-Item -LiteralPath $localPlugin -Force
  $target = @($item.Target) -join ''
  if ($item.LinkType -eq 'Junction' -and ($target -ieq $RepoRoot)) { $needLink = $false }
  else {
    if ($item.LinkType) { cmd /c "rmdir `"$localPlugin`"" | Out-Null }
    else { Remove-Item -LiteralPath $localPlugin -Recurse -Force }
  }
}
if ($needLink) {
  Write-Host "Creating local junction -> $RepoRoot"
  New-Item -ItemType Directory -Force -Path (Split-Path $localPlugin) | Out-Null
  cmd /c "mklink /J `"$localPlugin`" `"$RepoRoot`"" | Out-Host
}

Write-Host 'Marketplace refresh done. Reload Cursor window to pick up skills.'
# Show what got indexed
$mirrors = Get-ChildItem $marketplaceDir -Directory -ErrorAction SilentlyContinue
if ($mirrors) {
  Write-Host 'Marketplace mirror folder(s):'
  $mirrors | ForEach-Object { Write-Host "  $($_.Name)  $($_.LastWriteTime)" }
  $head = (git -C $RepoRoot rev-parse HEAD).Trim()
  Write-Host "Repo HEAD: $head"
  $hasSkills = Test-Path (Join-Path $mirrors[0].FullName 'skills\ux-design\SKILL.md')
  Write-Host "Mirror has ux-design: $hasSkills"
}
