# Sync Browser Generals to Firebase Hosting AND GitHub.
#
#   * Firebase: copies the canonical single-file game into public/index.html and
#     deploys -- but only when the source is newer than what was last deployed.
#   * GitHub:   commits and pushes whenever the working tree has any changes.
#
# Both steps are no-ops when nothing changed, so this is safe to call on every
# Claude Code Stop hook. Pass -Force to redeploy Firebase regardless of times.
param([switch]$Force)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root
$src = Join-Path $root 'generals-zero-hour.html'
$dst = Join-Path $root 'public\index.html'

if (-not (Test-Path $src)) { Write-Host 'Source game file missing; nothing to do.'; exit 0 }

# ---- 1. Firebase Hosting ----------------------------------------------------
$needsDeploy = $true
if (-not $Force -and (Test-Path $dst)) {
  if ((Get-Item $src).LastWriteTimeUtc -le (Get-Item $dst).LastWriteTimeUtc) { $needsDeploy = $false }
}
if ($needsDeploy) {
  New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null
  Copy-Item $src $dst -Force
  firebase deploy --only hosting:browser-generals --project claude-5273b
  if ($LASTEXITCODE -ne 0) { Write-Error "Firebase deploy failed (exit $LASTEXITCODE)"; exit $LASTEXITCODE }
  Write-Host 'Deployed Browser Generals -> https://browser-generals.web.app'
} else {
  Write-Host 'Firebase: source unchanged, skipping deploy.'
}

# ---- 2. GitHub --------------------------------------------------------------
if (-not (Test-Path (Join-Path $root '.git'))) { Write-Host 'No git repo; skipping push.'; exit 0 }
$dirty = git status --porcelain
if ([string]::IsNullOrWhiteSpace($dirty)) { Write-Host 'GitHub: working tree clean, nothing to push.'; exit 0 }
git add -A
$stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
git commit -m "Sync game and deploy ($stamp)" | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Error "git commit failed (exit $LASTEXITCODE)"; exit $LASTEXITCODE }
git push origin HEAD
if ($LASTEXITCODE -ne 0) { Write-Error "git push failed (exit $LASTEXITCODE)"; exit $LASTEXITCODE }
Write-Host 'Pushed to https://github.com/sunsetsarge/browser-generals'
