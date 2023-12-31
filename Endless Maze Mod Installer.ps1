Write-Host "Endless Maze Mod Installer 1.1" -ForegroundColor Cyan
Write-Host "This script will install and uninstall mods for you in the game endless maze" -ForegroundColor Gray
Write-Host "Endless Maze can be found on steam: https://store.steampowered.com/app/2663270/Endless_Maze/" -ForegroundColor Gray
Write-Host "Mods will only work in Windows!" -ForegroundColor Red
""

pause
Clear

# URL of GitHub .txt file
$url = "https://raw.githubusercontent.com/ItsTeraBytes/Endless-Maze-Mods/main/Mods.txt"
$steam_dir_url = "https://raw.githubusercontent.com/ItsTeraBytes/Endless-Maze-Mods/main/steam_directory.txt"

# Read text from the GitHub
try {
	$fileContent = Invoke-RestMethod -Uri $url
	$steam_directory = (Invoke-RestMethod -Uri $steam_dir_url) + '\win64'
	}
	catch {
		Clear
        Write-Host "Abort! Unable to retrieve mod files! Please make sure you have an internet connection, or GitHub is down..." -ForegroundColor Red
		pause
        return $null
    }

$Game_Path = 'C:\Program Files (x86)\Steam\steamapps\common\' + $steam_directory

# Identity game files and ask user when it's missing from the normal steam directory
if (Test-Path $Game_Path -PathType Container)
{
	Write-Host "Endless Maze game detected!" -ForegroundColor Green
} else
{
	do {
		$Game_Path = Read-Host "Endless Maze game not detected. Please type the directory of the steam game"
	} until (Test-Path $Game_Path -PathType Container)

	Write-Host "Endless Maze game detected!" -ForegroundColor Green
}

# Check if .txt file exist and if not, create one
if (-not(Test-Path $Game_Path'\installed_mods_do-not-modify.txt' -PathType Leaf))
{
	""
	Write-Host "It looks like this is the first time you ran this installer" -ForegroundColor Gray
	Write-Host "Creating installed_mods_do-not-modify.txt" -ForegroundColor Gray
	Write-Host "This file is used to track what mods you have installed" -ForegroundColor Gray
	""
	Write-Host "Do not delete/modify this file, it will break things, this file will not be big anyway" -ForegroundColor Red
	Write-Host "If you deleted/modify this file, reinstall Endless Maze" -ForegroundColor Red
	pause
	New-Item -Path $Game_Path'\installed_mods_do-not-modify.txt' -ItemType File
	Clear
}

# Script to download files from GitHub
function Download-GitHubFolder {
    param (
        [string]$Username = "ItsTeraBytes",
        [string]$Repository = "Endless-Maze-Mods",
        [string]$Branch = "main",
        [string]$Folder = "",
        [string]$Destination = "."
    )

    $ApiUrl = "https://api.github.com/repos/$Username/$Repository/contents"

    # Append the folder to the API URL to specify what folder to download
    if ($Folder -ne "") {
        $ApiUrl += "/$Folder"
    }

    # Add the branch name to the API URL
    $ApiUrl += "?ref=$Branch"

    function Update-Zip {
        param (
            [string]$FolderPath
        )
		
		$ZipPath = $FolderPath + '\package.zip'
		$NWPath = $FolderPath + '\package.nw'
		$TempPath = $FolderPath + '\TEMP'
		$extractedFolderPath = $FolderPath + '\ZipTEMP'
		
		Rename-Item -Path $NWPath -NewName 'package.zip'

		Expand-Archive -Path $ZipPath -DestinationPath $extractedFolderPath -Force
		
		Copy-Item -Path "$TempPath\*" -Destination $extractedFolderPath -Recurse -Force
		
		Compress-Archive -Path "$extractedFolderPath\*" -DestinationPath $ZipPath -Force

		Rename-Item -Path $ZipPath -NewName 'package.nw'
		
		Remove-Item $TempPath -Recurse -Force
		Remove-Item $extractedFolderPath -Recurse -Force
    }

    function Download-File {
        param (
            [string]$Url,
            [string]$OutputPath
        )

        $WebClient = New-Object System.Net.WebClient
        $WebClient.DownloadFile($Url, $OutputPath)
    }

    function Download-Folder {
        param (
            [string]$Url,
            [string]$OutputPath
        )

        $Content = Invoke-RestMethod -Uri $Url

        foreach ($Item in $Content) {
            if ($Item.type -eq "file") {
                $FileUrl = $Item.download_url
                $FileName = [System.IO.Path]::Combine($OutputPath, $Item.name)
                Download-File -Url $FileUrl -OutputPath $FileName
            } elseif ($Item.type -eq "dir") {
                $SubFolder = [System.IO.Path]::Combine($OutputPath, $Item.name)
                New-Item -ItemType Directory -Force -Path $SubFolder | Out-Null
                $SubUrl = $Item.url
                Download-Folder -Url $SubUrl -OutputPath $SubFolder
            }
        }
    }

    if (-not (Test-Path $Destination)) {
        New-Item -ItemType Directory -Force -Path $Destination | Out-Null
    }

    # Download the specified folder
    Download-Folder -Url $ApiUrl -OutputPath $Destination'\TEMP'

    # Update the existing zip file with the downloaded files
    Update-Zip -FolderPath $Destination

    Write-Host "Download and zip update completed." -ForegroundColor Green
}

""
"Some mods may conflit with each other. A mod may override changes another mod made"
"This can be prevented by choosing the order you install mods."
""
"List of mods:"

# Check if content is retrieved successfully
if ($fileContent -ne $null) {
    # Split the content into lines
    $lines = $fileContent -split "`n"

    while ($true) {
        # Print the content in a numbered list
        for ($i = 0; $i -lt $lines.Length; $i++) {
            if (Get-Content $Game_Path'\installed_mods_do-not-modify.txt' | Select-String -Pattern $lines[$i]) {
                Write-Host -NoNewline ("[{0}] {1}" -f ($i + 1), $lines[$i])
                " (Installed)"
            } else {
                Write-Host -NoNewline ("[{0}] {1}" -f ($i + 1), $lines[$i])
                " (Not installed)"
            }
        }
	    ""
        # Prompt the user for input
        Write-Host "Type (exit) when you are finished" -ForegroundColor Blue
        $userInput = Read-Host "Enter the mod you want to install/uninstall"
    
        # Validate user input
        if ($userInput -match 'exit') {
            Exit
        }
        if ($userInput -match '^\d+$' -and $userInput -ge 1 -and $userInput -le $lines.Length) {
            # Get the selected item
            $selectedItem = $lines[$userInput - 1]
			""
            Write-Host "Enter (yes) to confirm" -ForegroundColor Blue
            if (Get-Content $Game_Path'\installed_mods_do-not-modify.txt' | Select-String -Pattern $selectedItem) {
                $confirmation = Read-Host "Uninstall mod $selectedItem"
                if ($confirmation -eq 'yes') {
					""
                    Write-Host "Uninstalling mod: $selectedItem" -ForegroundColor Gray
                    ""
                    Write-Host "Downloading game file(s)..." -ForegroundColor Gray

                    Download-GitHubFolder -Branch "main" -Folder "Default/$selectedItem" -Destination $Game_Path
					
					$old_txt = Get-Content -Path $Game_Path'\installed_mods_do-not-modify.txt'

					# Read and remove mod name from list
					$new_txt = $old_txt | Where-Object { $_ -ne $selectedItem }
					Set-Content -Path $Game_Path'\installed_mods_do-not-modify.txt' -Value $new_txt
					pause
                }
            } else {
                $confirmation = Read-Host "Install mod $selectedItem"
                if ($confirmation -eq 'yes') {
					""
                    Write-Host "Installing mod: $selectedItem" -ForegroundColor Gray
                    ""
                    Write-Host "Downloading mod file(s)..." -ForegroundColor Gray

                    Download-GitHubFolder -Branch "main" -Folder "Mods/$selectedItem" -Destination $Game_Path

					# Read and remove mod name from list
                    Add-Content -Path $Game_Path'\installed_mods_do-not-modify.txt' -Value $selectedItem
					pause
                }
            }
        }
        else {
            Write-Host "Invalid input. Please enter a valid number."
        }
		Clear
    }
}
