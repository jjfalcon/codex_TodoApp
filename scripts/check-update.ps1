param(
  [Parameter(Mandatory = $true)]
  [string] $ManifestUrl,

  [Parameter(Mandatory = $true)]
  [string] $CurrentVersion,

  [string] $DownloadDir = "updates"
)

$ErrorActionPreference = "Stop"

function Compare-VersionText {
  param(
    [string] $Left,
    [string] $Right
  )

  $leftParts = @($Left.Split(".") | ForEach-Object { [int]$_ })
  $rightParts = @($Right.Split(".") | ForEach-Object { [int]$_ })
  $max = [Math]::Max($leftParts.Count, $rightParts.Count)

  for ($i = 0; $i -lt $max; $i++) {
    $leftValue = 0
    $rightValue = 0
    if ($i -lt $leftParts.Count) { $leftValue = $leftParts[$i] }
    if ($i -lt $rightParts.Count) { $rightValue = $rightParts[$i] }
    if ($leftValue -gt $rightValue) { return 1 }
    if ($leftValue -lt $rightValue) { return -1 }
  }

  return 0
}

function Read-Manifest {
  param([string] $Source)

  if ($Source -match "^https?://") {
    return Invoke-RestMethod -Uri $Source -UseBasicParsing
  }

  return Get-Content -LiteralPath $Source -Raw | ConvertFrom-Json
}

function Resolve-PackageUrl {
  param(
    [string] $ManifestSource,
    [string] $Package
  )

  if ($Package -match "^https?://") {
    return $Package
  }

  if ($ManifestSource -match "^https?://") {
    $baseUri = [Uri]$ManifestSource
    return ([Uri]::new($baseUri, $Package)).AbsoluteUri
  }

  $basePath = Split-Path -Parent (Resolve-Path -LiteralPath $ManifestSource)
  return Join-Path $basePath $Package
}

function Copy-OrDownload {
  param(
    [string] $Source,
    [string] $Target
  )

  if ($Source -match "^https?://") {
    Invoke-WebRequest -Uri $Source -OutFile $Target -UseBasicParsing
    return
  }

  Copy-Item -LiteralPath $Source -Destination $Target -Force
}

$manifest = Read-Manifest -Source $ManifestUrl

foreach ($required in @("version", "package", "sha256")) {
  if (-not $manifest.$required) {
    throw "Update manifest does not include $required."
  }
}

if ((Compare-VersionText -Left $manifest.version -Right $CurrentVersion) -le 0) {
  Write-Host "No update available. Current=$CurrentVersion Latest=$($manifest.version)"
  exit 0
}

if (-not (Test-Path -LiteralPath $DownloadDir)) {
  New-Item -ItemType Directory -Path $DownloadDir | Out-Null
}

$packageUrl = Resolve-PackageUrl -ManifestSource $ManifestUrl -Package $manifest.package
$targetPath = Join-Path $DownloadDir ([IO.Path]::GetFileName($manifest.package))

Copy-OrDownload -Source $packageUrl -Target $targetPath

$actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $targetPath).Hash.ToLowerInvariant()
$expectedHash = ([string]$manifest.sha256).ToLowerInvariant()

if ($actualHash -ne $expectedHash) {
  Remove-Item -LiteralPath $targetPath -Force
  throw "Downloaded package hash does not match latest manifest."
}

Write-Host "Update available and verified."
Write-Host "Current: $CurrentVersion"
Write-Host "Latest:  $($manifest.version)"
Write-Host "Package: $targetPath"
Write-Host "SHA256:  $actualHash"
