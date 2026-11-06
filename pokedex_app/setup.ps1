# Instalador automatico: Flutter SDK + projeto Pokedex
$ErrorActionPreference = "Stop"
$projeto = $PSScriptRoot
Set-Location $projeto

Write-Host "== 1/5 Verificando Git ==" -ForegroundColor Cyan
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Git nao encontrado. Instale em https://git-scm.com/download/win e rode de novo." -ForegroundColor Red
    exit 1
}

Write-Host "== 2/5 Instalando Flutter SDK em C:\src\flutter ==" -ForegroundColor Cyan
if (-not (Test-Path "C:\src\flutter\bin\flutter.bat")) {
    New-Item -ItemType Directory -Force "C:\src" | Out-Null
    git clone https://github.com/flutter/flutter.git -b stable "C:\src\flutter"
} else {
    Write-Host "Flutter ja existe em C:\src\flutter, pulando."
}

Write-Host "== 3/5 Configurando PATH ==" -ForegroundColor Cyan
$flutterBin = "C:\src\flutter\bin"
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$flutterBin*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$flutterBin", "User")
}
$env:Path += ";$flutterBin"

Write-Host "== 4/5 Gerando pastas do Android/Web ==" -ForegroundColor Cyan
Copy-Item "lib\main.dart" "$env:TEMP\pokedex_main.dart.bak" -Force
Copy-Item "pubspec.yaml" "$env:TEMP\pokedex_pubspec.yaml.bak" -Force
flutter create . --project-name pokedex_app --platforms=android,web
Copy-Item "$env:TEMP\pokedex_main.dart.bak" "lib\main.dart" -Force
Copy-Item "$env:TEMP\pokedex_pubspec.yaml.bak" "pubspec.yaml" -Force
if (Test-Path "test") { Remove-Item "test" -Recurse -Force }

Write-Host "== 5/5 Baixando dependencias ==" -ForegroundColor Cyan
flutter pub get

Write-Host ""
Write-Host "Pronto! Veja o diagnostico abaixo:" -ForegroundColor Green
flutter doctor
Write-Host ""
Write-Host "Agora abra esta pasta no VS Code (File > Open Folder) e aperte F5." -ForegroundColor Green
Read-Host "Pressione Enter para fechar"
