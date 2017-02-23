############################################
## ----- DFSR Active File Monitor
##
## 2017 - Nial Francis
############################################

<#
	.SYNOPSIS
	Monitors specified replicated folders.
	.DESCRIPTION
	DFSR Active File Monitor

	Monitors specified RGs (via the source/destination directories) and reports the status of replication of a test file.

	It is recommended to use a dedicated directory with this script or the cleanup option.

	Usually this type of monitor only needs to be run:
	max. 1/hour
	min. 1/day
	.EXAMPLE
	DFSRBruteForce.ps1 -Directories @{'C:\temp'='\\server2\temp';'\\server2\d$\Shares\test'='\\server3\d$\Shares\test'}
	Where the key is a local/UNC path to a replicated folder and the value is the UNC path to the replicated copy.
	.PARAMETER Directories
	Hash of local=remote directories where the file will be created then read. (Check the example)
	.PARAMETER ReplWait
	Time to wait for the check file to replicate in seconds. Default is 50.
	.PARAMETER Cleanup
	Switch to remove check files after scan.
	.OUTPUTS
	User configurable by creating a return function and editing OUTPUT CONFIGURATION.
	
	By default it returns a PRTG compatible EXE sensor response.
	On error, it returns the failed folder name.
#>

[cmdletbinding()]
Param(
  [ValidateNotNull()] [hashtable]$Directories,
  [int]$ReplWait = 50,
  [switch]$Cleanup
)

$errors = @()
$filename = "$(Get-Date -Format 'yymmdd-HHmmss').drt"
$filecont = "Time of file generation = $([DateTimeOffset]::Now.ToUnixTimeSeconds())"

############################################
#####    FUNCTIONS
############################################

function ReturnText ($message) {
	return $message
}

############################################
#####    MAIN
############################################

# CREATE

foreach ($rf in $directories.GetEnumerator()) {
	$filecont | Out-File -FilePath "$($rf.key)\$filename"
}

Start-Sleep $ReplWait

# CHECK

foreach ($rf in $directories.GetEnumerator()) {
	$cont = Get-Content -Path "$($rf.value)\$filename" -ea SilentlyContinue
	
	if (!($cont -eq $filecont)) {
		$errors += $rf.key
	}
	
	if ($Cleanup) { Remove-Item -Path "$($rf.key)\$filename" }
}

############################################
#####    OUTPUT CONFIGURATION
############################################

if ($errors.count -eq 0) {
	# SUCCESS
	
	ReturnText("0:All checks passed")
} else {
	# FAIL
	
	ReturnText("-1:Failed $($errors.split('\')[-1] -join ', ')")
}