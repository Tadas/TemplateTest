$ArtifactPath = "$BuildRoot\Artifacts"

task . InstallDependencies, Analyze, Test, Clean, Build

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
		ExcludeRule = 'PSAvoidUsingWriteHost'
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
	if (Test-Path -Path $ArtifactPath) {
		Remove-Item "$ArtifactPath/*" -Recurse -Force
	}
	New-Item -ItemType Directory -Path $ArtifactPath -Force | Out-Null
}

task Build {
	try {
		$TempPath = New-TemporaryFolder
		$ModuleName = ($BuildRoot -split '\\')[-1]

		Get-ChildItem -File -Recurse $BuildRoot -Exclude ".git*" | ForEach-Object {
			
			$DestinationPath = [System.IO.Path]::Combine(
				$TempPath,
				$_.FullName.Substring($BuildRoot.Length + 1)
			)
			Write-Host "`tMoving $($_.FullName)`r`n`t`t to $DestinationPath`r`n"

			# Makes sure the path is available
			New-Item -ItemType File -Path $DestinationPath -Force | Out-Null
			Copy-Item -LiteralPath $_.FullName -Destination $DestinationPath -Force
		}
		Compress-Archive -Path "$TempPath\*" -DestinationPath "$ArtifactPath\$ModuleName.zip" -Verbose -Force
	
	} finally {
		if(Test-Path -PathType Container -LiteralPath $TempPath) { Remove-Item -Recurse $TempPath -Force }
	}
}

task PushRelease {
}

function New-TemporaryFolder {
	do {
		$TemporaryPath = [System.IO.Path]::Combine(
			[System.IO.Path]::GetTempPath(),
			[System.IO.Path]::GetFileNameWithoutExtension([System.IO.Path]::GetRandomFileName())
		)

	} while (Test-Path -PathType Container -LiteralPath $TemporaryPath)
	New-Item -ItemType Container -Path $TemporaryPath
}