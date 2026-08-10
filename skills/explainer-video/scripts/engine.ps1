[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$Workdir = ".",
    [string]$ProjectDir = (Get-Location).Path,
    [string]$Image = $env:SKILLS_VIDEO_ENGINE_IMAGE,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Command
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

if (-not $Image) {
    $Image = "ghcr.io/mhuot/skills-video-engine:0.3.1"
}
if (-not $Command -or $Command.Count -eq 0) {
    throw "Usage: engine.ps1 [-Workdir relative/path] [-ProjectDir PATH] <engine command> [arguments...]"
}
if ([IO.Path]::IsPathRooted($Workdir) -or ($Workdir -split "[\\/]" | Where-Object { $_ -eq ".." })) {
    throw "Workdir must be a relative path beneath the video project"
}

$ResolvedProject = (Resolve-Path -LiteralPath $ProjectDir).Path
$ContainerWorkdir = "/project"
if ($Workdir -ne ".") {
    $NormalizedWorkdir = $Workdir -replace "^[.][\\/]", ""
    $ContainerWorkdir = "/project/" + ($NormalizedWorkdir -replace "\\", "/")
}

$DockerArgs = @(
    "run", "--rm", "--init",
    "--shm-size=1g",
    "--network", "none",
    "--volume", "${ResolvedProject}:/project",
    "--workdir", $ContainerWorkdir,
    $Image
) + $Command

& docker @DockerArgs
exit $LASTEXITCODE
