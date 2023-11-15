"Endless Maze Mod Installer DEV 1.0"
"This script will install and uninstall mods for you in the game endless maze"
"Endless Maze can be found on steam"
"Mods will only work in Windows!"
""

$Game_Path = 'C:\Program Files (x86)\Steam\steamapps\common\EndlessMazex64\windows64\x64'

if (Test-Path $Game_Path -PathType Container)
{
	Write-Host "Endless Maze game detected!"
} else
{
	do {
		$Game_Path = Read-Host "Endless Maze game not detected. Please type the directory of the steam game"
	} until (Test-Path $Game_Path -PathType Container)

	"Endless Maze game detected!"
}

if (-not(Test-Path $Game_Path'\installed_mods_do-not-delete.txt' -PathType Leaf))
{
	""
	"This is the first time you ran this installer"
	"Creating installed_mods_do-not-delete.txt"
	"This file is used to track what mods you have installed"
	""
	"Do not delete this file, it will break things, this file will not be big anyway"
	"If you deleted this file, reinstall Endless Maze"
	pause
	New-Item -Path 	$Game_Path'\installed_mods_do-not-delete.txt' -ItemType File
}

function Download-GitHubFolder {
    param (
        [string]$Username = "ItsTeraBytes",
        [string]$Repository = "Endless-maze-mods",
        [string]$Branch = "main",
        [string]$Folder = "",
        [string]$Destination = "."
    )

    $ApiUrl = "https://api.github.com/repos/$Username/$Repository/contents"

    # Append the folder to the API URL if specified
    if ($Folder -ne "") {
        $ApiUrl += "/$Folder"
    }

    # Add the branch to the API URL
    $ApiUrl += "?ref=$Branch"

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
    Download-Folder -Url $ApiUrl -OutputPath $Destination

    Write-Host "Download completed."
    ""
}

# Function to read text from a URL
function Read-TextFromUrl($url) {
    try {
        $webClient = New-Object System.Net.WebClient
        $content = $webClient.DownloadString($url)
        return $content
    }
    catch {
        Write-Host "Abort! Unable to retrieve mod files! Please make sure you have an internet connection, or GitHub is down..."
		pause
        return $null
    }
}
""
"List of mods:"
# URL of the text file
$url = "https://raw.githubusercontent.com/ItsTeraBytes/Endless-maze-mods/main/Mods.txt"

# Read text from the URL
$fileContent = Read-TextFromUrl $url

# Check if content is retrieved successfully
if ($fileContent -ne $null) {
    # Split the content into lines
    $lines = $fileContent -split "`n"

    while ($true) {
        # Print the content in a numbered list
        for ($i = 0; $i -lt $lines.Length; $i++) {
            if (Get-Content $Game_Path'\installed_mods_do-not-delete.txt' | Select-String -Pattern $lines[$i]) {
                Write-Host -NoNewline ("[{0}] {1}" -f ($i + 1), $lines[$i])
                " (Installed)"
            } else {
                Write-Host -NoNewline ("[{0}] {1}" -f ($i + 1), $lines[$i])
                " (Not installed)"
            }
        }
	    ""
        # Prompt the user for input
        Write-Host "Type (exit) when you are finished"
        $userInput = Read-Host "Enter the mod you want to install/uninstall"
    
        # Validate user input
        if ($userInput -match 'exit') {
            Exit
        }
        if ($userInput -match '^\d+$' -and $userInput -ge 1 -and $userInput -le $lines.Length) {
            # Get the selected item
            $selectedItem = $lines[$userInput - 1]
			""
            Write-Host "Enter (yes) to confirm"
            if (Get-Content $Game_Path'\installed_mods_do-not-delete.txt' | Select-String -Pattern $selectedItem) {
                $confirmation = Read-Host "Uninstall mod $selectedItem"
                if ($confirmation -eq 'yes') {
					""
                    Write-Host "Uninstalling mod: $selectedItem"
                    ""
                    Write-Host "Downloading game file(s)..."

                    Download-GitHubFolder -Branch "main" -Folder "Default/$selectedItem" -Destination $Game_Path

                    # Work in progress

                    Write-Host "`nDone!`n`n"
                }
            } else {
                $confirmation = Read-Host "Install mod $selectedItem"
                if ($confirmation -eq 'yes') {
					""
                    Write-Host "Installing mod: $selectedItem"
                    ""
                    Write-Host "Downloading mod file(s)..."

                    Download-GitHubFolder -Branch "main" -Folder "Mods/$selectedItem" -Destination $Game_Path

                    Add-Content -Path $Game_Path'\installed_mods_do-not-delete.txt' -Value $selectedItem

                    Write-Host "`nDone!`n`n"
                }
            }
        }
        else {
            Write-Host "Invalid input. Please enter a valid number."
        }
    }
}