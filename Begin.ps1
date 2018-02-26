Get-ChildItem .\Modules | ForEach-Object { 
	Import-Module $_.FullName
}

# [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
Write-Host "Hello, cruel world!"