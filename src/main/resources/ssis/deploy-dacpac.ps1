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
$DeployOptions.ExcludeObjectTypes        = new[]
{
    ObjectType.DatabaseTriggers, ObjectType.Permissions, ObjectType.RoleMembership,
    ObjectType.Users, ObjectType.Rules
}

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