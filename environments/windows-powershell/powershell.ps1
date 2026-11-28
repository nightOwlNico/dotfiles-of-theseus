# ========================== Custom Config Locations ==========================
# wezterm config location = C:\Users\Nico\.wezterm.lua
# starship config location = C:\Users\Nico\starship.toml
# lsd config location = C:\Users\Nico\AppData\Roaming\lsd\config.yaml
# fastfetch config location = C:\ProgramData\fastfetch\config.jsonc
# worktrunk config location = $env:APPDATA\worktrunk\config.toml
# ^^^^^^^^^^^^^^^^^^^^^^^^^^ Custom Config Locations ^^^^^^^^^^^^^^^^^^^^^^^^^^

# ======================== Cli Utilities With No Config ========================
# coreutils
# bat
# tlrc (tldr)
# ^^^^^^^^^^^^^^^^^^^^^^^^ Cli Utilities With No Config ^^^^^^^^^^^^^^^^^^^^^^^^

# ============================= Rust / MSVC Setup =============================
# Rust's Windows MSVC toolchain needs Microsoft's compiler/linker environment
# when Cargo builds an executable. Keep the normal shell environment unchanged
# until Cargo is actually used. On the first Cargo command in each PowerShell
# session, locate the installed Visual Studio Build Tools with vswhere and
# initialize the MSVC developer environment. Subsequent Cargo commands reuse
# that environment because Visual Studio sets VSCMD_VER after initialization.
#
# Calling cargo.exe explicitly inside the function avoids recursively calling
# this PowerShell wrapper.
function cargo {
    if (-not $env:VSCMD_VER) {
        $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"

        if (-not (Test-Path $vswhere)) {
            throw "Visual Studio Locator (vswhere.exe) was not found."
        }

        $vsPath = & $vswhere `
            -latest `
            -products * `
            -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
            -property installationPath

        if (-not $vsPath) {
            throw "Visual Studio Build Tools with the MSVC x64/x86 toolchain were not found."
        }

        $devShell = Join-Path $vsPath "Common7\Tools\Launch-VsDevShell.ps1"

        if (-not (Test-Path $devShell)) {
            throw "Visual Studio Developer PowerShell initializer was not found at '$devShell'."
        }

        try {
            & $devShell `
                -Arch amd64 `
                -HostArch amd64 `
                -SkipAutomaticLocation
        }
        finally {
            # Restore icons after Visual Studio changes the environment.
            if ($null -ne $global:MoonIconDaemonWatcher) {
                $global:MoonIconDaemonWatcher.Sync()
            }
        }

        if (-not $env:VSCMD_VER) {
            throw "The Visual Studio MSVC developer environment failed to initialize."
        }
    }

    & cargo.exe @args
}
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Rust / MSVC Setup ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

# ============================ Custom ls Using lsd ============================
function custom-lsd-ls { lsd --long $args }
Set-Alias -Name ls -Value custom-lsd-ls -Option AllScope
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Custom ls Using lsd ^^^^^^^^^^^^^^^^^^^^^^^^^^^^

# ============================= ls After Every cd =============================
# Decode native command output as UTF-8 so LSD icons display correctly.
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

# Run the ls after a successful directory change.
$ExecutionContext.SessionState.InvokeCommand.LocationChangedAction = {
    Write-Host
    ls | Out-Host
}
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ ls After Every cd ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

# Keep MOON_ICON synchronized with Moon Icon Daemon's published icon.
. 'D:\dev\moon-icon-daemon\shell-scripts\sync-moon-icon.ps1'

$ENV:STARSHIP_CONFIG = "$HOME\starship.toml"
$ENV:STARSHIP_CACHE = "$HOME\AppData\Local\Temp"

# ================== Shell Integration for WezTerm + Starship ==================
# https://wezterm.org/shell-integration.html#osc-7-on-windows-with-powershell-with-starship
$prompt = ""
function Invoke-Starship-PreCommand {
    $current_location = $executionContext.SessionState.Path.CurrentLocation
    if ($current_location.Provider.Name -eq "FileSystem") {
        $ansi_escape = [char]27
        $provider_path = $current_location.ProviderPath -replace "\\", "/"
        $prompt = "$ansi_escape]7;file://${env:COMPUTERNAME}/${provider_path}$ansi_escape\"
    }
    $host.ui.Write($prompt)
}
# ^^^^^^^^^^^^^^^^^^ Shell Integration for WezTerm + Starship ^^^^^^^^^^^^^^^^^^

# ================================== Starshp ==================================
# https://starship.rs/#powershell
Invoke-Expression (&starship init powershell)
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Starshp ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

if (Get-Command wt -ErrorAction SilentlyContinue) { Invoke-Expression (& wt config shell init powershell | Out-String) }
