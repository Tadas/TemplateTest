$ArtifactPath = "$BuildRoot\Artifacts"

task . InstallDependencies, Analyze, Test, Clean, Archive

task InstallDependencies {
	Install-Module Pester -Scope CurrentUser 
	Install-Module PSScriptAnalyzer -Scope CurrentUser
}

task Analyze {
	$scriptAnalyzerParams = @{
		Path = "$BuildRoot\Begin.ps1"
		Severity = @('Error', 'Warning')
		Recurse = $true
		Verbose = $false
		# ExcludeRule = 'PSUseDeclaredVarsMoreThanAssignments'
	}
	
	$Results = Invoke-ScriptAnalyzer @scriptAnalyzerParams

	if ($Results) {
		$Results | Format-Table
		throw "One or more PSScriptAnalyzer errors/warnings where found."
	}
}

task Test {
	$invokePesterParams = @{
		Strict = $true
		PassThru = $true
		Verbose = $false
		EnableExit = $false
	}

	# Publish Test Results as NUnitXml
	$testResults = Invoke-Pester @invokePesterParams;

	$numberFails = $testResults.FailedCount
	assert($numberFails -eq 0) ('Failed "{0}" unit tests.' -f $numberFails)
}

task Clean {
	$Artifacts = $ArtifactPath
	
	if (Test-Path -Path $Artifacts) {
		Remove-Item "$ArtifactPath/*" -Recurse -Force
	}

	New-Item -ItemType Directory -Path $Artifacts -Force
}

task Archive {
	$Artifacts = $ArtifactPath
	$ModuleName = ($BuildRoot -split '\\')[-1]
	Compress-Archive  -LiteralPath ".\Begin.ps1" -DestinationPath "$Artifacts\$ModuleName.zip"
	Compress-Archive -Path .\Modules -Update -DestinationPath "$Artifacts\$ModuleName.zip"
	# Compress-Archive -Path .\Examples -Update -DestinationPath "$Artifacts\$ModuleName.zip"
}