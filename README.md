AxCredentialVault
=================

This module lest you create a Password Vault in your Azure subscription for safe keeping and delegation of your credential sets.

Functionality:
* Create a new credential vault in your Azure subscription
* Connect to your credential vault
* Add credential sets to your vault
* Retrieve credential sets from your vault
* Remove credential sets from your vault

#Instructions

```powershell
# One time setup
    # Download the repository
    # Unblock the zip
    # Extract the AxCredentialVault folder to a module path (e.g. $env:USERPROFILE\Documents\WindowsPowerShell\Modules\)

    #Simple alternative, if you have PowerShell 5, or the PowerShellGet module:
        Install-Module AxCredentialVault

# Import the module.
    Import-Module AxCredentialVault    #Alternatively, Import-Module \\Path\To\PSExcel

# Get commands in the module
    Get-Command -Module AxCredentialVault

# Get help for a command
    Get-Help Connect-AzureCredentialVault -Full



```
