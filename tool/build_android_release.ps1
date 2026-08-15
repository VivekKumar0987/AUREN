$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$flutter = "flutter"
$flutterBat = "C:\src\flutter\bin\flutter.bat"

if (Test-Path $flutterBat) {
  $flutter = $flutterBat
}

Set-Location $root

& $flutter build apk --release

$source = Join-Path $root "build\app\outputs\flutter-apk\app-release.apk"
$dist = Join-Path $root "dist"
$target = Join-Path $dist "AUREN.apk"

if (-not (Test-Path $source)) {
  throw "Release APK not found at $source"
}

New-Item -ItemType Directory -Force -Path $dist | Out-Null
Copy-Item -Path $source -Destination $target -Force

Write-Host "AUREN APK ready:"
Write-Host $target
