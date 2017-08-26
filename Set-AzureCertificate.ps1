function Set-AzureCertificate
{
    <#
    .Synopsis
        Add a certificate to Azure Vault
    .DESCRIPTION
        Add a certificate set to Azure Vault. Run Connect-AzureCredentialVault prior to running this command.
    .EXAMPLE
        Set-AzureCertificate -Path C:\mycert.pfx -Name MyCert
       
        cmdlet Set-AzureCertificate at command pipeline position 1
        Supply values for the following parameters:
        (Type !? for Help.)
        Password:**************


    .EXAMPLE
        $Password = Read-Host -AsSecureString
        Set-AzureCertificate -Path C:\mycert.pfx -Name MyCert -Password $Password


    #>
    [CmdletBinding()]
    [Alias()]
    Param
    (
        # Path to PFX or PEM file
        [Parameter(Mandatory=$true, Position=0)]
        $Path,
        [Parameter(Mandatory=$true, Position=1,HelpMessage="Supply a name for the certificate")]
        $Name,
        # Password needs to be a secure string
        [Parameter(Mandatory=$true, Position=2,HelpMessage="Supply the password as a System.Security.SecureString")]
        [alias("SecurePassword")]
        [Security.SecureString]$Password,
        [Parameter(Mandatory=$true, Position=3,HelpMessage="Supply the resource group name to use")]
        $ResourceGroupName,
        [Parameter(Mandatory=$true, Position=4,HelpMessage="Supply the storage account name to use")]
        $StorageAccountName,
        [Parameter(Mandatory=$true, Position=5,HelpMessage="Supply the vault name")]
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
    }
    Process
    {
        try{
            Import-AzureKeyVaultCertificate -VaultName $VaultName -Name $Name -FilePath $Path -Password $Password -ErrorAction stop | Out-Null
            Write-Verbose "$Name has been aded to $VaultName"
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