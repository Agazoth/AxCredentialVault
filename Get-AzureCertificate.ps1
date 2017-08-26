function Get-AzureCertificate
{
    <#
    .Synopsis
        Get a certificate from Azure Vault
    .DESCRIPTION
        Get a certificate from Azure Vault. Run Connect-AzureCredentialVault prior to running this command.
    .EXAMPLE
        Get-AzureCertificate -Name MyCert

    .EXAMPLE
        Get-AzureCertificate


    #>
    [CmdletBinding()]
    [Alias()]
    Param
    (
        # Path to PFX or PEM file
        [Parameter(Mandatory=$false, Position=0,HelpMessage="Supply a name for the certificate")]
        $Name,
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
    }
    Process
    {
        try{
            if ($Name){
                Write-Verbose "Getting $Name from $VaultName"
                Get-AzureKeyVaultCertificate -VaultName $VaultName -Name $Name -ErrorAction stop
            } else {
                Write-Verbose "Getting all certificates from $VaultName"
                Get-AzureKeyVaultCertificate -VaultName $VaultName -ErrorAction stop
            }
            
        }
        catch {
            Write-Warning -Message $_.Exception.Message
            continue
        }
        
    }
    End
    {
    }
}