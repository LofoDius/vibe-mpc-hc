$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Push-Location $root
try {
    $version = Get-Content include/version.h -Raw
    $major = [regex]::Match($version, '#define\s+MPC_VERSION_MAJOR\s+(\d+)').Groups[1].Value
    $minor = [regex]::Match($version, '#define\s+MPC_VERSION_MINOR\s+(\d+)').Groups[1].Value
    $patch = [regex]::Match($version, '#define\s+MPC_VERSION_PATCH\s+(\d+)').Groups[1].Value
    $hash = git rev-parse --short HEAD
    if ($LASTEXITCODE -ne 0) { throw 'Cannot read Git revision.' }
    $info = @"
#define MPCHC_HASH _T("$hash")
#define MPC_VERSION_REV 0
#define MPC_VERSION_ADDITIONAL _T(" (Windows 11, $hash)")
#define GCC32_VERSION _T("not used - packaged LAV Filters")
#define GCC64_VERSION _T("not used - packaged LAV Filters")
"@
    $info += "`r`n"
    $file = Join-Path $PSScriptRoot 'version_rev.h'
    if (!(Test-Path $file) -or (Get-Content $file -Raw) -ne $info) {
        [IO.File]::WriteAllText($file, $info)
    }
    $file = Join-Path $root 'src/mpc-hc/res/mpc-hc.exe.manifest'
    $manifest = (Get-Content "$file.conf" -Raw).Replace('$VERSION$', "$major.$minor.$patch.0")
    if (!(Test-Path $file) -or (Get-Content $file -Raw) -ne $manifest) {
        [IO.File]::WriteAllText($file, $manifest)
    }
} finally { Pop-Location }
