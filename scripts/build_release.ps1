<#
.SYNOPSIS
  Canonical obfuscated release build for Hidden Gems SL.

.DESCRIPTION
  Builds a release artifact with obfuscation, split debug symbols, and
  production values loaded from the gitignored dart_define_prod.json file.

.PARAMETER Target
  apk | appbundle | ipa (default: appbundle)
#>
param(
  [ValidateSet('apk', 'appbundle', 'ipa')]
  [string]$Target = 'appbundle'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$env:DEBUG = ''
$env:GRADLE_USER_HOME = Join-Path $env:TEMP 'hidden-gems-gradle-cache'

$definesFile = Join-Path $repoRoot 'dart_define_prod.json'
if (-not (Test-Path $definesFile)) {
  Write-Error 'Missing dart_define_prod.json. Copy dart_define_prod.json.example and fill in the production values.'
}

$requiredDefines = @(
  'HIDDEN_GEMS_API_KEY',
  'HMAC_SECRET',
  'VAULT_SIGN_KEY',
  'SHARED_AES_KEY',
  'SHARED_HMAC_KEY',
  'HMAC_EXPIRY_SECRET',
  'REVENUECAT_API_KEY_ANDROID',
  'WEATHER_API_KEY',
  'ADMOB_BANNER_ID',
  'ADMOB_INTERSTITIAL_ID',
  'ADMOB_REWARDED_ID',
  'ADMOB_NATIVE_ID'
)
if ($Target -eq 'ipa') {
  $requiredDefines += @(
    'REVENUECAT_API_KEY_IOS',
    'APP_STORE_ID'
  )
}
$defines = Get-Content $definesFile -Raw | ConvertFrom-Json
$invalidDefines = foreach ($key in $requiredDefines) {
  $value = [string]$defines.$key
  if (
    [string]::IsNullOrWhiteSpace($value) -or
    $value -eq '0000000000' -or
    $value -match '(?i)test|not[_ -]?functional|replace|change|your_|example|localhost'
  ) {
    $key
  }
}
if ($invalidDefines.Count -gt 0) {
  Write-Error "Production configuration is missing or contains placeholders: $($invalidDefines -join ', ')"
}

$symbolsDir = Join-Path $repoRoot "symbols/$Target"
New-Item -ItemType Directory -Force -Path $symbolsDir | Out-Null

Write-Host "Building RELEASE ($Target), obfuscated, symbols -> symbols/$Target" -ForegroundColor Cyan

flutter build $Target `
  --release `
  --obfuscate `
  --split-debug-info=$symbolsDir `
  --dart-define-from-file=$definesFile

if ($LASTEXITCODE -ne 0) {
  Write-Error "flutter build failed (exit $LASTEXITCODE)."
}

Write-Host "Done. Archive the symbols in symbols/$Target for Crashlytics." -ForegroundColor Green
