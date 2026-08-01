# Sync Browser Generals to Firebase Hosting AND GitHub.
#
#   * Firebase: stages the canonical single-file game into public/index.html, generates
#     public/sw.js from the game's own sprite registries + a content hash, and deploys --
#     but only when the source is newer than what was last SUCCESSFULLY deployed.
#   * GitHub:   commits and pushes whenever the working tree has any changes.
#
# Both steps are no-ops when nothing changed, so this is safe to call on every Claude Code
# Stop hook. Pass -Force to redeploy Firebase regardless of times, -DryRun to do everything
# except `firebase deploy` and the git push (leaves the deploy gate armed).
#
# WS-D1 notes:
#   * The mtime gate is armed BEFORE the deploy and only stamped after it succeeds, so a
#     failed/aborted deploy re-fires next run instead of silently skipping forever.
#   * public/sw.js's CACHE name carries a content hash of index.html + every staged asset,
#     so returning players can never be served a stale game.
#   * UNIT_KEYS/BLD_KEYS in public/sw.js are generated from generals-zero-hour.html, so the
#     offline precache list can't drift from the game's real sprite registry.
param([switch]$Force,[switch]$DryRun)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root
$src    = Join-Path $root 'generals-zero-hour.html'
$dst    = Join-Path $root 'public\index.html'
$swTpl  = Join-Path $root 'sw.js'
$pub    = Join-Path $root 'public'
$pubAssets = Join-Path $pub 'assets'
# Sentinel mtime meaning "staged but not yet proven deployed" -- older than any real edit.
$NOT_DEPLOYED = [datetime]::new(2000,1,1,0,0,0,[System.DateTimeKind]::Utc)

if (-not (Test-Path $src)) { Write-Host 'Source game file missing; nothing to do.'; exit 0 }

# ---- helpers ----------------------------------------------------------------
# Pull the unit sprite keys straight out of the game's UNIT_SPRITE_REG literal.
function Get-UnitKeys([string]$html) {
  $i = $html.IndexOf('const UNIT_SPRITE_REG=[')
  if ($i -lt 0) { throw 'deploy: UNIT_SPRITE_REG not found in the game file (parser needs updating).' }
  $j = $html.IndexOf('];', $i)
  if ($j -lt 0) { throw 'deploy: UNIT_SPRITE_REG has no terminator.' }
  $block = $html.Substring($i, $j - $i)
  $keys = [regex]::Matches($block, "\['([A-Za-z0-9_]+)'\s*,") | ForEach-Object { $_.Groups[1].Value }
  return @($keys)
}
# ...and the building keys out of the array feeding BLD_SPRITES.
function Get-BldKeys([string]$html) {
  $i = $html.IndexOf('const BLD_SPRITES={};')
  if ($i -lt 0) { throw 'deploy: BLD_SPRITES not found in the game file (parser needs updating).' }
  $j = $html.IndexOf('.forEach(', $i)
  if ($j -lt 0) { throw 'deploy: BLD_SPRITES key array has no .forEach terminator.' }
  $block = $html.Substring($i, $j - $i)
  $keys = [regex]::Matches($block, "'([A-Za-z0-9_]+)'") | ForEach-Object { $_.Groups[1].Value }
  return @($keys)
}
# Short content hash over a set of files plus an extra salt string.
function Get-BundleHash([string[]]$files, [string]$salt) {
  $sb = New-Object System.Text.StringBuilder
  foreach ($f in ($files | Sort-Object)) {
    if (Test-Path $f) { [void]$sb.AppendLine((Split-Path $f -Leaf) + ':' + (Get-FileHash $f -Algorithm SHA256).Hash) }
  }
  [void]$sb.AppendLine($salt)
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try   { $h = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($sb.ToString())) }
  finally { $sha.Dispose() }
  return (([System.BitConverter]::ToString($h) -replace '-','').Substring(0,12).ToLower())
}
# Format a key list as a JS array literal, 8 per line.
function Format-JsKeys([string[]]$keys, [string]$name) {
  $lines = @()
  for ($i = 0; $i -lt $keys.Count; $i += 8) {
    $chunk = $keys[$i..([Math]::Min($i+7, $keys.Count-1))]
    $lines += '  ' + (($chunk | ForEach-Object { "'" + $_ + "'" }) -join ',')
  }
  return "const $name = [`r`n" + ($lines -join ",`r`n") + "`r`n];"
}
# Swap a /* @gen:tag */ ... /* @end:tag */ region for freshly generated text.
function Set-GenRegion([string]$text, [string]$tag, [string]$body) {
  $pat = "(?s)(/\* @gen:$tag \*/).*?(/\* @end:$tag \*/)"
  if (-not [regex]::IsMatch($text, $pat)) { throw "deploy: sw.js template is missing the @gen:$tag region." }
  return [regex]::Replace($text, $pat, { param($m) $m.Groups[1].Value + "`r`n" + $body + "`r`n" + $m.Groups[2].Value })
}

# ---- 1. Firebase Hosting ----------------------------------------------------
$needsDeploy = $true
if (-not $Force -and (Test-Path $dst)) {
  if ((Get-Item $src).LastWriteTimeUtc -le (Get-Item $dst).LastWriteTimeUtc) { $needsDeploy = $false }
}
if ($needsDeploy) {
  New-Item -ItemType Directory -Force -Path $pub | Out-Null
  Copy-Item $src $dst -Force
  # ARM THE GATE: the staged copy is not "deployed" until firebase says so. If the deploy
  # fails, crashes, or is Ctrl-C'd, dst stays older than src and the next run retries.
  (Get-Item $dst).LastWriteTimeUtc = $NOT_DEPLOYED

  # stage PWA shell files (manifest, launcher icons) alongside index.html -- sw.js is generated below
  foreach ($f in @('manifest.json','icon-192.png','icon-512.png','icon-512-maskable.png')) {
    $p = Join-Path $root $f
    if (Test-Path $p) { Copy-Item $p (Join-Path $pub $f) -Force } else { Write-Warning "PWA file missing, not staged: $f" }
  }
  # stage directional sprite frames for hosting (the <key>_0..7.png files, not the big source sheets)
  New-Item -ItemType Directory -Force -Path $pubAssets | Out-Null
  Get-ChildItem (Join-Path $root 'assets') -Filter '*.png' | Where-Object { $_.BaseName -match '_[0-7]$' } | ForEach-Object { Copy-Item $_.FullName $pubAssets -Force }

  # ---- generate public/sw.js from the game file + a content hash ----
  if (-not (Test-Path $swTpl)) { throw 'deploy: sw.js template missing.' }
  # Read/write as explicit UTF-8: PS 5.1's Get-Content assumes ANSI for BOM-less files and
  # would mojibake every em dash in the source, and Set-Content -Encoding utf8 adds a BOM.
  $html = [System.IO.File]::ReadAllText($src, [System.Text.Encoding]::UTF8)
  $unitKeys = Get-UnitKeys $html
  $bldKeys  = Get-BldKeys  $html
  # Fail closed: a silently-empty parse would ship a service worker that precaches nothing.
  if ($unitKeys.Count -lt 20) { throw "deploy: only $($unitKeys.Count) unit sprite keys parsed -- refusing to ship a gutted precache list." }
  if ($bldKeys.Count  -lt 10) { throw "deploy: only $($bldKeys.Count) building sprite keys parsed -- refusing to ship a gutted precache list." }
  Write-Host "sw.js precache: $($unitKeys.Count) unit keys, $($bldKeys.Count) building keys (generated from the game file)."

  $hashFiles = @($dst)
  foreach ($f in @('manifest.json','icon-192.png','icon-512.png','icon-512-maskable.png')) {
    $p = Join-Path $pub $f; if (Test-Path $p) { $hashFiles += $p }
  }
  $hashFiles += (Get-ChildItem $pubAssets -Filter '*.png' | ForEach-Object { $_.FullName })
  $salt = ($unitKeys -join ',') + '|' + ($bldKeys -join ',')
  $hash = Get-BundleHash $hashFiles $salt
  $cacheName = "browser-generals-$hash"

  $sw = [System.IO.File]::ReadAllText($swTpl, [System.Text.Encoding]::UTF8)
  $sw = Set-GenRegion $sw 'cache'     "const CACHE = '$cacheName';"
  $sw = Set-GenRegion $sw 'unit-keys' (Format-JsKeys $unitKeys 'UNIT_KEYS')
  $sw = Set-GenRegion $sw 'bld-keys'  (Format-JsKeys $bldKeys  'BLD_KEYS')
  $swOut = Join-Path $pub 'sw.js'
  [System.IO.File]::WriteAllText($swOut, $sw, (New-Object System.Text.UTF8Encoding($false)))
  Write-Host "sw.js cache name: $cacheName"

  # Validate the generated worker before it can reach a single browser.
  $node = Get-Command node -ErrorAction SilentlyContinue
  if ($node) {
    & node --check $swOut
    if ($LASTEXITCODE -ne 0) { throw 'deploy: generated public/sw.js failed `node --check` -- aborting before deploy.' }
    Write-Host 'sw.js: node --check OK.'
  } else { Write-Warning 'node not found; skipped syntax check of generated sw.js.' }

  if ($DryRun) {
    Write-Host 'DryRun: staged public/ and generated sw.js; skipping firebase deploy (gate left armed).'
  } else {
    firebase deploy --only hosting:browser-generals --project claude-5273b
    if ($LASTEXITCODE -ne 0) { Write-Error "Firebase deploy failed (exit $LASTEXITCODE); deploy gate left armed for retry."; exit $LASTEXITCODE }
    # DISARM: only a successful deploy marks the staged copy as current.
    (Get-Item $dst).LastWriteTimeUtc = (Get-Item $src).LastWriteTimeUtc
    Write-Host 'Deployed Browser Generals -> https://browser-generals.web.app'
  }
} else {
  Write-Host 'Firebase: source unchanged since last successful deploy, skipping.'
}

# ---- 2. GitHub --------------------------------------------------------------
if ($DryRun) { Write-Host 'DryRun: skipping git commit/push.'; exit 0 }
if (-not (Test-Path (Join-Path $root '.git'))) { Write-Host 'No git repo; skipping push.'; exit 0 }
# Commit any working-tree changes.
$dirty = git status --porcelain
if (-not [string]::IsNullOrWhiteSpace($dirty)) {
  git add -A
  $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
  git commit -m "Sync game and deploy ($stamp)" | Out-Null
  if ($LASTEXITCODE -ne 0) { Write-Error "git commit failed (exit $LASTEXITCODE)"; exit $LASTEXITCODE }
}
# Push whenever local is ahead of its upstream (covers commits an earlier run
# made but failed to push), not just when we committed this run.
$ahead = git rev-list --count '@{u}..HEAD' 2>$null
if ($ahead -and [int]$ahead -gt 0) {
  git push origin HEAD
  if ($LASTEXITCODE -ne 0) { Write-Error "git push failed (exit $LASTEXITCODE)"; exit $LASTEXITCODE }
  Write-Host "Pushed $ahead commit(s) to https://github.com/sunsetsarge/browser-generals"
} else {
  Write-Host 'GitHub: up to date, nothing to push.'
}
