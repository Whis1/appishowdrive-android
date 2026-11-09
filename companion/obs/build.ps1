param(
 [Parameter(Mandatory=$true)][string]$ObsSdk,
 [Parameter(Mandatory=$true)][string]$Rnnoise,
 [string]$ObsDirectory='C:/Program Files/obs-studio',
 [string]$Clang=''
)
$ErrorActionPreference='Stop'
$sdkRoot=[IO.Path]::GetFullPath($ObsSdk)
$rnnRoot=[IO.Path]::GetFullPath($Rnnoise)
if(!$Clang) {
 $command=Get-Command clang-cl -ErrorAction SilentlyContinue
 if($command) { $Clang=$command.Source }
 else { $Clang=Join-Path $env:USERPROFILE '.cache/appishowdrive-android-tools/sdk/ndk/28.2.13676358/toolchains/llvm/prebuilt/windows-x86_64/bin/clang-cl.exe' }
}
$obsBin=Join-Path $ObsDirectory 'bin/64bit'
$target=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../build/obs'))
New-Item -ItemType Directory -Path (Join-Path $target 'rnn') -Force | Out-Null
$vswhere=Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
$vs=& $vswhere -latest -property installationPath
$msvc=Get-ChildItem -LiteralPath (Join-Path $vs 'VC/Tools/MSVC') -Directory | Sort-Object Name | Select-Object -Last 1
$tools=Join-Path $msvc.FullName 'bin/Hostx64/x64'
$win=Join-Path ${env:ProgramFiles(x86)} 'Windows Kits/10'
$version=(Get-ChildItem -LiteralPath (Join-Path $win 'Include') -Directory | Sort-Object Name | Select-Object -Last 1).Name
$env:INCLUDE=@((Join-Path $msvc.FullName 'include'),(Join-Path $win "Include/$version/ucrt"),(Join-Path $win "Include/$version/um"),(Join-Path $win "Include/$version/shared")) -join ';'
$env:LIB=@((Join-Path $msvc.FullName 'lib/x64'),(Join-Path $win "Lib/$version/ucrt/x64"),(Join-Path $win "Lib/$version/um/x64")) -join ';'
$exports=& (Join-Path $tools 'dumpbin.exe') /nologo /exports (Join-Path $obsBin 'obs.dll')
$names=foreach($line in $exports) { if($line -match '^\s+\d+\s+[0-9A-F]+\s+[0-9A-F]+\s+([A-Za-z_][A-Za-z_0-9]*)(?:\s+=.*)?\s*$') { $matches[1] } }
if($names.Count -lt 1000) { throw 'Esportazioni OBS non valide.' }
@('LIBRARY obs.dll','EXPORTS')+$names | Set-Content -LiteralPath (Join-Path $target 'obs.def') -Encoding ascii
& (Join-Path $tools 'lib.exe') /nologo "/def:$target/obs.def" /machine:x64 "/out:$target/obs.lib"
if($LASTEXITCODE -ne 0) { throw 'Import library OBS non creata.' }
$cSources=@('denoise.c','rnn.c','rnn_data.c','pitch.c','kiss_fft.c','celt_lpc.c') | ForEach-Object { Join-Path $rnnRoot "src/$_" }
& $Clang --target=x86_64-pc-windows-msvc /nologo /c /O2 /MD /DWIN32 /DRNNOISE_BUILD /D_CRT_SECURE_NO_WARNINGS /D_USE_MATH_DEFINES "/I$rnnRoot/include" "/I$rnnRoot/src" "/Fo$target/rnn/" $cSources
if($LASTEXITCODE -ne 0) { throw 'RNNoise non compilato.' }
$objects=Get-ChildItem -LiteralPath (Join-Path $target 'rnn') -Filter '*.obj' | Select-Object -ExpandProperty FullName
& (Join-Path $tools 'cl.exe') /nologo /utf-8 /std:c++17 /EHsc /LD /O2 /MD /DWIN32 /D_CRT_SECURE_NO_WARNINGS "/I$sdkRoot/libobs" "/I$rnnRoot/include" "/Fo$target/" (Join-Path $PSScriptRoot 'appishowdrive_voice.cpp') $objects /link (Join-Path $target 'obs.lib') "/IMPLIB:$target/appishowdrive-voice.lib" "/OUT:$target/appishowdrive-voice.dll"
if($LASTEXITCODE -ne 0) { throw 'Plugin OBS non compilato.' }
Write-Output "Plugin: $target/appishowdrive-voice.dll"
& (Join-Path $tools 'cl.exe') /nologo /std:c++17 /EHsc /O2 /MD /DWIN32 /D_CRT_SECURE_NO_WARNINGS "/I$sdkRoot/libobs" "/I$rnnRoot/include" "/Fo$target/" (Join-Path $PSScriptRoot 'verify.cpp') $objects /link (Join-Path $target 'obs.lib') "/OUT:$target/verify-voice.exe"
if($LASTEXITCODE -ne 0) { throw 'Verifica OBS non compilata.' }
$bundle=Join-Path $target 'package'
New-Item -ItemType Directory -Path (Join-Path $bundle 'source') -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $target 'appishowdrive-voice.dll') -Destination $bundle
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'LEGGIMI.txt') -Destination $bundle
Copy-Item -LiteralPath (Join-Path $rnnRoot 'COPYING') -Destination (Join-Path $bundle 'COPYING-RNNOISE.txt')
Copy-Item -LiteralPath (Join-Path $sdkRoot 'COPYING') -Destination (Join-Path $bundle 'COPYING-GPL-2.0.txt')
foreach($name in @('voice_processor.hpp','appishowdrive_voice.cpp','verify.cpp','build.ps1','install.cs','install.manifest')) {
 Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination (Join-Path $bundle 'source')
}
$pluginHash=(Get-FileHash -LiteralPath (Join-Path $bundle 'appishowdrive-voice.dll') -Algorithm SHA256).Hash.ToLowerInvariant()
$installer=(Get-Content -LiteralPath (Join-Path $PSScriptRoot 'install.cs') -Raw).Replace('__PLUGIN_SHA__',$pluginHash)
[IO.File]::WriteAllText((Join-Path $target 'install-generated.cs'),$installer,[Text.UTF8Encoding]::new($true))
$csc=Join-Path $env:WINDIR 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
& $csc /nologo /target:winexe /reference:System.Windows.Forms.dll "/win32manifest:$PSScriptRoot/install.manifest" "/out:$bundle/Installazione-Voce-OBS.exe" (Join-Path $target 'install-generated.cs')
if($LASTEXITCODE -ne 0) { throw 'Installazione OBS non compilata.' }
Compress-Archive -LiteralPath (Get-ChildItem -LiteralPath $bundle | Select-Object -ExpandProperty FullName) -DestinationPath (Join-Path $target 'APPISHOWDRIVE-Voce-OBS.zip') -Force
Write-Output "Componente distribuibile: $target/APPISHOWDRIVE-Voce-OBS.zip"
