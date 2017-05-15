#
# Script.ps1
#
configuration InstallADFS {
	param {
		[parameter(Mandatory)]
		[string]$MachineName,

		[parameter(Mandatory)]
		[string]$DomainName,

		[parameter(Mandatory)]
		[system.management.automation.pscredential]$admincreds,

		[int]$retryCount=20,
		[int]$retryintervalsec = 30
	}

	Import-DscResource -ModuleName xActiveDirectory,xPendingReboot

	[System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)"), $Admincreds.Password

	Node localhost

	LocalConfigurationManager {            
	   ActionAfterReboot = 'ContinueConfiguration'            
	   ConfigurationMode = 'ApplyOnly'            
	   RebootNodeIfNeeded = $true            
	}

	xWaitForADDomain DscForestWait {
		DomainName = $DomainName
		DomainUserCredential = $DomainCreds
		RetryCount = $retryCount
		RetryIntervalSec = $RetryIntervalSec
	}

	xComputer JoinDomain {
		Name = $MachineName
		DomainName = $DomainName
		Credential = $domainCreds
		DependsOn = '[xWaitForADDomain]DscForestWait'
	}

	xPendingReboot Reboot1 {
		Name = "RebootServer"
		DependsOn = "[xComputer]JoinDomain"
	}
	
	WindowsFeature installADFS {
		Ensure = "Present"
		Name = "ADFS-Federation"
		DependsOn = "[xPendingReboot]Reboot1"
	}
}