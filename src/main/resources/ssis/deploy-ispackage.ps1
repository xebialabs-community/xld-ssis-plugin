#
# Copyright 2018 XEBIALABS
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
$DtsxFullName = $deployed.file
$ServerInstance = $deployed.serverInstance
$PackageFullName = $deployed.packageFullName

try {
	# Get Sql Version
	$SqlVersion = Get-SqlVersion -ServerInstance $ServerInstance

	# Set Dtutil Path based on Sql Version
	Set-DtutilPath -SqlVersion $SqlVersion

	##Check for existing package
	if (test-packagepath $PackageFullName) {
		Write-Host "Removing old package [$PackageFullName] from [$ServerInstance]."
		remove-package -ServerInstance $ServerInstance -PackageFullName $PackageFullName
	}

	Write-Host "Deploying package [$PackageFullName] to [$ServerInstance]."

	#Create path if needed
	Get-FolderList -PackageFullName $PackageFullName |
	where { $(test-path -ServerInstance $ServerInstance -FolderPath $_.FullPath) -eq $false } |
	foreach { new-folder -ServerInstance $ServerInstance -ParentFolderPath $_.Parent -NewFolderName $_.Child }

	#Install SSIS Package
	install-package -DtsxFullName $DtsxFullName -ServerInstance $ServerInstance -PackageFullName $PackageFullName

	#Verify Package
	if(test-packagepath -ServerInstance $ServerInstance -PackageFullName $PackageFullName){
		Write-Host "Package [$PackageFullName] was found on [$ServerInstance]."
	}
	else{
		Write-Host "Package [$PackageFullName] not found on [$ServerInstance]."
		Exit 1
	}
}
catch {
    write-error "$_ `n $("Failed to install DtsxFullName {0} to ServerInstance {1} PackageFullName {2}" -f $DtsxFullName,$ServerInstance,$PackageFullName)"
}
