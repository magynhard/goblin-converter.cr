# Windows dev environment for goblin-converter.cr (MSVC + gvsbuild GTK stack).
#
# Usage (PowerShell, per shell session):
#   . .\scripts\goblin-env.ps1
#   # with custom locations:
#   . .\scripts\goblin-env.ps1 -GtkDir C:\home\software\gtk -ImageMagickDir C:\home\software\ImageMagick
#
# What it does:
#   1. Loads the VS2022 x64 toolchain via vcvars64.bat (needs VS2022 Build Tools
#      or Community with "Desktop development with C++" + Windows 10 SDK).
#   2. Removes ancient VC98/VS6 entries from PATH/LIB/INCLUDE so they cannot
#      shadow the modern toolchain.
#   3. Prepends the gvsbuild GTK stack (bin/lib/include) and sets
#      PKG_CONFIG_PATH so gi-crystal/gtk4 find their .pc files and .lib files.
#   4. Requires Crystal >= 1.21 in PATH (gi-crystal 0.26.0 needs
#      Fiber::ExecutionContext).
#   5. Optionally prepends ImageMagick (runtime `magick` for conversions)
#      and Ghostscript (runtime `gs` delegate for PDF input).
#
# After this: `shards install`, `.\bin\gi-crystal.exe`, then
# `crystal build src/goblin-converter.cr -o bin/goblin-converter.exe`.
param(
  [string]$GtkDir = "C:\gtk",
  [string]$ImageMagickDir = "",
  [string]$GhostscriptDir = "",
  [string]$CrystalDir = ""
)

$ErrorActionPreference = "Stop"

$vcvarsCandidates = @(
  "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat",
  "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
)
$vcvars = $vcvarsCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $vcvars) { throw "vcvars64.bat not found. Install VS2022 Build Tools (MSVC v143) + Windows 10 SDK." }

$raw = & cmd /c "`"$vcvars`" >nul && set"
foreach ($line in $raw) {
  if ($line -match '^([^=]+)=(.*)$') {
    Set-Item -Path ("env:" + $matches[1]) -Value $matches[2]
  }
}

# Never let ancient VC98/VS6 entries shadow the modern toolchain.
$env:PATH = ($env:PATH -split ';' | Where-Object { $_ -and ($_ -notmatch 'VC98|VisualStudio6|VB98|Vfp98|VIntDev98') }) -join ';'
foreach ($v in @('LIB', 'INCLUDE', 'LIBPATH')) {
  $cur = (Get-Item -Path "env:$v" -ErrorAction SilentlyContinue).Value
  if ($cur) {
    Set-Item -Path "env:$v" -Value (($cur -split ';' | Where-Object { $_ -and ($_ -notmatch 'VC98') }) -join ';')
  }
}

if ($CrystalDir -ne "") {
  if (-not (Test-Path -LiteralPath "$CrystalDir\crystal.exe")) { throw "Crystal not found: $CrystalDir\crystal.exe" }
  $env:PATH = "$CrystalDir;" + (($env:PATH -split ';' | Where-Object { $_ -and ($_ -ne $CrystalDir) }) -join ';')
}
$crystalVersion = & crystal --version 2>&1 | Select-Object -First 1
if ($crystalVersion -notmatch 'Crystal (\d+)\.(\d+)') { throw "Cannot determine Crystal version: $crystalVersion" }
if ([int]$Matches[1] -lt 1 -or ([int]$Matches[1] -eq 1 -and [int]$Matches[2] -lt 21)) {
  throw "Crystal >= 1.21 required (gi-crystal 0.26.0 needs Fiber::ExecutionContext), found: $crystalVersion"
}

if (-not (Test-Path -LiteralPath "$GtkDir\bin\pkg-config.exe")) { throw "GTK stack missing: $GtkDir\bin\pkg-config.exe not found (gvsbuild GTK4 zip)." }
if (-not (Test-Path -LiteralPath "$GtkDir\lib\girepository-1.0.lib")) { throw "GTK stack incomplete: $GtkDir\lib\girepository-1.0.lib not found." }

if (($env:PATH -split ';') -notcontains "$GtkDir\bin") { $env:PATH = "$GtkDir\bin;" + $env:PATH }
if ($env:LIB -notlike "$GtkDir\lib*") { $env:LIB = "$GtkDir\lib;" + $env:LIB }
$gtkIncludes = "$GtkDir\include;$GtkDir\include\cairo;$GtkDir\include\glib-2.0;$GtkDir\include\gobject-introspection-1.0;$GtkDir\lib\glib-2.0\include"
if ($env:INCLUDE -notlike "$GtkDir\include*") { $env:INCLUDE = $gtkIncludes + ";" + $env:INCLUDE }
$env:PKG_CONFIG_PATH = "$GtkDir\lib\pkgconfig;$GtkDir\share\pkgconfig"

if ($ImageMagickDir -ne "" -and (Test-Path -LiteralPath "$ImageMagickDir\magick.exe")) {
  if (($env:PATH -split ';') -notcontains $ImageMagickDir) { $env:PATH = "$ImageMagickDir;" + $env:PATH }
}

if ($GhostscriptDir -ne "") {
  $gsBin = if (Test-Path -LiteralPath "$GhostscriptDir\bin\gswin64c.exe") { "$GhostscriptDir\bin" } else { $GhostscriptDir }
  if (($env:PATH -split ';') -notcontains $gsBin) { $env:PATH = "$gsBin;" + $env:PATH }
}

Write-Host "goblin-env ready: $crystalVersion | $(& cl.exe 2>&1 | Select-Object -First 1) | pkg-config $(& "$GtkDir\bin\pkg-config.exe" --version)"
