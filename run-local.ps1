$ErrorActionPreference = 'Stop'

$root = $PSScriptRoot
$gradleVersion = '8.10.2'
$gradleRoot = Join-Path $root '.gradle-dist'
$gradleHome = Join-Path $gradleRoot "gradle-$gradleVersion"
$gradleZip = Join-Path $gradleRoot "gradle-$gradleVersion-bin.zip"
$gradleSha256 = '31c55713e40233a8303827ceb42ca48a47267a0ad4bab9177123121e71524c26'

function Get-ToolPath {
    param([string]$Name)

    $tool = Get-Command $Name -ErrorAction SilentlyContinue
    if (-not $tool) {
        throw "Required tool '$Name' was not found on PATH."
    }
    return $tool.Source
}

function Invoke-Checked {
    param(
        [string]$Executable,
        [string[]]$Arguments,
        [string]$WorkingDirectory = $root
    )

    Push-Location $WorkingDirectory
    try {
        & $Executable @Arguments
        if ($LASTEXITCODE -ne 0) {
            throw "'$Executable $($Arguments -join ' ')' failed with exit code $LASTEXITCODE."
        }
    }
    finally {
        Pop-Location
    }
}

$maven = Get-ToolPath 'mvn'
$java = Get-ToolPath 'java'
$javac = Get-ToolPath 'javac'
$node = Get-ToolPath 'node'
$npm = Get-ToolPath 'npm'
$python = Get-ToolPath 'python'

Write-Host 'Checking local build tools...'
Invoke-Checked $java @('--version')
Invoke-Checked $javac @('-version')
Invoke-Checked $node @('--version')
Invoke-Checked $npm @('--version')
Invoke-Checked $python @('--version')

Write-Host "`nBuilding and testing Java/Maven..."
Invoke-Checked $maven @('-B', '-f', 'java-maven/pom.xml', 'clean', 'verify')

if (-not (Test-Path (Join-Path $gradleHome 'bin/gradle.bat'))) {
    New-Item -ItemType Directory -Force -Path $gradleRoot | Out-Null
    Write-Host "`nDownloading Gradle $gradleVersion..."
    Invoke-WebRequest `
        -Uri "https://services.gradle.org/distributions/gradle-$gradleVersion-bin.zip" `
        -OutFile $gradleZip `
        -UseBasicParsing

    $actualHash = (Get-FileHash -Path $gradleZip -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualHash -ne $gradleSha256) {
        Remove-Item -LiteralPath $gradleZip -Force
        throw 'Gradle distribution checksum verification failed.'
    }

    Expand-Archive -LiteralPath $gradleZip -DestinationPath $gradleRoot -Force
    Remove-Item -LiteralPath $gradleZip -Force
}

Write-Host "`nBuilding and testing Java/Gradle..."
Invoke-Checked (Join-Path $gradleHome 'bin/gradle.bat') @(
    '-p', 'java-gradle', 'clean', 'check', 'jacocoTestReport'
)

Write-Host "`nTesting Node.js..."
Invoke-Checked $npm @('install', '--no-package-lock') (Join-Path $root 'node')
Invoke-Checked $npm @('test') (Join-Path $root 'node')

$pythonProject = Join-Path $root 'python'
$pythonVenv = Join-Path $pythonProject '.venv'
$venvPython = Join-Path $pythonVenv 'Scripts/python.exe'
if (-not (Test-Path $venvPython)) {
    Invoke-Checked $python @('-m', 'venv', $pythonVenv)
}

Write-Host "`nTesting Python..."
Invoke-Checked $venvPython @('-m', 'pip', 'install', '-r', 'requirements.txt') $pythonProject
$previousPythonPath = $env:PYTHONPATH
$previousCoverageFile = $env:COVERAGE_FILE
try {
    $env:PYTHONPATH = $pythonProject
    $env:COVERAGE_FILE = Join-Path $pythonProject '.coverage'
    Invoke-Checked $venvPython @(
        '-m', 'coverage', 'run', '--source=src.palindrome',
        '-m', 'unittest', 'discover', '-s', 'tests'
    )
    Invoke-Checked $venvPython @('-m', 'coverage', 'xml', '-o', 'coverage.xml')
    Invoke-Checked $venvPython @('-m', 'coverage', 'report', '--fail-under=80')
}
finally {
    $env:PYTHONPATH = $previousPythonPath
    $env:COVERAGE_FILE = $previousCoverageFile
}

$port = 3000
$portCheck = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $port)
$portAvailable = $true
try {
    $portCheck.Start()
}
catch {
    $portAvailable = $false
}
finally {
    if ($portAvailable) {
        $portCheck.Stop()
    }
}
if (-not $portAvailable) {
    throw "Port $port is already in use. Stop the existing process or choose another port."
}

$demoBuild = Join-Path $root 'demo/.build'
New-Item -ItemType Directory -Force -Path $demoBuild | Out-Null
$stdoutLog = Join-Path $demoBuild 'server.stdout.log'
$stderrLog = Join-Path $demoBuild 'server.stderr.log'
$previousPort = $env:PORT
try {
    $env:PORT = "$port"
    $server = Start-Process `
        -FilePath $node `
        -ArgumentList 'server.js' `
        -WorkingDirectory (Join-Path $root 'demo') `
        -RedirectStandardOutput $stdoutLog `
        -RedirectStandardError $stderrLog `
        -WindowStyle Hidden `
        -PassThru
}
finally {
    $env:PORT = $previousPort
}

$url = "http://127.0.0.1:$port"
$ready = $false
for ($attempt = 0; $attempt -lt 30; $attempt++) {
    $server.Refresh()
    if ($server.HasExited) {
        break
    }
    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 2
        if ($response.StatusCode -eq 200) {
            $ready = $true
            break
        }
    }
    catch {
        Start-Sleep -Seconds 1
    }
}

if (-not $ready) {
    $server.Refresh()
    if (-not $server.HasExited) {
        Stop-Process -Id $server.Id
    }
    $serverError = if (Test-Path $stderrLog) { Get-Content -Raw $stderrLog } else { '' }
    throw "Demo server did not start. $serverError"
}

Start-Process $url
Write-Host "`nBuild passed. Demo opened at $url"
Write-Host "Keep this terminal open. Stop the demo with: Stop-Process -Id $($server.Id)"
