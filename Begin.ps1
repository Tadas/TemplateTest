Get-ChildItem .\Modules | ForEach-Object { 
	Import-Module $_.FullName
}

Write-Host "Hello, cruel world!"