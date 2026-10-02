# Goblin Converter
![GitHub Release](https://img.shields.io/github/v/release/magynhard/goblin?style=plastic&color=default&label=GitHub&logo=github)
[![Flatpak](https://img.shields.io/badge/_-Flatpak-Sub?style=plastic&color=gray&logo=flatpak&logoColor=blu)](#)
[![Crystal](https://img.shields.io/badge/_-Crystal-Sub?style=plastic&color=gray&logo=crystal&logoColor=white)](#)
[![GTK](https://img.shields.io/badge/_-GTK-Sub?style=plastic&color=gray&logo=gtk&logoColor=green)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-gold.svg?style=plastic&logo=mit)](LICENSE)

<img src="data/icons/app-icon.svg" style="height: 96px;">

>
> A simple document converter GUI for GTK using magick

Initial use case was to convert 300ppi (PDF) documents (grayscale or colored) to monochrome (PDF) documents to reduce the size significantly for digital document storage.

E.g. a PDF document with 300ppi and about 3-4MB in grayscale can be reduced to about 40-75KB(!) in monochrome.

```diff
- Warning: This app is in early development and may not work as expected or at all due some refactorings.
```

# Setup
This app is distributed as a Flatpak package or can be installed locally.

## Flatpak
```bash
# Not available yet, follow the Local installation guide
flatpak install flathub de.magynhard.GoblinConverter
```

## Local
Ensure, Crystal is installed.

Beside, you need to have build tools and other dependencies to be installed.
### Ubuntu
```
sudo apt install build-essential libcairo2-dev libgirepository1.0-dev libgdk-pixbuf2.0-dev libgtk-4-common libgtk-4-dev libadwaita-1-0 libadwaita-1-dev imagemagick crystal
```
### Manjaro/Arch
```
sudo pacman -S base-devel crystal gtk4 libadwaita imagemagick
```

#### Install
```
git clone https://github.com/magynhard/goblin-converter.cr.git
cd goblin-converter.cr
shards install
make install
```
### Uninstall
```
cd goblin-converter.cr
make uninstall
```

# Development
Target platforms are Linux (primary) and Windows. macOS is not planned.

## Requirements (development)
* Crystal 1.21+
* GTK4
* ImageMagick 7
* Ghostscript 10

### Windows (verified 2026-10-02, MSVC route)
Build must run on a Windows machine (no cross-compile from Linux):

1. Install: Crystal for Windows (MSVC, portable zip) + VS2022 Build Tools
   ("Desktop development with C++", MSVC v143 x64) + Windows 10 SDK.
   Enable Developer Mode in Windows Settings.
2. Unzip a wingtk/gvsbuild `GTK4_Gvsbuild_<ver>_x64.zip` to `C:\gtk`
   (provides GTK4/Adwaita, GObject-Introspection, pkg-config, msgfmt).
3. Per PowerShell session, load the env (adjust paths if needed):
   ```
   . .\scripts\goblin-env.ps1 [-GtkDir C:\gtk] [-CrystalDir ...] [-ImageMagickDir ...] [-GhostscriptDir ...]
   ```
4. Then as usual (no `make` needed):
   ```
   shards install
   .\bin\gi-crystal.exe
   crystal build src/goblin-converter.cr -o bin/goblin-converter.exe
   crystal spec
   ```
   `make install` is Unix-only. Runtime needs ImageMagick 7 (`magick.exe`,
   portable zip works) and Ghostscript 10 (`gs` installer, run elevated —
   there is no portable zip) plus `C:\gtk\bin` on `PATH` (for the GTK DLLs).
   Tip: if monochrome Fax/PDF output looks broken and your user name contains
   non-ASCII chars, set `MAGICK_TEMPORARY_PATH` to an ASCII-only directory.

## Install local for development
```
make install
```

## Build
```
make build
```

## Run
```
make run
```

## Create locales
```
make locales
```

## Clean
```
make clean
```

## Create new version
### Update version in shard.yml
```yaml
version: 0.X.X
```

### Create tag
```
git tag 0.X.X
git push origin 0.X.X
```
