# XL Deploy SSIS plugin

[![Build Status][xld-ssis-plugin-travis-image] ][xld-ssis-plugin-travis-url]
[![License: MIT][xld-ssis-plugin-license-image]][xld-ssis-plugin-license-url]
![Github All Releases][xld-ssis-plugin-downloads-image]
[![Codacy Badge][xld-ssis-plugin-codacy-image] ][xld-ssis-plugin-codacy-url]
[![Code Climate][xld-ssis-plugin-code-climate-image] ][xld-ssis-plugin-code-climate-url]

[xld-ssis-plugin-travis-image]: https://travis-ci.org/xebialabs-community/xld-ssis-plugin.svg?branch=master
[xld-ssis-plugin-travis-url]: https://travis-ci.org/xebialabs-community/xld-ssis-plugin
[xld-ssis-plugin-license-image]: https://img.shields.io/badge/License-MIT-yellow.svg
[xld-ssis-plugin-license-url]: https://opensource.org/licenses/MIT
[xld-ssis-plugin-downloads-image]: https://img.shields.io/github/downloads/xebialabs-community/xld-ssis-plugin/total.svg
[xld-ssis-plugin-codacy-image]: https://api.codacy.com/project/badge/Grade/c22530fe75554e8283856e4a5eeed0c5
[xld-ssis-plugin-codacy-url]: https://www.codacy.com/app/joris-dewinne/xld-ssis-plugin
[xld-ssis-plugin-code-climate-image]: https://api.codeclimate.com/v1/badges/ea54a1897681154b8ad4/maintainability
[xld-ssis-plugin-code-climate-url]: https://codeclimate.com/github/xebialabs-community/xld-ssis-plugin/maintainability


# Overview

This document describes the functionality provided by the SSIS plugin.

See the **XL Deploy Reference Manual** for background information on XL Deploy and deployment concepts.

## Features

* Deploys SSIS (dts) packages to an [MSSQLClient container](https://docs.xebialabs.com/xl-deploy/8.2.x/databasePluginManual.html#sqlmssqlclient)
* Deploys SSIS (ispac) projects to an [MSSQLClient container](https://docs.xebialabs.com/xl-deploy/8.2.x/databasePluginManual.html#sqlmssqlclient)
* Deploys database packages (dacpac) to an [MSSQLClient container](https://docs.xebialabs.com/xl-deploy/8.2.x/databasePluginManual.html#sqlmssqlclient)
* Compatible with SQL Server 2005 and up (SQL Server 2012 required for project deployments)

# Requirements

* **XL Deploy requirements**
	* **Deployit**: version 3.9+
	* **XL Deploy**: version 4.0+
	* Requires the database plugin to be installed (see DEPLOYIT_SERVER_HOME/available-plugins)

# Installation

Place the plugin JAR file into your `DEPLOYIT_SERVER_HOME/plugins` directory.

# Usage

## An SSIS package is bundled in a single dtsx file.

The plugin copies the provided dtsx file (the artefact) to the container's server. From there is determines the version of SQL Server and uses that to determine the location of the dtutil utility.
The dtsx package is deployed using the SQL Server dtutil utility to the provided server and path.

## A SSIS project is bundled in a single ispac file

The plugin copies the provided ipac file (the artefact) to the container's server. On the server it connects to the SSIS instance. In the SSIS instance it tries to connect to the provided SSIS catalog (default value is SSISDB). If the catalog isn't shared it's removed. If no catalog is found a new one is created with the provided password.
A folder is created with the provided name (if a folder with that name is found it is used).
Within the folder:

* The project with the given projectName is created, if a project with that name is found it is first removed.
* The sepcified environments are created, if an environment exists it is first removed.
* Specified environment variables are created and if specified a project parameter is created with a reference
* The environment is referenced to the project

When the ISProject is destroyed the catalog is removed if it is not shared. Otherwise only project & environments are removed. If the folderName is empty after project & environment removal it is also removed.

## A database package is bundled in a single dacpac file.

The plugin copies the provided *dacpac* file (the artefact) to the container's server. Where it is deployed using powershell. Requires powershell v3, which is checked by the script. It also requires a trusted connection, so native winrm (*available when XL Deploys runs on windows machine*) or a winrs proxy with credential delegation is needed.
You might need to install the following on the target container you're running the powershell:

* [DacFramework.msi](https://www.microsoft.com/en-us/download/details.aspx?id=42293)
* [SQLDom.msi](https://www.microsoft.com/en-us/download/details.aspx?id=42295)
* [SQLSysClrTypes.msi](https://www.microsoft.com/en-us/download/details.aspx?id=42295)

# References

* **dtsx packages**
	* [Run an SSIS package with PowerShell](https://docs.microsoft.com/en-us/sql/integration-services/ssis-quickstart-run-powershell?view=sql-server-2017)
	* [Execute an SSIS Package from Powershell](https://gallery.technet.microsoft.com/scriptcenter/Execute-an-SSIS-Package-1105aad4)
* **ispac package**
	* [Deploy an SSIS project with PowerShell](https://docs.microsoft.com/en-us/sql/integration-services/ssis-quickstart-deploy-powershell?view=sql-server-2017)
	* [Publish to SSIS Catalog using PowerShell](https://www.mattmasson.com/2012/06/publish-to-ssis-catalog-using-powershell/)
* **dacpac packages**
	* [Microsoft.SqlServer.Dac Namespace](https://docs.microsoft.com/en-us/dotnet/api/microsoft.sqlserver.dac?view=sql-dacfx-140.3881.1)
	* [Publishing DACPACs with Powershell](https://social.msdn.microsoft.com/forums/sqlserver/en-US/7d01a0cf-1a1a-4692-aaee-10eda7b3553b/publishing-dacpacs-with-powershell)
	* [Data-tier Applications](https://docs.microsoft.com/en-us/sql/relational-databases/data-tier-applications/data-tier-applications?view=sql-server-2017)
