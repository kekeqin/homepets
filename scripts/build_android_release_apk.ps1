$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir '..')
$appDir = Join-Path $repoRoot 'app'

$apiBaseUrl = $env:API_BASE_URL
if ([string]::IsNullOrWhiteSpace($apiBaseUrl)) {
    $apiBaseUrl = 'https://pickstarpet.kkqin.com'
}

if (
    $apiBaseUrl -match '^http://(10\.0\.2\.2|127\.0\.0\.1|localhost)(:|/|$)' -or
    $apiBaseUrl -match '^http://192\.168\.' -or
    $apiBaseUrl -like '*homepets.example.com*'
) {
    throw "API_BASE_URL must not point to a local development server: $apiBaseUrl"
}

$revenueCatAndroidApiKey = $env:REVENUECAT_ANDROID_API_KEY
$revenueCatEntitlementId = $env:REVENUECAT_ENTITLEMENT_ID
if ([string]::IsNullOrWhiteSpace($revenueCatEntitlementId)) {
    $revenueCatEntitlementId = 'premium'
}
$revenueCatUseTestStore = $env:REVENUECAT_USE_TEST_STORE
if ([string]::IsNullOrWhiteSpace($revenueCatUseTestStore)) {
    $revenueCatUseTestStore = 'false'
}

Push-Location $appDir
try {
    & flutter build apk --release `
        "--dart-define=API_BASE_URL=$apiBaseUrl" `
        "--dart-define=REVENUECAT_ANDROID_API_KEY=$revenueCatAndroidApiKey" `
        "--dart-define=REVENUECAT_ENTITLEMENT_ID=$revenueCatEntitlementId" `
        "--dart-define=REVENUECAT_USE_TEST_STORE=$revenueCatUseTestStore" `
        @args

    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}
finally {
    Pop-Location
}
