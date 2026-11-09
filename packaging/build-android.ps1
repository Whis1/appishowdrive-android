param([switch]$SkipChecks)
$ErrorActionPreference = 'Stop'
$androidProject = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$androidTools = Join-Path $env:USERPROFILE '.cache/appishowdrive-android-tools'
$androidFlutter = Join-Path $androidTools 'flutter/bin/flutter.bat'
$env:JAVA_HOME = 'C:/Program Files/Android/openjdk/jdk-21.0.8'
$env:ANDROID_HOME = Join-Path $androidTools 'sdk'
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$androidSigningPath = Join-Path $env:USERPROFILE '.appishowdrive-android-release/signing.private.json'
if (-not (Test-Path -LiteralPath $androidSigningPath)) { throw 'Chiave privata Android assente: non crearne una nuova per aggiornare installazioni esistenti.' }
$androidSigning = Get-Content -LiteralPath $androidSigningPath -Raw | ConvertFrom-Json
$env:STORE_FILE = $androidSigning.keystore
$env:STORE_PASSWORD = $androidSigning.password
$env:KEY_ALIAS = $androidSigning.alias
$env:KEY_PASSWORD = $androidSigning.password
Push-Location $androidProject
try {
  & node packaging/prepare-embedded-speech.mjs
  if ($LASTEXITCODE -ne 0) { throw 'Modello vocale integrato non verificato.' }
  if (-not $SkipChecks) {
    & $androidFlutter analyze
    if ($LASTEXITCODE -ne 0) { throw 'Analisi non superata.' }
    & $androidFlutter test
    if ($LASTEXITCODE -ne 0) { throw 'Test app non superati.' }
    & $androidFlutter test packages/on_device_tts/test
    if ($LASTEXITCODE -ne 0) { throw 'Test del motore vocale non superati.' }
  }
  & $androidFlutter build apk --release --target lib/main.dart --target-platform android-arm,android-arm64,android-x64
  if ($LASTEXITCODE -ne 0) { throw 'Compilazione APK non riuscita.' }
  $productionApk=Join-Path $androidProject 'build/app/outputs/flutter-apk/app-release.apk'
  @{ target='lib/main.dart'; apkSha256=(Get-FileHash -LiteralPath $productionApk -Algorithm SHA256).Hash.ToLowerInvariant(); builtAtUtc=[DateTime]::UtcNow.ToString('o') } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $androidProject 'build/production-entrypoint.json') -Encoding utf8
} finally {
  Remove-Item Env:STORE_PASSWORD,Env:KEY_PASSWORD -ErrorAction SilentlyContinue
  Pop-Location
}
