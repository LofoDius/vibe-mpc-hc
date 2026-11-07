# Building for Windows 11 (x64)

Run from PowerShell in the repository root:

```powershell
git submodule update --init --recursive
.\build-windows11.ps1
```

The executable and its runtime dependencies are placed in
`bin/mpc-hc_x64`. Keep that entire directory together when copying the player
to another machine. Do not copy just `mpc-hc64.exe`.

Prerequisites in Visual Studio Installer:

- C++ desktop build tools and MSBuild (Visual Studio 2026 is supported).
- MSVC v141 (VS 2017) x86/x64 build tools and MFC for v141.
- Windows SDK 10.0.26100.0, or select another installed SDK with
  `-WindowsSdkVersion <version>`.
- YASM available on PATH (for VirtualDub assembly routines).

The v141 compiler is retained for this legacy source tree; Windows 11 does not
require a newer compiler. The build uses C++17 and the Windows 10/11 SDK,
not the Windows 8.1 SDK. This is an x64 build path, not an ARM64 build.

The script downloads pinned, SHA-256 checked archives into `build/dependencies`:

- Microsoft.DXSDK.D3DX 9.29.952.8 from NuGet, including the app-local D3DX9 DLL.
- Official LAV Filters 0.83 x64 binaries, including their licenses and dependencies.
- Python 2.7.18 from NuGet, used locally for the legacy translation generator.

These replace the legacy DirectX SDK installer and the MSYS2/FFmpeg source build
for this build path. No global codec registration or DirectX runtime installer
is needed. An Internet connection is needed for the first build. The original
build scripts remain available for building the pinned LAV source instead.

For a debug build:

```powershell
.\build-windows11.ps1 -Configuration Debug
```

Its output is `bin/mpc-hc_x64_Debug`. Build diagnostics are written to
`build/windows11-build.log`; translation diagnostics are written to
`build/windows11-translations.log`. Both Release and Debug builds include all
translated resource DLLs in the output's `Lang` directory.
Keep `Lang` beside the executable when distributing the player. The script does
not generate the installer.
