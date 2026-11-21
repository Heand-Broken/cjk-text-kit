<#
.SYNOPSIS
    Publishes CJK Text Kit to itch.io with the official butler CLI.

.EXAMPLE
    .\publish.ps1 -Project yourname/cjk-text-kit

.DESCRIPTION
    Finds butler, loads your itch.io API key, stages the upload directory and
    pushes it. The API key is read from $env:ITCH_API_KEY or from
    api_key.txt next to this script.
#>
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Project,

    [string]$Butler = ""
)

$ErrorActionPreference = "Stop"

$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = Split-Path -Parent $Here
$Dist = Join-Path $env:TEMP "cjk-text-kit-upload"

function Write-Step($message) { Write-Host "`n==> $message" -ForegroundColor Cyan }
function Write-Ok($message) { Write-Host "    $message" -ForegroundColor DarkGray }
function Write-Warn($message) { Write-Host "    $message" -ForegroundColor Yellow }

# --- 0. package -------------------------------------------------------------

Write-Step "Packaging the release archives"
$packager = Join-Path $Root "tools\package_release.py"
if (Test-Path $packager) {
    Push-Location $Root
    try {
        python $packager
        if ($LASTEXITCODE -eq 0) {
            Write-Ok "archives are up to date"
        } else {
            Write-Warn "packaging failed with exit code $LASTEXITCODE, continuing with whatever is in dist\"
        }
    } catch {
        Write-Warn "could not run the packager: $($_.Exception.Message)"
    } finally {
        Pop-Location
    }
} else {
    Write-Warn "packager not found, using the archives already in dist\"
}

# --- 1. butler ---------------------------------------------------------------

Write-Step "Locating butler"
if ([string]::IsNullOrWhiteSpace($Butler)) {
    $command = Get-Command butler -ErrorAction SilentlyContinue
    if ($command) {
        $Butler = $command.Source
    } else {
        $local = Join-Path $Root "tools\butler\butler.exe"
        if (Test-Path $local) { $Butler = $local }
    }
}

if ([string]::IsNullOrWhiteSpace($Butler)) {
    Write-Warn "butler was not found. Trying to install it with winget..."
    try {
        winget install --id itchio.butler --accept-source-agreements --accept-package-agreements | Out-Null
        $command = Get-Command butler -ErrorAction SilentlyContinue
        if ($command) {
            $Butler = $command.Source
            Write-Ok "installed via winget"
        }
    } catch {
        Write-Warn "winget could not install butler automatically."
    }
}

if ([string]::IsNullOrWhiteSpace($Butler)) {
    Write-Warn "butler is still missing. Install it with one of:"
    Write-Warn "  winget install itchio.butler"
    Write-Warn "  or download https://itch.io/docs/butler/ and put butler.exe on your PATH"
    exit 1
}
Write-Ok "butler: $Butler"

# --- 2. API key -------------------------------------------------------------

$key = $env:ITCH_API_KEY
$keyFile = Join-Path $Here "api_key.txt"
if ([string]::IsNullOrWhiteSpace($key) -and (Test-Path $keyFile)) {
    $key = (Get-Content $keyFile -Raw).Trim()
}

if ([string]::IsNullOrWhiteSpace($key)) {
    Write-Warn "No itch.io API key found."
    Write-Warn "Create one at https://itch.io/settings/user/api-keys"
    Write-Warn "then run: `$env:ITCH_API_KEY = 'your-key'   (or save it to itch\api_key.txt)"
    exit 1
}
Write-Ok "API key loaded"

# --- 3. upload directory ----------------------------------------------------

Write-Step "Assembling the upload directory"
if (Test-Path $Dist) { Remove-Item -Recurse -Force $Dist }
New-Item -ItemType Directory -Path $Dist | Out-Null

$pluginZip = Join-Path $Root "dist\cjk-text-kit-v1.0.0.zip"
$demoZip = Join-Path $Root "dist\cjk-text-kit-demo-v1.0.0.zip"

foreach ($zip in @($pluginZip, $demoZip)) {
    if (Test-Path $zip) {
        Copy-Item $zip $Dist
        Write-Ok "staged $(Split-Path -Leaf $zip)"
    } else {
        Write-Warn "missing $(Split-Path -Leaf $zip) - skipped"
    }
}

if ((Get-ChildItem $Dist -File).Count -eq 0) {
    Write-Warn "Nothing to upload. Run the packaging step first."
    exit 1
}

# --- 4. push ----------------------------------------------------------------

Write-Step "Pushing to itch.io ($Project)"
& $Butler push $Project $Dist --api-key $key
if ($LASTEXITCODE -ne 0) {
    Write-Warn "butler push failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

# --- 5. verify --------------------------------------------------------------

Write-Step "Verifying the upload"
try {
    $parts = $Project -split "/"
    $user = $parts[0]
    $slug = $parts[1]
    $uri = "https://itch.io/api/1/$user/$slug/uploads?api_key=$key"
    $uploads = Invoke-RestMethod -Uri $uri -TimeoutSec 60
    if ($uploads -and $uploads.Count -gt 0) {
        foreach ($upload in $uploads) {
            Write-Ok ("{0}  {1:N1} KB" -f $upload.filename, ($upload.size / 1KB))
        }
    } else {
        Write-Warn "the API reported no uploads yet. Refresh the page in a moment."
    }
} catch {
    Write-Warn "could not verify through the API: $($_.Exception.Message)"
    Write-Warn "check the project page manually instead."
}

Write-Host @"

Uploaded. Next on the website:
  1. Open https://itch.io/$Project
  2. Paste the description from itch\itch-page.md
  3. Upload cover.png as the cover and demo.gif as the embedded file
  4. Set the price to 9.99 USD for launch, 19.99 USD afterwards
  5. Press Save, then set Visibility to Public

Full checklist: itch\PUBLISH.md
"@ -ForegroundColor Green
