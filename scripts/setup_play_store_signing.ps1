# Creates the upload keystore and android/key.properties for Play Store release signing.
# Run once from project root:  .\scripts\setup_play_store_signing.ps1
# Back up the generated keystore and keystore-passwords.txt; never commit them.

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not (Test-Path (Join-Path $ProjectRoot "android"))) { $ProjectRoot = (Get-Location).Path }
$AndroidDir = Join-Path $ProjectRoot "android"
$KeyStorePath = Join-Path $AndroidDir "upload-keystore.jks"
$KeyPropsPath = Join-Path $AndroidDir "key.properties"
$PasswordsPath = Join-Path $AndroidDir "keystore-passwords.txt"

if (Test-Path $KeyPropsPath) {
    Write-Host "key.properties already exists. Delete it first if you want to regenerate."
    exit 0
}

# Random password (alphanumeric, 24 chars)
Add-Type -AssemblyName 'System.Web'
$Password = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 24 | ForEach-Object { [char]$_ })

# Create keystore with keytool (non-interactive)
$DName = "CN=ARADI, OU=Mobile, O=ARADI, L=Dubai, ST=Dubai, C=AE"
& keytool -genkey -v -keystore $KeyStorePath -keyalg RSA -keysize 2048 -validity 10000 `
  -alias upload -storepass $Password -keypass $Password -dname $DName
if ($LASTEXITCODE -ne 0) { throw "keytool failed" }

# key.properties: storeFile is relative to android/app (app module), so ../upload-keystore.jks = android/upload-keystore.jks
$StoreFileRelative = "../upload-keystore.jks"
$Content = @"
storePassword=$Password
keyPassword=$Password
keyAlias=upload
storeFile=$StoreFileRelative
"@
Set-Content -Path $KeyPropsPath -Value $Content.TrimEnd() -NoNewline

# Save password for backup (file is in .gitignore)
Set-Content -Path $PasswordsPath -Value @"
Upload keystore password (store and key use the same):
$Password

Keystore: $KeyStorePath
Back up this file and the .jks file; delete from this machine after copying to a safe place.
"@

Write-Host "Done. Created:"
Write-Host "  - $KeyStorePath"
Write-Host "  - $KeyPropsPath"
Write-Host "  - $PasswordsPath (back up this and the .jks, then remove from repo)"
Write-Host "Run: flutter build appbundle"
Write-Host ""
