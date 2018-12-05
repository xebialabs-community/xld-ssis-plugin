#
# Copyright 2018 XEBIALABS
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
#######################

$ErrorActionPreference = "Stop"
$Script:dtutil = $null
$exitCode = @{
0="The utility executed successfully."
1="The utility failed."
4="The utility cannot locate the requested package."
5="The utility cannot load the requested package."
6="The utility cannot resolve the command line because it contains either syntactic or semantic errors"}

#######################
function Get-SqlVersion
{
    param($ServerInstance)

    Write-Host "Getting SQL Server version for [$ServerInstance]."

    #write-verbose "sqlcmd -S `"$ServerInstance`" -d `"master`" -Q `"SET NOCOUNT ON; SELECT SERVERPROPERTY('ProductVersion')`" -h -1 -W"

    $SqlVersion = sqlcmd -S "$ServerInstance" -d "master" -Q "SET NOCOUNT ON; SELECT SERVERPROPERTY('ProductVersion')" -h -1 -W

    if ($lastexitcode -ne 0) {
        Write-Host "SqlVersion could not be established [$SqlVersion]."
        Exit 1
    }
    else {
        $SqlVersion
    }

} #Get-SqlVersion

#######################
function Set-DtutilPath
{
    param($SqlVersion)

    $paths = [Environment]::GetEnvironmentVariable("Path", "Machine") -split ";"

    if ($SqlVersion -like "9*") {
        $Script:dtutil = $paths | where { $_ -like "*Program Files\Microsoft SQL Server\90\DTS\Binn\" }
        if ($Script:dtutil -eq $null) {
			Write-Host "SQL Server 2005 Version of dtutil not found."
			Exit 1
        }
    }
    elseif ($SqlVersion -like "10*") {
        $Script:dtutil = $paths | where { $_ -like "*Program Files\Microsoft SQL Server\100\DTS\Binn\" }
        if ($Script:dtutil -eq $null) {
			Write-Host "SQL Server 2008 or 2008R2 Version of dtutil not found."
			Exit 1
        }
    }
    elseif ($SqlVersion -like "11*") {
        $Script:dtutil = $paths | where { $_ -like "*Program Files\Microsoft SQL Server\110\DTS\Binn\" }
        if ($Script:dtutil -eq $null) {
			Write-Host "SQL Server 2012 Version of dtutil not found."
			Exit 1
        }
    }

    if ($Script:dtutil -eq $null) {
		Write-Host "Unable to find path to dtutil.exe. Verify dtutil installed."
		Exit 1
    }
    else {
        $Script:dtutil += 'dtutil.exe'
    }

} #Set-DtutilPath

#######################
function install-package
{
    param($DtsxFullName, $ServerInstance, $PackageFullName)

    $result = & $Script:dtutil /File "$DtsxFullName" /DestServer "$ServerInstance" /Copy SQL`;"$PackageFullName" /Quiet
    $result = $result -join "`n"

    if ($lastexitcode -ne 0) {
        Write-Host "Cannot install package at [$PackageFullName]."
        Exit 1
    }

} #install-package

#######################
function remove-package
{
    param($ServerInstance, $PackageFullName)

    $result = & $Script:dtutil /SourceServer "$ServerInstance" /SQL "$PackageFullName" /Delete /Quiet
    $result = $result -join "`n"

    if ($lastexitcode -ne 0) {
        Write-Host "Failed to remove package at [$PackageFullName]. Last exit code: [$lastexitcode]."
        Exit 1
    }

} #remove-package

#######################
function test-path
{
    param($ServerInstance, $FolderPath)

    #write-verbose "$Script:dtutil /SourceServer `"$ServerInstance`" /FExists SQL`;`"$FolderPath`""

    $result = & $Script:dtutil /SourceServer "$ServerInstance" /FExists SQL`;"$FolderPath"

    if ($lastexitcode -gt 1) {
        $result = $result -join "`n"
        throw "$result `n $($exitcode[$lastexitcode])"
    }

    if ($result -and $result[4] -eq "The specified folder exists.") {
        $true
    }
    else {
        $false
    }

} #test-path

#######################
function test-packagepath
{
    param($ServerInstance, $PackageFullName)

    #write-verbose "$Script:dtutil /SourceServer `"$ServerInstance`" /SQL `"$PackageFullName`" /EXISTS"

    $result = & $Script:dtutil /SourceServer "$ServerInstance" /SQL "$PackageFullName" /EXISTS

    if ($lastexitcode -eq 0 -and $result -and $result[4] -eq "The specified package exists.") {
        $true
    }
    else{
    	$false
    }

} #test-packagepath

#######################
function new-folder
{
    param($ServerInstance, $ParentFolderPath, $NewFolderName)

    $result = & $Script:dtutil /SourceServer "$ServerInstance" /FCreate SQL`;"$ParentFolderPath"`;"$NewFolderName"
    $result = $result -join "`n"

    if ($lastexitcode -ne 0) {
        Write-Host "Cannot create folder [$NewFolderName] for package [$PackageFullName]."
        Exit 1
    }

} #new-folder

#######################
function Get-FolderList
{
    param($PackageFullName)

    if ($PackageFullName -match '\\') {
        $folders = $PackageFullName  -split "\\"
        0..$($folders.Length -2) | foreach {
        new-object psobject -property @{
            Parent=$(if($_-gt 0) { $($folders[0..$($_ -1)] -join "\") } else { "\" })
            FullPath=$($folders[0..$_] -join "\")
            Child=$folders[$_]}}
    }

} #Get-FolderList
