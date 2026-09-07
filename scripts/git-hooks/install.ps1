# Install post-push hook into this clone's .git/hooks (git does not track hooks).
# Writes LF endings so Git Bash can execute the shebang on Windows.
$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$src = Join-Path $PSScriptRoot 'post-push'
$destDir = Join-Path $repoRoot '.git\hooks'
$dest = Join-Path $destDir 'post-push'

if (-not (Test-Path $src)) { throw "Missing $src" }
if (-not (Test-Path $destDir)) { throw "Not a git repo: $destDir" }

$text = [System.IO.File]::ReadAllText($src) -replace "`r`n", "`n" -replace "`r", "`n"
[System.IO.File]::WriteAllText($dest, $text)
Write-Host "Installed (LF): $dest"
