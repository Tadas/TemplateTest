Import-Module $BuildRoot\BuildTools -Force

$ProjectName      = ($BuildRoot -split '\\')[-1]
$ArtifactPath     = "$BuildRoot\Artifacts"
$ArtifactFileName = "$ProjectName.zip"
$ArtifactFullPath = "$ArtifactPath\$ProjectName.zip"

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

		Get-ChildItem -File -Recurse $BuildRoot | Where-Object {
			(-not $_.FullName.Contains("\.vscode\")) -and
			(-not $_.FullName.Contains("\.git")) -and
			(-not $_.FullName.Contains("\Artifacts\")) -and
			(-not $_.FullName.Contains("\Tests\"))

		} | ForEach-Object {
			$DestinationPath = [System.IO.Path]::Combine(
				$TempPath,
				$_.FullName.Substring($BuildRoot.Length + 1)
			)
			Write-Host "`tMoving $($_.FullName)`r`n`t`t to $DestinationPath`r`n"

			# Makes sure the path is available
			New-Item -ItemType File -Path $DestinationPath -Force | Out-Null
			Copy-Item -LiteralPath $_.FullName -Destination $DestinationPath -Force
		}
		Compress-Archive -Path "$TempPath\*" -DestinationPath "$ArtifactPath\$ProjectName.zip" -Verbose -Force

	} finally {
		if(Test-Path -PathType Container -LiteralPath $TempPath) { Remove-Item -Recurse $TempPath -Force }
	}
}

task CreateReleaseAndUpload {
	$versionNumber = "0.2" # Get-NextVersionNumber
	$releaseNotes = "How to create release notes?"
	$gitHubApiKey = "47ccba14444c88d19b7dbcd75a210a4404e0282f"


	$releaseData = @{
		tag_name = $versionNumber
		target_commitish = git rev-parse HEAD;
		name = [string]::Format("{0}", $versionNumber);
		body = $releaseNotes;
		draft = $true;
		prerelease = $false;
	}

	$releaseParams = @{
		Uri = "https://api.github.com/repos/Tadas/$ProjectName/releases";
		Method = 'POST';
		Headers = @{
			Authorization = 'Basic {0}' -f ([System.Convert]::ToBase64String([char[]]"Tadas:$gitHubApiKey"))
		};
		ContentType = 'application/json';
		Body = (ConvertTo-Json $releaseData -Compress)
	}

	[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
	$result = Invoke-RestMethod @releaseParams

	Write-Host "Upload url →" $result.upload_url
	$uploadUri = $result.upload_url -replace '\{\?name,label\}', "?name=$ArtifactFileName"
	Write-Host $uploadUri

	$uploadParams = @{
		Uri = $uploadUri;
		Method = 'POST';
		Headers = @{
			Authorization = 'Basic {0}' -f ([System.Convert]::ToBase64String([char[]]"Tadas:$gitHubApiKey"))
		};
		ContentType = 'application/zip';
		InFile = $ArtifactFullPath
	}

	$result = Invoke-RestMethod @uploadParams
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