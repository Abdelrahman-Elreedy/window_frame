# Runs every AUTOMATIC check before publishing to pub.dev and prints one summary.
#
# It only runs local commands. It does NOT publish anything, does NOT touch git or
# GitHub, and needs no login. (`dart pub publish --dry-run` only validates.)
#
# From the package root (the folder with pubspec.yaml):
#   powershell -ExecutionPolicy Bypass -File tool/prepublish.ps1
#
# Before running: CLOSE the example app (and stop `flutter run`), or the last step
# cannot overwrite the running .exe.
#
# It cannot replace you for the manual part: run the example on Windows and go
# through the table of behaviors in README.md ("Everything the title bar and its
# menus do").
#
# Optional: -WithPana also runs `pana` (the pub.dev score). pana does not work on
# Windows (it fails on the ":" in "C:\..."), so run it on Linux/WSL or let pub.dev
# score the package after publishing.

param([switch]$WithPana)

$results = @()

function Invoke-Step {
  param([string]$Name, [scriptblock]$Command)
  Write-Host ""
  Write-Host "=== $Name ===" -ForegroundColor Cyan
  & $Command
  $passed = ($LASTEXITCODE -eq 0)
  $script:results += [pscustomobject]@{ Step = $Name; Passed = $passed }
}

Invoke-Step 'flutter pub get'                 { flutter pub get }
# --output=none only CHECKS. To fix the files run:  dart format .
Invoke-Step 'dart format (nothing to change)' { dart format --output=none --set-exit-if-changed . }
Invoke-Step 'flutter analyze (no issues)'     { flutter analyze }
if (Test-Path 'test/*_test.dart') {
  Invoke-Step 'flutter test'                  { flutter test }
} else {
  Write-Host ""
  Write-Host "(no test/*_test.dart files: tests skipped)" -ForegroundColor Yellow
}
Invoke-Step 'dart doc'                        { dart doc }
Invoke-Step 'dart pub publish --dry-run'      { dart pub publish --dry-run }
if ($WithPana) {
  Invoke-Step 'pana (the pub.dev score)'      { dart pub global activate pana; dart pub global run pana --no-warning . }
}
if (Test-Path 'example') {
  Invoke-Step 'example builds for Windows'    {
    Push-Location example
    try { flutter build windows --debug } finally { Pop-Location }
  }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize

if ($results.Passed -contains $false) {
  Write-Host "Some steps failed: do not publish yet." -ForegroundColor Red
  exit 1
}
Write-Host "All automatic steps passed. Now do the manual test on Windows." -ForegroundColor Green
