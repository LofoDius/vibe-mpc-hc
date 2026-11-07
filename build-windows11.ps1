param(
    [ValidateSet('Debug', 'Release')][string]$Configuration = 'Release',
    [ValidatePattern('^10\.0(?:\.\d+\.\d+)?$')][string]$WindowsSdkVersion = '10.0.26100.0'
)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
Push-Location $root
try {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
    $vs = & $vswhere -latest -products '*' -requires Microsoft.Component.MSBuild -property installationPath
    if (!$vs) { throw 'Install Visual Studio with C++ build tools, MSVC v141 and MFC for v141.' }
    $toolset = Get-ChildItem "$vs/VC/Tools/MSVC/14.16.*" -Directory | Select-Object -Last 1
    if (!$toolset -or !(Test-Path "$($toolset.FullName)/atlmfc/include/afxwin.h")) {
        throw 'Install MSVC v141 (VS 2017) x86/x64 build tools and MFC for v141 in Visual Studio Installer.'
    }
    if (!(Get-Command yasm.exe -ErrorAction SilentlyContinue)) { throw 'Install YASM and add its directory to PATH.' }
    if (!(Test-Path src/thirdparty/sanear/sanear/sanear.vcxproj)) {
        throw 'Initialize dependencies: git submodule update --init --recursive'
    }
    $deps = Join-Path $root 'build/dependencies'
    New-Item -ItemType Directory -Path $deps -Force | Out-Null
    function Get-Archive($Url, $Name, $Directory, $Marker, $Sha256) {
        if (!(Test-Path (Join-Path $Directory $Marker))) {
            $archive = Join-Path $deps "$Name.zip"
            Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $archive
            if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $Sha256) {
                throw "Checksum mismatch: $Name"
            }
            Expand-Archive -LiteralPath $archive -DestinationPath $Directory -Force
        }
    }
    Get-Archive 'https://api.nuget.org/v3-flatcontainer/microsoft.dxsdk.d3dx/9.29.952.8/microsoft.dxsdk.d3dx.9.29.952.8.nupkg' 'd3dx' "$deps/d3dx" 'build/native/include/d3dx9.h' 'EAD0906AE8A26C18A7525DA7490127A2110F7C58F18293738283E30E97C6EA4B'
    Get-Archive 'https://github.com/Nevcairiel/LAVFilters/releases/download/0.83/LAVFilters-0.83-x64.zip' 'lav-0.83-x64' "$deps/lav-0.83-x64" 'LAVSplitter.ax' '0126982F47157BB86A6DBB43C4F332F7F98BEBA9AD552C19B65F9DB2E7D4F186'
    Get-Archive 'https://api.nuget.org/v3-flatcontainer/python2/2.7.18/python2.2.7.18.nupkg' 'python2' "$deps/python2" 'tools/python.exe' 'C8DF5BD4C103F37A946E94F942A5625CDD84665EE160BBCC57AF93857C892E22'
    $output = Join-Path $root 'bin/mpc-hc_x64'
    if ($Configuration -eq 'Debug') { $output += '_Debug' }
    New-Item -ItemType Directory -Path "$output/LAVFilters64" -Force | Out-Null
    Copy-Item "$deps/lav-0.83-x64/*" "$output/LAVFilters64" -Recurse -Force
    Copy-Item "$deps/d3dx/build/native/release/bin/x64/D3DX9_43.dll" $output -Force
    Copy-Item "$deps/d3dx/LICENSE.txt" "$output/D3DX-LICENSE.txt" -Force
    Copy-Item "$deps/d3dx/NOTICE.md" "$output/D3DX-NOTICE.md" -Force
    Copy-Item "$root/COPYING.txt" "$output/COPYING.txt" -Force
    $previousWindows11 = $env:MPCHC_WINDOWS11
    $env:MPCHC_WINDOWS11 = 'true'
    & "$root/build/Update-Version.ps1"
    $devcmd = Join-Path $vs 'Common7/Tools/VsDevCmd.bat'
    $buildCommand = "`"$devcmd`" -arch=x64 -host_arch=x64 -vcvars_ver=14.16 && msbuild mpc-hc.sln /m:1 /nr:false /t:Build /p:Configuration=$Configuration /p:Platform=x64 /p:PlatformToolset=v141 /p:MPCHC_WINDOWS11=true /p:MPCHC_WINSDK_VER=$WindowsSdkVersion /nologo /v:minimal /fl /flp:logfile=build\windows11-build.log;verbosity=minimal"
    & $env:ComSpec /d /s /c $buildCommand
    if ($LASTEXITCODE -ne 0) { throw 'Build failed. See build/windows11-build.log.' }
    & "$deps/python2/tools/python.exe" "$root/build/Generate-Translations.py"
    if ($LASTEXITCODE -ne 0) { throw 'Translation resource generation failed.' }
    # BuildAll selects each Release language configuration. Disable its legacy
    # SyncTranslations dependency: resources were generated above without editing PO files.
    $translationCommand = "`"$devcmd`" -arch=x64 -host_arch=x64 -vcvars_ver=14.16 && msbuild src\mpc-hc\mpcresources\BuildAll.vcxproj /m:1 /nr:false /t:Build /p:Configuration=Release /p:Platform=x64 /p:PlatformToolset=v141 /p:MPCHC_WINDOWS11=true /p:MPCHC_WINSDK_VER=$WindowsSdkVersion /p:BuildProjectReferences=false /p:SolutionDir=`"$root/`" /p:OutDir=`"$output/Lang/`" /nologo /v:minimal /fl /flp:logfile=build\windows11-translations.log;verbosity=minimal"
    & $env:ComSpec /d /s /c $translationCommand
    if ($LASTEXITCODE -ne 0) { throw 'Translation build failed. See build/windows11-translations.log.' }
    Write-Host "Built: $output/mpc-hc64.exe"
} finally {
    if (Get-Variable previousWindows11 -ErrorAction SilentlyContinue) { $env:MPCHC_WINDOWS11 = $previousWindows11 }
    Pop-Location
}
