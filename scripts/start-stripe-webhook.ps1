[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$envPath = Join-Path $root '.env'
$stripePath = Join-Path $root '.tools\stripe\stripe.exe'
$runtimeDirectory = Join-Path $root '.stripe-listener'
$pidPath = Join-Path $runtimeDirectory 'pid'
$stdoutPath = Join-Path $runtimeDirectory 'stdout.log'
$stderrPath = Join-Path $runtimeDirectory 'stderr.log'

if (-not (Test-Path -LiteralPath $envPath)) {
    throw 'Nedostaje .env datoteka u root folderu projekta.'
}

if (-not (Test-Path -LiteralPath $stripePath)) {
    throw 'Stripe CLI nije pronadjen u .tools\stripe. Prvo instalirajte Stripe CLI prema docs/local-development.md.'
}

$envLines = [System.Collections.Generic.List[string]](Get-Content -LiteralPath $envPath)
$secretEntry = $envLines | Where-Object { $_ -like 'STRIPE_SECRET_KEY=*' } | Select-Object -First 1
$secretKey = if ($secretEntry) { $secretEntry.Substring('STRIPE_SECRET_KEY='.Length).Trim() } else { '' }
$apiPortEntry = $envLines | Where-Object { $_ -like 'API_PORT=*' } | Select-Object -First 1
$apiPort = if ($apiPortEntry) { $apiPortEntry.Substring('API_PORT='.Length).Trim() } else { '' }
if ($secretKey -notlike 'sk_test_*') {
    throw 'STRIPE_SECRET_KEY mora sadrzavati standardni Stripe testni kljuc.'
}
if ($apiPort -notmatch '^\d+$') {
    throw 'API_PORT mora sadrzavati validan port.'
}
$apiBaseUrl = "http://localhost:$apiPort"

if (Test-Path -LiteralPath $pidPath) {
    $previousPid = Get-Content -LiteralPath $pidPath -ErrorAction SilentlyContinue
    if ($previousPid -match '^\d+$') {
        Stop-Process -Id ([int]$previousPid) -Force -ErrorAction SilentlyContinue
    }
}

New-Item -ItemType Directory -Force -Path $runtimeDirectory | Out-Null
Remove-Item -LiteralPath $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue

$env:STRIPE_API_KEY = $secretKey
try {
    $listener = Start-Process -FilePath $stripePath `
        -ArgumentList @(
            'listen',
            '--events',
            'payment_intent.succeeded,payment_intent.payment_failed,payment_intent.processing',
            '--forward-to',
            "$apiBaseUrl/api/Payments/webhook",
            '--color',
            'off'
        ) `
        -RedirectStandardOutput $stdoutPath `
        -RedirectStandardError $stderrPath `
        -WindowStyle Hidden `
        -PassThru
}
finally {
    Remove-Item Env:STRIPE_API_KEY -ErrorAction SilentlyContinue
}

$webhookSecret = $null
for ($attempt = 0; $attempt -lt 30; $attempt++) {
    Start-Sleep -Seconds 1
    $listener.Refresh()
    $output = ((Get-Content $stdoutPath -Raw -ErrorAction SilentlyContinue) + "`n" +
        (Get-Content $stderrPath -Raw -ErrorAction SilentlyContinue))
    $secretMatch = [regex]::Match($output, 'whsec_[A-Za-z0-9]+')
    if ($secretMatch.Success) {
        $webhookSecret = $secretMatch.Value
        break
    }
    if ($listener.HasExited) {
        break
    }
}

if (-not $webhookSecret) {
    if (-not $listener.HasExited) {
        Stop-Process -Id $listener.Id -Force -ErrorAction SilentlyContinue
    }
    throw 'Stripe listener nije pokrenut. Provjerite .stripe-listener\stderr.log.'
}

$secretUpdated = $false
for ($index = 0; $index -lt $envLines.Count; $index++) {
    if ($envLines[$index] -like 'STRIPE_WEBHOOK_SECRET=*') {
        $envLines[$index] = 'STRIPE_WEBHOOK_SECRET=' + $webhookSecret
        $secretUpdated = $true
        break
    }
}
if (-not $secretUpdated) {
    $envLines.Add('STRIPE_WEBHOOK_SECRET=' + $webhookSecret)
}

[System.IO.File]::WriteAllLines($envPath, $envLines, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText($pidPath, $listener.Id.ToString(), [System.Text.UTF8Encoding]::new($false))

Push-Location $root
try {
    docker compose up -d --force-recreate --no-deps cabinrent-api
    if ($LASTEXITCODE -ne 0) {
        throw 'API kontejner nije ponovo pokrenut.'
    }
}
finally {
    Pop-Location
}

for ($attempt = 0; $attempt -lt 20; $attempt++) {
    Start-Sleep -Seconds 1
    try {
        $health = Invoke-WebRequest -Uri "$apiBaseUrl/health" -UseBasicParsing -TimeoutSec 5
        if ($health.StatusCode -eq 200) {
            Write-Host 'Stripe webhook listener radi, a CabinRent API je spreman.' -ForegroundColor Green
            exit 0
        }
    }
    catch {
        # API se jos pokrece.
    }
}

throw 'Stripe listener radi, ali API health provjera nije uspjela.'
