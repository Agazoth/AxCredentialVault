function Set-AzureCredential
{
    <#
    .Synopsis
        Add a credential set to Azure Vault
    .DESCRIPTION
        Add a credential set to Azure Vault based on the guidelines in Test-VaultAccess
    .EXAMPLE
        Set-AzureCredential -UserName Admin
       
        cmdlet Set-AzureCredential at command pipeline position 1
        Supply values for the following parameters:
        (Type !? for Help.)
        Password:**************


    .EXAMPLE
        $Password = Read-Host -AsSecureString
        Set-AzureCredential -UserName Admin -Password $Password

    .EXAMPLE
        Set-AzureCredential -UserName AdminTest -Verbose
        
        cmdlet Set-AzureCredential at command pipeline position 1
        Supply values for the following parameters:
        (Type !? for Help.)
        Password: ****
        VERBOSE: Setting userentry for AdminTest
        VERBOSE: Setting Key Vault Secret for AdminTest
    
    .EXAMPLE
        Set-AzureCredential AdminTest

        cmdlet Set-AzureCredential at command pipeline position 1
        Supply values for the following parameters:
        (Type !? for Help.)
        Password: ********
        WARNING: Credentials for AdminTest exists. Please use -Force switch to update

    .EXAMPLE
        $Password = Read-Host -AsSecureString
        **********
        Set-AzureCredential -UserName AdminTest -Password $Password -Force
    #>
    [CmdletBinding()]
    [Alias()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true, Position=0)]
        $UserName,

        # Password needs to be a secure string
        [Parameter(Mandatory=$true, Position=1,HelpMessage="Supply the password as a System.Security.SecureString")]
        [alias("SecurePassword")]
        [Security.SecureString]$Password,
        [Parameter(Mandatory=$true, Position=2,HelpMessage="Supply the resource group name to use")]
        $ResourceGroupName,
        [Parameter(Mandatory=$true, Position=3,HelpMessage="Supply the storage account name to use")]
        $StorageAccountName,
        [Parameter(Mandatory=$true, Position=4,HelpMessage="Supply the vault name")]
        $VaultName,
        $TableName,
        $PartitionKey,
        [Switch]$Force
    )

    Begin
    {
        if (!$Global:VaultSA)
        {
            Connect-AzureCredentialVault -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -VaultName $VaultName
        }
        $CurrentSubscriptionUser = Get-AzureRmContext | Select-Object -ExpandProperty Account | Select-Object -ExpandProperty Id
        $Table = Get-AzureStorageTable -Name $TableName -Context $Global:VaultSA.Context
    }
    Process
    {
        
        # Part 0: Check table for existing password
        $UserEntry = Get-AzureStorageTableRowByColumnName -table $table -columnName UserName -value $UserName -operator equal
        if ($UserEntry -and !$Force)
        {
            Write-warning "Credentials for $UserName exists. Please use -Force switch to update"
            continue
        }
        # Part 1: Set table entry
        if (!$UserEntry)
        {
            Write-Verbose "Setting userentry for $UserName"
            $Guid = [guid]::NewGuid().tostring()
            Add-StorageTableRow -table $Table -partitionKey $PartitionKey -rowKey $Guid -property @{UserName=$UserName;DateCreated=$(Get-date).tostring();Creator=$CurrentSubscriptionUser} | Out-Null
            $UserEntry = Get-AzureStorageTableRowByColumnName -table $Table -columnName UserName -value $UserName -operator equal
            $Force = $True
        }
        if ($Force)
        {
            Write-Verbose "Setting Key Vault Secret for $UserName"
            Set-AzureKeyVaultSecret -VaultName $VaultName -Name $UserEntry.RowKey -SecretValue $Password | Out-Null
        }
    }
    End
    {
    }
}