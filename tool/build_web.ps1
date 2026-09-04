<#
.SYNOPSIS
  웹(PWA) 빌드/실행. Maps API 키를 android/local.properties에서 읽어 --dart-define으로 넘긴다 (NFR-02).
.EXAMPLE
  .\tool\build_web.ps1                      # flutter build web --release (base-href /)
  .\tool\build_web.ps1 -BaseHref /repo/     # GitHub Pages 하위 경로
  .\tool\build_web.ps1 -Run                 # flutter run -d chrome
#>
param(
    [switch]$Run,
    [string]$BaseHref = '/'
)

$root = Split-Path -Parent $PSScriptRoot
$propsPath = Join-Path $root 'android\local.properties'
if (-not (Test-Path $propsPath)) {
    Write-Error "$propsPath 가 없습니다. MAPS_API_KEY=... 를 넣어 주세요."
    exit 1
}
$key = (Get-Content $propsPath | Where-Object { $_ -match '^MAPS_API_KEY=' }) -replace '^MAPS_API_KEY=', ''
if (-not $key) {
    Write-Error "android/local.properties에 MAPS_API_KEY가 없습니다."
    exit 1
}

Set-Location $root
if ($Run) {
    flutter run -d chrome --dart-define=MAPS_API_KEY=$key
} else {
    flutter build web --release --base-href $BaseHref --dart-define=MAPS_API_KEY=$key
}
exit $LASTEXITCODE
