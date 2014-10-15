$ServerInstance = $deployed.serverInstance
$PackageFullName = $deployed.packageFullName

try {
	# Get Sql Version
	$SqlVersion = Get-SqlVersion -ServerInstance $ServerInstance

	# Set Dtutil Path based on Sql Version
	Set-DtutilPath -SqlVersion $SqlVersion
	
    Write-Host "Removing package [$PackageFullName] on [$ServerInstance]."
    remove-package  -ServerInstance $ServerInstance -PackageFullName $PackageFullName
    
    #Verify Package
    if(test-packagepath -ServerInstance $ServerInstance -PackageFullName $PackageFullName){
    	Write-Host "Package [$PackageFullName] still exists on [$ServerInstance]."
    	Exit 1
    }
    else{
    	Write-Host "Package [$PackageFullName] no longer found on [$ServerInstance]."
    	Exit 0
    }
}
catch {
    write-error "$_ `n $("Failed to remove [$PackageFullName] from [$ServerInstance]")"
}