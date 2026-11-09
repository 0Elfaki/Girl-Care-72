# Builds everything for Hostinger into .\dist and .\GirlCare72-hostinger.zip
#
#   dist\
#   ├── index.html                 website
#   ├── .htaccess                  server settings (from hosting\.htaccess)
#   ├── assets\
#   │   ├── css\  js\  img\        website styles, scripts, favicon, QR code
#   │   └── data\                  default text + release.json (version shown on Download)
#   ├── downloads\
#   │   └── GirlCare72.apk         Android app (also at /GirlCare72.apk for the QR code)
#   └── app\
#       ├── index.html             the app in a browser, at /app/
#       └── static\                its scripts, fonts, lessons
#
# Run from the project folder:
#   powershell -ExecutionPolicy Bypass -File .\build_hostinger.ps1 -Notes "What changed"
# Raise "version:" in pubspec.yaml first so phones see the APK as an update.
# -SkipBuild reuses the last Flutter builds (faster when only the website changed).

param(
  [string]$ApiBase = 'https://girlcare72.com',
  [string]$FreeNumber = '0788907052',
  [string]$Notes = 'Call now button on Get help, new free number 0788907052.',
  [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$utf8 = New-Object Text.UTF8Encoding $false
$defines = @("--dart-define=API_BASE=$ApiBase", "--dart-define=FREE_NUMBER=$FreeNumber")
$version = (Select-String pubspec.yaml -Pattern '^version:\s*([0-9.]+)').Matches[0].Groups[1].Value
$apkOut = 'build\app\outputs\flutter-apk'

if (-not $SkipBuild) {
  flutter build apk --release --split-per-abi @defines; if ($LASTEXITCODE) { throw 'APK build failed' }
  New-Item -ItemType Directory apk -Force | Out-Null
  Copy-Item "$apkOut\app-arm64-v8a-release.apk" "apk\GirlCare72-$version-arm64-v8a.apk" -Force
  Copy-Item "$apkOut\app-armeabi-v7a-release.apk" "apk\GirlCare72-$version-armeabi-v7a.apk" -Force
  flutter build apk --release @defines; if ($LASTEXITCODE) { throw 'APK build failed' }
  Copy-Item "$apkOut\app-release.apk" "apk\GirlCare72-$version-all-phones.apk" -Force
  flutter build web --release --base-href /app/static/ @defines; if ($LASTEXITCODE) { throw 'Web build failed' }
}

# ---- Website at /
if (Test-Path dist) { Remove-Item dist -Recurse -Force }
Copy-Item website dist -Recurse
Copy-Item hosting\.htaccess dist\.htaccess
Copy-Item qr\girlcare72-download-qr.png dist\assets\img\qr-download.png   # points to /GirlCare72.apk

# ---- Android app at /downloads/
New-Item -ItemType Directory dist\downloads | Out-Null
Copy-Item "$apkOut\app-release.apk" dist\downloads\GirlCare72.apk
$apk = Get-Item dist\downloads\GirlCare72.apk
$release = [ordered]@{
  version = $version
  url     = 'downloads/GirlCare72.apk'
  size    = $apk.Length
  updated = (Get-Date -Format 'd MMMM yyyy')
  notes   = $Notes
  sha256  = (Get-FileHash $apk.FullName -Algorithm SHA256).Hash.ToLower()
  qr      = 'assets/img/qr-download.png'
}
[IO.File]::WriteAllText("$PWD\dist\assets\data\release.json", ($release | ConvertTo-Json), $utf8)

# ---- Browser app at /app/
New-Item -ItemType Directory dist\app\static | Out-Null
Get-ChildItem build\web -Force | Where-Object { $_.Name -notin 'index.html', '.last_build_id' } |
  ForEach-Object { Copy-Item $_.FullName dist\app\static -Recurse }
Copy-Item build\web\index.html dist\app\index.html
$manifest = "$PWD\dist\app\static\manifest.json"
$m = [IO.File]::ReadAllText($manifest) -replace '"start_url":\s*"[^"]*"', '"start_url": "/app/",
    "scope": "/app/"'
[IO.File]::WriteAllText($manifest, $m, $utf8)

# ---- Zip with "/" paths (Hostinger runs Linux)
$zip = Join-Path $PSScriptRoot 'GirlCare72-hostinger.zip'
if (Test-Path $zip) { Remove-Item $zip }
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
$root = (Resolve-Path dist).Path.TrimEnd('\') + '\'
$archive = [IO.Compression.ZipFile]::Open($zip, 'Create')
try {
  Get-ChildItem dist -Recurse -Force -File | ForEach-Object {
    $name = $_.FullName.Substring($root.Length).Replace('\', '/')
    [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $_.FullName, $name, 'Optimal')
  }
} finally { $archive.Dispose() }

Write-Host "Done: GirlCare72 $version -> dist\ and GirlCare72-hostinger.zip ($([math]::Round((Get-Item $zip).Length / 1MB, 1)) MB)"
