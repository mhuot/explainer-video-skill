[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$ProjectDir = ".",
    [switch]$Docker
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$Root = (Resolve-Path -LiteralPath $ProjectDir).Path
$Failed = $false
function Pass([string]$Message) { Write-Output "PASS $Message" }
function Fail([string]$Message) {
    [Console]::Error.WriteLine("FAIL $Message")
    $script:Failed = $true
}
function Warn([string]$Message) { Write-Warning $Message }

@(
    "video-project.json",
    "video/index.html",
    "video/assets/gsap.min.js",
    "production/assets/audio",
    "production/renders",
    "production/snapshots"
) | ForEach-Object {
    if (Test-Path -LiteralPath (Join-Path $Root $_)) { Pass $_ } else { Fail "missing $_" }
}

if (Test-Path -LiteralPath (Join-Path $Root "tools/tts_generate.py")) {
    Pass "tools/tts_generate.py"
} elseif (Test-Path -LiteralPath (Join-Path $Root "narration.json")) {
    Pass "narration.json"
} else {
    Warn "No narration generator; pre-authored audio is still supported"
}

try {
    $Manifest = Get-Content -Raw -LiteralPath (Join-Path $Root "video-project.json") | ConvertFrom-Json
    if ($Manifest.schemaVersion -ne 1 -or $Manifest.recipe -ne "explainer-video") {
        throw "schemaVersion must be 1 and recipe must be explainer-video"
    }
    Pass "video-project.json schema"
} catch {
    Fail "invalid video-project.json: $($_.Exception.Message)"
}

if ($Docker) {
    try {
        & docker version *> $null
        if ($LASTEXITCODE -ne 0) { throw "docker version failed" }
        Pass "Docker engine"
    } catch {
        Fail "Docker engine unavailable"
    }
    $Image = if ($env:SKILLS_VIDEO_ENGINE_IMAGE) {
        $env:SKILLS_VIDEO_ENGINE_IMAGE
    } else {
        "ghcr.io/mhuot/skills-video-engine:0.3.1"
    }
    & docker image inspect $Image *> $null
    if ($LASTEXITCODE -eq 0) {
        Pass "Skills Video Engine image $Image"
    } else {
        Fail "missing Engine image; run: docker pull $Image"
    }
}

if ($Failed) {
    throw "project check: failures above"
}
Write-Output "project check: ready"
