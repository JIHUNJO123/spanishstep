$apps = @(
    "jlpt-vocab-n1",
    "jlpt-vocab-n2",
    "onomastep",
    "jlpt-step-apps",
    "daily-jp-step",
    "kanji-dict-flutter",
    "sat-vocab-app",
    "english-vocab-app",
    "english-proverb-app",
    "toefl-prep-vocabulary",
    "toeic-prep-vocabulary",
    "gre-vocab-app",
    "ielts-prep-vocabulary",
    "english-idiom-app",
    "hskmaster"
)

$baseDir = "c:\Users\user\Desktop\spanishstep"
$results = @()

foreach ($app in $apps) {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Building $app..." -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    
    Set-Location "$baseDir\$app"
    
    # Run flutter build
    $buildOutput = flutter build appbundle --release 2>&1
    
    # Check if AAB was created
    $aabPath = "$baseDir\$app\build\app\outputs\bundle\release\app-release.aab"
    if (Test-Path $aabPath) {
        $size = [math]::Round((Get-Item $aabPath).Length / 1MB, 2)
        Write-Host "$app : SUCCESS ($size MB)" -ForegroundColor Green
        $results += "$app : SUCCESS ($size MB)"
    } else {
        Write-Host "$app : FAILED" -ForegroundColor Red
        $results += "$app : FAILED"
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "BUILD SUMMARY" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
$results | ForEach-Object { Write-Host $_ }
