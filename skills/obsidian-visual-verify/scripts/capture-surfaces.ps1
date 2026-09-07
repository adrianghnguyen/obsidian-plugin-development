# Capture Obsidian UI surfaces for visual verification (serial CLI only).
#
# Usage:
#   .\capture-surfaces.ps1 -Vault <sandbox-vault-name> -PluginId <id> -Surface Main
#   .\capture-surfaces.ps1 -Vault <sandbox-vault-name> -PluginId <id> -Surface Settings,PluginModal
#   .\capture-surfaces.ps1 -Vault <name> -PluginId <id> -OpenCommandId "<id>:open-modal" -Surface PluginModal

param(
    [Parameter(Mandatory = $true)]
    [string]$Vault,
    [Parameter(Mandatory = $true)]
    [string]$PluginId,
    [ValidateSet('Main', 'StatusBar', 'Settings', 'PluginModal')]
    [string[]]$Surface = @('Main'),
    [string]$OpenCommandId = '',
    [string]$OutputDir = '',
    [int]$CliTimeoutSec = 15,
    [int]$OpenWaitSec = 5,
    [int]$UiSettleSec = 2,
    [int]$LaunchWaitSec = 120,
    [switch]$NoLaunch
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'ObsidianCliSerial.ps1')

if (-not $OutputDir) {
    $OutputDir = Join-Path (Get-Location) ".tmp\visual-$Vault"
}

$surfaceFiles = @{
    Main         = 'main.png'
    StatusBar    = 'status-bar.png'
    Settings     = 'plugin-settings.png'
    PluginModal  = 'plugin-modal.png'
}

$DismissUiCode = @'
(() => {
  document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));
  document.querySelectorAll('.modal-close-button').forEach(b => b.click());
  if (app.setting?.close) app.setting.close();
  return 'cleared';
})()
'@

function Prepare-ObsidianSurface {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Main', 'StatusBar', 'Settings', 'PluginModal')]
        [string]$Name
    )

    switch ($Name) {
        { $_ -in @('Main', 'StatusBar') } {
            Invoke-ObsidianEvalSerial -Vault $Vault -Code $DismissUiCode -TimeoutSec $CliTimeoutSec | Out-Null
        }
        'Settings' {
            Invoke-ObsidianEvalSerial -Vault $Vault -Code $DismissUiCode -TimeoutSec $CliTimeoutSec | Out-Null
            $settingsCode = @"
app.commands.executeCommandById('app:open-settings');
const t = (app.setting.pluginTabs || []).find(x => x.id === '$PluginId');
if (t) { t.display(); 'ok' } else { 'no-tab' }
"@
            $r = Invoke-ObsidianEvalSerial -Vault $Vault -Code $settingsCode -TimeoutSec $CliTimeoutSec
            if ($r -ne 'ok') { Write-Warning "Settings tab for $PluginId : $r" }
        }
        'PluginModal' {
            if (-not $OpenCommandId) {
                throw 'PluginModal surface requires -OpenCommandId (e.g. my-plugin:open)'
            }
            Invoke-ObsidianEvalSerial -Vault $Vault -Code $DismissUiCode -TimeoutSec $CliTimeoutSec | Out-Null
            Invoke-ObsidianEvalSerial -Vault $Vault -Code "app.commands.executeCommandById('$OpenCommandId'); 'ok'" -TimeoutSec $CliTimeoutSec | Out-Null
        }
    }
    Start-Sleep -Seconds $UiSettleSec
}

Write-Host "=== capture-surfaces vault=$Vault plugin=$PluginId surfaces=$($Surface -join ',') ==="

Write-Host '[1/4] Ensuring Obsidian + CLI ready...'
Ensure-ObsidianVaultReady -Vault $Vault -CliTimeoutSec $CliTimeoutSec -LaunchWaitSec $LaunchWaitSec -NoLaunch:$NoLaunch

Write-Host "[2/4] Focusing vault via URI (wait ${OpenWaitSec}s)..."
Open-ObsidianVault -Vault $Vault -WaitSec $OpenWaitSec

$name = Invoke-ObsidianEvalSerial -Vault $Vault -Code 'app.vault.getName()' -TimeoutSec $CliTimeoutSec
Write-Host "      vault name: $name"

Write-Host '[3/4] Focusing Obsidian window...'
Focus-ObsidianWindow

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$captured = @()

foreach ($s in ($Surface | Select-Object -Unique)) {
    Write-Host "[4/4] Surface $s ..."
    Prepare-ObsidianSurface -Name $s
    Focus-ObsidianWindow
    $outPath = Join-Path $OutputDir $surfaceFiles[$s]
    Invoke-ObsidianScreenshotSerial -Vault $Vault -Path $outPath -TimeoutSec 30
    Write-Host "      $outPath"
    $captured += $outPath
}

Write-Host '=== capture-surfaces OK ==='
$captured
