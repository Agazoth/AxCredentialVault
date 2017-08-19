function Remove-AzureCredential
{
    <#
    .Synopsis
        Removes credential set from Azure Keyvault 
    .DESCRIPTION
        Removes credential set from Azure Keyvault based on the guidelines in Test-VaultAccess
    .EXAMPLE
        Remove-AzureCredential AdminTest

        Confirm
        Are you sure you want to perform this action?
        Performing the operation "Remove-AzureCredential" on target "AdminTest".
        [Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "Y"):

    .EXAMPLE
        Remove-AzureCredential AdminTest -Confirm:$false -Verbose
        VERBOSE: Table entry found for AdminTest.
        VERBOSE: Performing the operation "Remove-AzureCredential" on target "AdminTest".
        VERBOSE: Deleting table entry for AdminTest ...
        VERBOSE: Deleting secret for AdminTest
    #>
    [CmdletBinding( SupportsShouldProcess=$true,ConfirmImpact="High")]
    [Alias()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true, Position=0)]
        $UserName,
        [Parameter(Mandatory=$true, Position=1,HelpMessage="Supply the resource group name to use")]
        $ResourceGroupName,
        [Parameter(Mandatory=$true, Position=2,HelpMessage="Supply the storage account name to use")]
        $StorageAccountName,
        [Parameter(Mandatory=$true, Position=3,HelpMessage="Supply the vault name")]
        $VaultName,
        $TableName,
        $PartitionKey
    )

    Begin
    {
        if (!$Global:VaultSA)
        {
            Connect-AzureCredentialVault -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -VaultName $VaultName
        }
        if ($force) {$ConfirmPreference='low'}
    }
    Process
    {
        $table = Get-AzureStorageTable -Name $TableName -Context $Global:VaultSA.Context
        $TableUser = Get-AzureStorageTableRowByColumnName -Table $table -ColumnName UserName -value $UserName -operator Equal
        if ($TableUser)
        {
            Write-Verbose "Table entry found for $UserName."
            # $ErrorActionPreference = "SilentlyContinue" # Because Get-AzureKeyVaultSecret creates a red error, if the entry does not exist
            try {
                $Secret = Get-AzureKeyVaultSecret -VaultName $VaultName -Name $TableUser.RowKey -ErrorAction Stop
            }
            catch {
                Write-Warning "No secret found for $UserName. Only the table entry will be removed."
            }
             
            if ($pscmdlet.ShouldProcess($UserName))
            {
               Write-Verbose "Deleting table entry for $UserName ..."
               $null = Remove-AzureStorageTableRow -table $Table -rowKey $TableUser.RowKey -partitionKey $TableUser.PartitionKey
               If ($Secret)
               {
                    Write-Verbose "Deleting secret for $UserName"
                    Remove-AzureKeyVaultSecret -VaultName $VaultName -Name $Secret.Name -Confirm:$false -force
               }
            }

        }
        else {Write-Warning "No table entry found for $UserName. Make sure casing is right and that the account exists."}
    }
    End
    {
    }
}