function Get-AzureCredential
{
    <#
    .Synopsis
        Gets a credential object from Azure Keyvault 
    .DESCRIPTION
        Gets a credential object to Azure Vault based on the guidelines in Test-VaultAccess
    .EXAMPLE
        Get-AzureCredential -UserName AdminTest

        UserName                      Password
        --------                      --------
        AdminTest System.Security.SecureString

    .EXAMPLE
        Get-AzureCredential -UserName AdminTest -ClearTextPassword
        WowThatWasStupid

    .EXAMPLE
        Get-AzureCredential -UserName AdminTest -ClearTextPassword | clip
        
        (Now the password is in the clipboard - ready for pasting)
    #>
    [CmdletBinding(DefaultParameterSetName = 'Specific')]
    [Alias()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true, Position=2,HelpMessage="Supply the resource group name to use")]
        $ResourceGroupName,
        [Parameter(Mandatory=$true, Position=3,HelpMessage="Supply the storage account name to use")]
        $StorageAccountName,
        [Parameter(Mandatory=$true, Position=4,HelpMessage="Supply the vault name")]
        $VaultName,
        [Parameter(ParameterSetName = 'Specific',Mandatory=$true, Position=0)]
        $UserName,
        [Parameter(ParameterSetName = 'Specific',Mandatory=$False, Position=1)]
        [switch]$ClearTextPassword,
        [Parameter(ParameterSetName = 'AllCredentials',Mandatory=$true, Position=0)]
        [Switch]$All,
        [Parameter(ParameterSetName = 'AllUserNames',Mandatory=$true, Position=0)]
        [Switch]$ListUserNames,
        $TableName,
        $PartitionKey
    )

    Begin
    {
        if (!$Global:VaultSA)
        {
            Connect-AzureCredentialVault -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -VaultName $VaultName 
        }
        $table = Get-AzureStorageTable -Name $TableName -Context $Global:VaultSA.Context
    }
    Process
    {
        $UserEntries = Get-AzureStorageTableRowAll -table $Table
        if ($UserName)
        {
            $Users = $UserEntries | Where-Object {$_.UserName -eq $UserName}
            if ($UserName -and $Users){Write-Verbose "Table entry found for $UserName."}
            else {Write-Warning "No table entry found for $UserName"}

        }
        if ($All)
        {
            $Users = $UserEntries
        }
        if ($ListUserNames){
            $UserEntries.UserName
            continue
        }
        Foreach ($User in $Users)
        {
            $Secret = Get-AzureKeyVaultSecret -VaultName $VaultName -Name $User.RowKey
            if ($Secret)
            {
                if ($ClearTextPassword)
                {
                    $Secret.SecretValueText
                }
                else
                {
                    New-Object -typename System.Management.Automation.PSCredential -argumentlist $User.UserName,$Secret.SecretValue
                }
            }
            Else {Write-Warning "No Secret found for $($User.UserName)"}
        }
    }
    end {
    }
}