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