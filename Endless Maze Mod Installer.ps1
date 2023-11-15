"Endless Maze Mod Installer"
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

    # Print the content in a numbered list
    for ($i = 0; $i -lt $lines.Length; $i++) {
        Write-Host ("[{0}] {1}" -f ($i + 1), $lines[$i])
    }
	""
    # Prompt the user for input
    $userInput = Read-Host "Enter the mod you want to install"
	
    # Validate user input
    if ($userInput -match '^\d+$' -and $userInput -ge 1 -and $userInput -le $lines.Length) {
        # Get the selected item
        $selectedItem = $lines[$userInput - 1]
        Write-Host "Installing mod: $selectedItem"
    }
    else {
        Write-Host "Invalid input. Please enter a valid number."
    }
}


pause