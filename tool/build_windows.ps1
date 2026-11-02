#Requires -Version 5.1

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Checked {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Executable,
        [string[]] $ArgumentList = @()
    )

    & $Executable @ArgumentList
    if ($LASTEXITCODE -ne 0) {
        throw "$Executable $($ArgumentList -join ' ') failed with exit code $LASTEXITCODE."
    }
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$locationPushed = $false
$temporaryArchive = $null
$scriptExitCode = 0

try {
    if ([System.Environment]::OSVersion.Platform -ne [System.PlatformID]::Win32NT) {
        throw 'Build this package on Windows with Flutter and Visual Studio C++ tools installed.'
    }

    $flutter = (Get-Command flutter.bat -CommandType Application -ErrorAction Stop |
        Select-Object -First 1).Source
    $dart = (Get-Command dart.bat -CommandType Application -ErrorAction Stop |
        Select-Object -First 1).Source
    if (-not (Test-Path -LiteralPath (Join-Path $projectRoot 'pubspec.yaml') -PathType Leaf)) {
        throw 'Cannot find pubspec.yaml next to the tool directory.'
    }

    Push-Location -LiteralPath $projectRoot
    $locationPushed = $true

    Invoke-Checked -Executable $flutter -ArgumentList @('--version')
    Invoke-Checked -Executable $flutter -ArgumentList @('config', '--enable-windows-desktop')
    Invoke-Checked -Executable $dart -ArgumentList @('tool/bootstrap_platforms.dart')
    Invoke-Checked -Executable $flutter -ArgumentList @('pub', 'get')
    Invoke-Checked -Executable $dart -ArgumentList @('format', 'lib', 'test', 'tool')
    Invoke-Checked -Executable $flutter -ArgumentList @('analyze')
    Invoke-Checked -Executable $flutter -ArgumentList @('test')
    Invoke-Checked -Executable $flutter -ArgumentList @('build', 'windows', '--release', '--target-platform', 'windows-x64')

    $releaseDirectory = Join-Path $projectRoot 'build/windows/x64/runner/Release'
    foreach ($requiredFile in @('chess_2.exe', 'flutter_windows.dll', 'data/icudtl.dat')) {
        $requiredPath = Join-Path $releaseDirectory $requiredFile
        if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
            throw "The Windows bundle is incomplete: missing $requiredFile."
        }
    }
    if (-not (Test-Path -LiteralPath (Join-Path $releaseDirectory 'data/flutter_assets') -PathType Container)) {
        throw 'The Windows bundle is incomplete: missing data/flutter_assets.'
    }

    $distDirectory = Join-Path $projectRoot 'dist'
    $null = New-Item -ItemType Directory -Path $distDirectory -Force
    $archivePath = Join-Path $distDirectory 'Chess-2-Windows-x64.zip'
    $temporaryArchive = Join-Path $distDirectory ("Chess-2-Windows-x64-{0}.zip" -f [guid]::NewGuid())

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    # Zip the entire directory, including DLLs, data, assets, and hidden files.
    [System.IO.Compression.ZipFile]::CreateFromDirectory(
        $releaseDirectory,
        $temporaryArchive,
        [System.IO.Compression.CompressionLevel]::Optimal,
        $false
    )
    Move-Item -LiteralPath $temporaryArchive -Destination $archivePath -Force
    $temporaryArchive = $null

    Write-Host "Windows package ready: $archivePath"
    Write-Host 'Extract the entire ZIP to a folder, then run chess_2.exe.'
}
catch {
    [Console]::Error.WriteLine("Windows package failed: $($_.Exception.Message)")
    $scriptExitCode = 1
}
finally {
    if ($temporaryArchive -and (Test-Path -LiteralPath $temporaryArchive)) {
        Remove-Item -LiteralPath $temporaryArchive -Force
    }
    if ($locationPushed) {
        Pop-Location
    }
}

exit $scriptExitCode
