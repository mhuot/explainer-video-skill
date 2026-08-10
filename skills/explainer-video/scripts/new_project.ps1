[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$ProjectDir,
    [string]$EngineImage = "ghcr.io/mhuot/skills-video-engine:0.3.1",
    [string]$GsapSource,
    [switch]$Offline
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

if ($EngineImage -notmatch "^[A-Za-z0-9][A-Za-z0-9._/:@-]*$") {
    throw "Engine image contains unsupported characters: $EngineImage"
}

$SkillDir = Split-Path -Parent $PSScriptRoot
$Target = [IO.Path]::GetFullPath($ProjectDir)
$ProjectName = Split-Path -Leaf $Target
if ($ProjectName -notmatch "^[A-Za-z0-9._-]+$") {
    throw "Project directory name may contain only letters, numbers, dots, dashes, and underscores"
}
if (Test-Path -LiteralPath $Target) {
    throw "Refusing to overwrite existing path: $Target"
}

$Parent = Split-Path -Parent $Target
New-Item -ItemType Directory -Force -Path $Parent | Out-Null
$Staging = Join-Path $Parent ".$ProjectName.tmp.$([Guid]::NewGuid().ToString('N'))"

try {
    @(
        "production/research",
        "production/script",
        "production/scene_plan",
        "production/checkpoints/frames",
        "production/assets/audio",
        "production/renders",
        "production/snapshots",
        "tools",
        "video/assets/audio"
    ) | ForEach-Object {
        New-Item -ItemType Directory -Force -Path (Join-Path $Staging $_) | Out-Null
    }

    Copy-Item (Join-Path $SkillDir "scripts/tts_generate.py") (Join-Path $Staging "tools/")
    Copy-Item (Join-Path $SkillDir "scripts/tts_pronounce.py") (Join-Path $Staging "tools/")
    Copy-Item (Join-Path $SkillDir "scripts/engine.sh") (Join-Path $Staging "tools/")
    Copy-Item (Join-Path $SkillDir "scripts/engine.ps1") (Join-Path $Staging "tools/")
    Copy-Item (Join-Path $SkillDir "assets/composition-skeleton.html") (Join-Path $Staging "video/index.html")
    Copy-Item (Join-Path $SkillDir "assets/decision-log.json") (Join-Path $Staging "production/checkpoints/decision-log.json")

    $GsapDestination = Join-Path $Staging "video/assets/gsap.min.js"
    if ($GsapSource) {
        if (-not (Test-Path -LiteralPath $GsapSource -PathType Leaf)) {
            throw "GSAP source is missing: $GsapSource"
        }
        Copy-Item -LiteralPath $GsapSource -Destination $GsapDestination
    } else {
        if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
            throw "Docker is required to copy the bundled GSAP runtime"
        }
        $PullPolicy = if ($Offline) { "never" } else { "missing" }
        $DockerArgs = @(
            "run", "--rm",
            "--network", "none",
            "--pull", $PullPolicy,
            "--volume", "${Staging}:/project",
            "--workdir", "/project",
            $EngineImage,
            "copy-gsap", "video/assets/gsap.min.js"
        )
        & docker @DockerArgs
        if ($LASTEXITCODE -ne 0) {
            throw "Unable to copy GSAP from engine image $EngineImage.`nEnsure Docker can pull the image, or use -Offline only after it is cached.`nCustom images must provide the copy-gsap command; -GsapSource remains available."
        }
        if (-not (Test-Path -LiteralPath $GsapDestination -PathType Leaf) -or
            (Get-Item -LiteralPath $GsapDestination).Length -eq 0) {
            throw "Engine did not provide video/assets/gsap.min.js"
        }
    }

    @{
        schemaVersion = 1
        name = $ProjectName
        recipe = "explainer-video"
        engineImage = $EngineImage
    } | ConvertTo-Json | Set-Content -Encoding utf8 (Join-Path $Staging "video-project.json")

    @"
.DS_Store
.venv/
__pycache__/
*.py[cod]
"@ | Set-Content -Encoding utf8 (Join-Path $Staging ".gitignore")

    @"
# $ProjectName

Created with the explainer-video skill.

## Docker workflow

PowerShell:

    & .\tools\engine.ps1 python tools/tts_generate.py
    & .\tools\engine.ps1 -Workdir video hyperframes lint
    & .\tools\engine.ps1 -Workdir video hyperframes check
    & .\tools\engine.ps1 -Workdir video hyperframes render --quality high --output ../production/renders/master.mp4

Bash:

    ./tools/engine.sh python tools/tts_generate.py
    ./tools/engine.sh --workdir video hyperframes lint
    ./tools/engine.sh --workdir video hyperframes check
    ./tools/engine.sh --workdir video hyperframes render --quality high --output ../production/renders/master.mp4
"@ | Set-Content -Encoding utf8 (Join-Path $Staging "README.md")

    if (Test-Path -LiteralPath $Target) {
        throw "Project path appeared during setup; refusing to overwrite: $Target"
    }
    Move-Item -LiteralPath $Staging -Destination $Target
    Write-Output "Created explainer-video project: $Target"
    Write-Output "Engine: $EngineImage"
} finally {
    if (Test-Path -LiteralPath $Staging) {
        Remove-Item -LiteralPath $Staging -Recurse -Force
    }
}
