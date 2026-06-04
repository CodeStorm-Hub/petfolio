param(
  [string]$Project = "petfolio-v1"
)

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

Write-Host "Using Firebase project: $Project"
firebase use $Project

Write-Host "Regenerating lib/firebase_options.dart (FlutterFire)..."
flutterfire configure --project=$Project --yes --platforms=android,web --out=lib/firebase_options.dart

$androidOut = "android/app/google-services.json"
if (Test-Path $androidOut) { Remove-Item $androidOut -Force }
firebase apps:sdkconfig ANDROID --project $Project -o $androidOut
Write-Host "Wrote $androidOut"

$webJson = firebase apps:sdkconfig WEB --project $Project | Out-String
$web = $webJson | ConvertFrom-Json
$js = @"
self.FIREBASE_WEB_CONFIG = {
  apiKey: '$($web.apiKey)',
  authDomain: '$($web.authDomain)',
  projectId: '$($web.projectId)',
  storageBucket: '$($web.storageBucket)',
  messagingSenderId: '$($web.messagingSenderId)',
  appId: '$($web.appId)',
};
"@
Set-Content -Path "web/firebase-config.js" -Value $js -NoNewline
Write-Host "Wrote web/firebase-config.js"
Write-Host "Done. Set FIREBASE_VAPID_KEY in .env (Console -> Cloud Messaging -> Web Push key pair)."
