#
# Copyright 2018 XEBIALABS
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
#Variables
$SqlServer      = $deployed.serverName
$TargetDatabase = $deployed.targetDatabase

# Load the required assemblies
$assemblylist =
"Microsoft.SqlServer.Smo",
"Microsoft.SqlServer.SMOEnum",
"Microsoft.SqlServer.Management.Smo",
"Microsoft.SqlServer.Management.SMOEnum"

foreach ($asm in $assemblylist)
{
    $asm = [System.Reflection.Assembly]::LoadWithPartialName($asm) | Out-Null
}

$srv = new-Object Microsoft.SqlServer.Management.Smo.Server($SqlServer)
if ($srv.Databases[$TargetDatabase] -ne $null)
 {
    $srv.KillAllProcesses($TargetDatabase)
    $srv.Databases[$TargetDatabase].drop()
    Write-Host "Database $TargetDatabase successfully dropped."
}
 else {
    Write-Host "Nothing to be done. Database $TargetDatabase not found."
 }
