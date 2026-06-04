param(
    [string]$ServiceAccountPath = "",
    [string]$ProjectRef = "jqyjvhwlcqcsuwcqgcwf",
    [string]$DispatchSecretPath = ""
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
if ([string]::IsNullOrWhiteSpace($ServiceAccountPath)) {
    $candidates = Get-ChildItem $repoRoot -Filter "petfolio-v1-firebase-adminsdk*.json" -File | Select-Object -First 1
    if ($null -eq $candidates) {
        throw "No petfolio-v1-firebase-adminsdk*.json in repo root. Pass -ServiceAccountPath."
    }
    $ServiceAccountPath = $candidates.FullName
}

if (-not (Test-Path $ServiceAccountPath)) {
    throw "Service account file not found: $ServiceAccountPath"
}

$parsed = Get-Content $ServiceAccountPath -Raw | ConvertFrom-Json
$minified = $parsed | ConvertTo-Json -Compress -Depth 20
$null = $minified | ConvertFrom-Json

$envFile = Join-Path $repoRoot "supabase\.secrets.fcm.env"
$lines = @("FIREBASE_SERVICE_ACCOUNT_JSON=$minified")

if ($DispatchSecretPath -and (Test-Path $DispatchSecretPath)) {
    Get-Content $DispatchSecretPath | ForEach-Object { $lines += $_ }
} elseif (Test-Path (Join-Path $repoRoot ".env")) {
    $dispatch = Get-Content (Join-Path $repoRoot ".env") |
        Where-Object { $_ -match '^FCM_DISPATCH_SECRET=' }
    if ($dispatch) { $lines += $dispatch }
}

$lines | Set-Content $envFile -Encoding utf8

Push-Location $repoRoot
try {
    npx supabase secrets set --env-file "supabase/.secrets.fcm.env" --project-ref $ProjectRef
    $dispatchLine = $lines | Where-Object { $_ -match '^FCM_DISPATCH_SECRET=' } | Select-Object -First 1
    if ($dispatchLine) {
        $secret = ($dispatchLine -replace '^FCM_DISPATCH_SECRET=', '').Trim()
        $escaped = $secret.Replace("'", "''")
        $sql = "UPDATE private.fcm_internal_config SET dispatch_secret = '$escaped' WHERE id = 1;"
        npx supabase db query --linked $sql 2>&1 | Out-Host
    }
    Write-Host "Supabase FCM secrets and dispatch_secret synced."
}
finally {
    Pop-Location
}
