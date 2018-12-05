#
# Copyright 2018 XEBIALABS
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
#first check Powershell compatibility
if($PSVersionTable.PSVersion.major -lt 3) {
    Write-Error "This script requires Powershell version 3 or higher to run"
    Exit
}

#Variables
$fullDacPacPath = $deployed.file
$SqlServer      = $deployed.serverName
$TargetDatabase = $deployed.targetDatabase
$TrustedConnection = $deployed.sourceTrustServerCertificate
$EncryptConnection  = $deployed.sourceEncryptConnection

$assemblylist =
"Microsoft.SqlServer.Smo",
"Microsoft.SqlServer.SMOEnum",
"Microsoft.SqlServer.Management.Smo",
"Microsoft.SqlServer.Management.SMOEnum",
"Microsoft.SqlServer.Dac",
"Microsoft.SqlServer.Dac.DacServices",
"Microsoft.SqlServer.Management.Dac",
"Microsoft.SqlServer.Management.DacEnum"

foreach ($asm in $assemblylist)
{
    $asm = [System.Reflection.Assembly]::LoadWithPartialName($asm)
}

try
{
    add-type -path $deployed.dacDllPath
}
catch
{
    Write-Host -foreground yellow "Exception";
    $Error | format-list -force
    Write-Host -foreground red $Error[0].Exception.LoaderExceptions;
    Exit 1
}
Write-Host "Deploying the DB with the following settings"
Write-Host "SQL Server: $SqlServer"
Write-Host "Target Database: $TargetDatabase"

$connectionString = "server=$SqlServer;Trusted_Connection=$TrustedConnection;Encrypt=$EncryptConnection"
if($deployed.userName -and $deployed.password){
    Write-Host "Using provided credentials for user $($deployed.userName)."
    $connectionString = "server=$SqlServer;Trusted_Connection=$TrustedConnection;Encrypt=$EncryptConnection;User Id=$($deployed.userName);Password=$($deployed.password)"
}

$d = new-object Microsoft.SqlServer.Dac.DacServices ($connectionString)

# register events, if you want 'em
register-objectevent -in $d -eventname Message -source "msg" -action { out-host -in $Event.SourceArgs[1].Message.Message } | Out-Null

$ErrorActionPreference = "Continue" #To force script to run to completion

# Load dacpac from file & deploy to database named pubsnew
$dp = [Microsoft.SqlServer.Dac.DacPackage]::Load($fullDacPacPath)
$DeployOptions = new-object Microsoft.SqlServer.Dac.DacDeployOptions
$DeployOptions.IncludeCompositeObjects   = $deployed.includeCompositeObjects
$DeployOptions.IgnoreFileSize            = $deployed.ignoreFileSize
$DeployOptions.IgnoreFilegroupPlacement  = $deployed.ignoreFilegroupPlacement
$DeployOptions.IgnoreFileAndLogFilePath  = $deployed.ignoreFileAndLogFilePath
$DeployOptions.AllowIncompatiblePlatform = $deployed.allowIncompatiblePlatform
$DeployOptions.BlockOnPossibleDataLoss   = $deployed.blockOnPossibleDataLoss
$DeployOptions.DropObjectsNotInSource    = $deployed.dropObjectsNotInSource
$DeployOptions.GenerateSmartDefaults     = $deployed.generateSmartDefaults
$DeployOptions.IncludeTransactionalScripts = $deployed.includeTransactionalScripts


$d.Deploy($dp, $TargetDatabase, $true, $DeployOptions)


# clean up event
unregister-event -source "msg"

$srv = new-Object Microsoft.SqlServer.Management.Smo.Server($SqlServer)
if ($srv.Databases[$TargetDatabase] -ne $null){
    Write-Host "Database $targetDatabase successfully created."
    Exit 0
}
else{
    Write-Error "Database $targetDatabase was not created."
    Exit 1
}
