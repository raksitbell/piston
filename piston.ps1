# Piston Management Script (Windows PowerShell)
# Usage: .\piston.ps1 <command>

$PistonPath = $PSScriptRoot
$PistonEnv = if (Test-Path "$PistonPath\.piston_env") { Get-Content "$PistonPath\.piston_env" } else { "dev" }

function Invoke-DockerCompose {
    param([string[]]$Args)
    $ComposeFile = "docker-compose.$PistonEnv.yaml"
    if (Test-Path "$PistonPath\$ComposeFile") {
        docker-compose -f $ComposeFile @Args
    } else {
        docker-compose @Args
    }
}

function Show-Help {
    Write-Host "=== Piston Management (PowerShell) ==="
    Write-Host "Current Environment: $PistonEnv"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host " select <env>           Select the environment"
    Write-Host " logs                   Show docker-compose logs"
    Write-Host " setup                  Interactive installation of language packages"
    Write-Host " list                   Lists all registered packages"
    Write-Host " install <pkgs...>      Installs language packages"
    Write-Host " start                  Starts piston"
    Write-Host " stop                   Stops piston"
    Write-Host " restart                 Restarts piston"
    Write-Host " uninstall <pkgs...>    Uninstalls language packages"
    Write-Host " bash                    Opens a bash shell for the piston_api container"
    Write-Host ""
    Write-Host " update                  Fetches and applies latest updates from origin"
    Write-Host " sync                    Synchronizes your fork with the upstream repository"
    Write-Host ""
    Write-Host "Development Commands:"
    Write-Host " clean-pkgs              Clean any package build artifacts on disk"
    Write-Host " clean-repo              Remove all packages from local repo"
    Write-Host " list-pkgs               Lists all packages that can be built"
    Write-Host " build-pkg <pkg> <ver>   Build a package"
    Write-Host " rebuild                 Build and restart the docker container"
    Write-Host " lint                    Lint the codebase using prettier"
}

$Command = $args[0]
$CommandArgs = $args[1..($args.Count - 1)]

switch ($Command) {
    "help" { Show-Help }
    "select" { 
        $NewEnv = $CommandArgs[0]
        if ($NewEnv) { $NewEnv | Out-File "$PistonPath\.piston_env" -Encoding ASCII; Write-Host "Selected environment: $NewEnv" }
        else { Write-Host "Usage: .\piston.ps1 select <environment>" }
    }
    "logs" { Invoke-DockerCompose -Args @("logs", "-f") }
    "start" { Invoke-DockerCompose -Args @("up", "-d") }
    "stop" { Invoke-DockerCompose -Args @("down") }
    "restart" { Invoke-DockerCompose -Args @("restart") }
    "bash" { Invoke-DockerCompose -Args @("exec", "api", "/bin/bash") }
    "rebuild" { 
        Invoke-DockerCompose -Args @("build")
        Invoke-DockerCompose -Args @("up", "-d")
    }
    "list" {
        if (-not (Test-Path "$PistonPath\core\cli\node_modules")) {
            Push-Location "$PistonPath\core\cli"; npm install; Pop-Location
        }
        node "$PistonPath\core\cli\index.js" ppman list @CommandArgs
    }
    "install" {
        if (-not (Test-Path "$PistonPath\core\cli\node_modules")) {
            Push-Location "$PistonPath\core\cli"; npm install; Pop-Location
        }
        node "$PistonPath\core\cli\index.js" ppman install @CommandArgs
    }
    "uninstall" {
        if (-not (Test-Path "$PistonPath\core\cli\node_modules")) {
            Push-Location "$PistonPath\core\cli"; npm install; Pop-Location
        }
        node "$PistonPath\core\cli\index.js" ppman uninstall @CommandArgs
    }
    "setup" {
        Write-Host "=== Piston Setup Wizard (Windows) ==="
        Write-Host "Scanning for available language packages..."
        $Pkgs = Get-ChildItem -Path "$PistonPath\packages" -Directory -Recurse -Depth 1 | Where-Object { $_.Parent.Name -eq "packages" -or $_.Parent.Parent.Name -eq "packages" } | ForEach-Object {
             if ($_.Parent.Name -eq "packages") {
                 $Parent = $_.Name
                 Get-ChildItem -Path $_.FullName -Directory | ForEach-Object { "$Parent-$($_.Name)" }
             }
        } | Sort-Object
        
        if ($Pkgs.Count -eq 0) { Write-Host "No packages found."; exit }

        for ($i=0; $i -lt $Pkgs.Count; $i++) {
            Write-Host ("[{0,2}] {1}" -f ($i+1), $Pkgs[$i])
        }

        $Selection = Read-Host "Enter selections (e.g., 1,3,5 or shorthand 'gcc,node'). 'all' for everything"
        $SelectedItems = @()

        if ($Selection -eq "all") { $SelectedItems = $Pkgs }
        else {
            foreach ($Item in ($Selection -split ',')) {
                $Item = $Item.Trim()
                if ($Item -match '^\d+$') {
                    $Idx = [int]$Item - 1
                    if ($Idx -ge 0 -and $Idx -lt $Pkgs.Count) { $SelectedItems += $Pkgs[$Idx] }
                } else {
                    $Matches = $Pkgs | Where-Object { $_ -like "$Item*" }
                    if ($Matches) { $SelectedItems += $Matches[-1] }
                }
            }
        }

        $SelectedItems = $SelectedItems | Select-Object -Unique
        Write-Host "Installing $($SelectedItems.Count) package(s)..."

        foreach ($Pkg in $SelectedItems) {
            $Parts = $Pkg -split '-'
            $Lang = $Parts[0]
            $Ver = $Parts[1]
            Write-Host "📦 Installing $Pkg..."
            Invoke-DockerCompose -Args @("up", "-d")
            .\piston.ps1 build-pkg $Lang $Ver
            .\piston.ps1 install $Lang
            Write-Host "✅ $Pkg installed!"
        }
    }
    "sync" {
        $Remotes = git remote
        if ($Remotes -notcontains "upstream") {
            Write-Host "❌ 'upstream' remote not found."
            exit 1
        }
        git fetch upstream
        $Response = Read-Host "Rebase local changes on upstream/master? [y/N]"
        if ($Response -match '^[yY]$') {
            git rebase upstream/master
            Write-Host "✅ Sync complete!"
        }
    }
    "clean-pkgs" { git clean -fqXd packages }
    "clean-repo" { git clean -fqXd core/repo }
    "list-pkgs" { 
        Get-ChildItem -Path "$PistonPath\packages" -Directory -Recurse -Depth 1 | Where-Object { $_.Parent.Name -eq "packages" -or $_.Parent.Parent.Name -eq "packages" } | ForEach-Object {
             if ($_.Parent.Name -eq "packages") {
                 $Parent = $_.Name
                 Get-ChildItem -Path $_.FullName -Directory | ForEach-Object { "$Parent-$($_.Name)" }
             }
        } | ForEach-Object { Write-Host $_ }
    }
    "build-pkg" {
        $Lang = $CommandArgs[0]
        $Ver = $CommandArgs[1]
        $PkgSlug = "$Lang-$Ver"
        $Builder = if ($CommandArgs[2]) { $CommandArgs[2] } else { "piston-repo-builder" }
        Write-Host "Building $PkgSlug..."
        docker build core/repo -t $Builder
        docker run --rm -v "${PistonPath}:/piston" $Builder --no-server $PkgSlug
    }
    "update" {
        git pull
        Push-Location "$PistonPath\core\cli"; npm install; Pop-Location
        Invoke-DockerCompose -Args @("pull")
        Invoke-DockerCompose -Args @("up", "-d")
    }
    "lint" {
        npm install
        npx prettier --ignore-unknown --write .
    }
    default {
        if ($Command) {
            if (-not (Test-Path "$PistonPath\core\cli\node_modules")) {
                Push-Location "$PistonPath\core\cli"; npm install; Pop-Location
            }
            node "$PistonPath\core\cli\index.js" @args
        } else {
            Show-Help
        }
    }
}
