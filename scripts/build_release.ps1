<#
.SYNOPSIS
  Canonical RELEASE build for Hidden Gems SL — always obfuscated.

.DESCRIPTION
  This is the ONLY supported way to produce a release artifact. It always
  passes --obfuscate --split-debug-info so a release build can never ship
  un-obfuscated by accident (the failure mode HARDENING.md warned about), and
  loads all --dart-define secrets from dart_defines.json (gitignored) so they
  aren't hardcoded in source.

  Symbols are written to symbols/<target>/ — KEEP THEM. You need them to
  de-obfuscate Crashlytics stack traces.

.PARAMETER Target
  apk | appbundle | ipa   (default: appbundle — the Play Store format)

.EXAMPLE
  ./scripts/build_release.ps1
  ./scripts/build_release.ps1 -Target apk
#>
param(
  [ValidateSet('apk', 'appbundle', 'ipa')]
  [string]$Target = 'appbundle'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$definesFile = Join-Path $repoRoot 'dart_defines.json'
if (-not (Test-Path $definesFile)) {
  Write-Error "Missing dart_defines.json. Copy dart_defines.example.json to dart_defines.json and fill it in."
}

$symbolsDir = Join-Path $repoRoot "symbols/$Target"
New-Item -ItemType Directory -Force -Path $symbolsDir | Out-Null

Write-Host "Building RELEASE ($Target), obfuscated, symbols -> symbols/$Target" -ForegroundColor Cyan

flutter build $Target `
  --release `
  --obfuscate `
  --split-debug-info="symbols/$Target" `
  --dart-define-from-file=dart_defines.json

if ($LASTEXITCODE -ne 0) { Write-Error "flutter build failed (exit $LASTEXITCODE)." }

Write-Host "Done. Obfuscation symbols saved in symbols/$Target — archive them for Crashlytics." -ForegroundColor Green
