function New-AzureCredentialVault {
    <#
    .SYNOPSIS
    Creates a new Azure Credential Vault
    
    .DESCRIPTION
    Creates a new  Azure Credential Vault.
    
    .PARAMETER SubscriptionID
    The Subscription ID of the subscription for your vault. You can find the subscription ID by running Get-AzureSubscription
    
    .PARAMETER Credential
    You need to supply valid credentials for the subscription. This is the only credentials you ever need to remember
    
    .PARAMETER ResourceGroupName
    Name of the resource group you keep the Key Vault in
    
    .PARAMETER Location
    The location for your resource group
    
    .PARAMETER StorageAccountName
    Name of the Storage Account for the Key Vault
    
    .PARAMETER VaultName
    The name of your Key Vault
    
    .EXAMPLE
    New-AzureCredentialVault -SubscriptionID 3ec04d29-9a0a-49ef-bdec-646f4575650e -Credential $credential -ResourceGroupName MyKeyVault -Location westeurope -StorageAccountName mykeyvaults -VaultName MyKeysForWork -Verbose
    
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0,HelpMessage="Supply SubscriptionID")]
        [guid]$SubscriptionID,
        [Parameter(Mandatory=$true, Position=1,HelpMessage="Supply valid credentials for the subscription")]
        [PSCredential]$Credential,
        [Parameter(Mandatory=$true, Position=2,HelpMessage="Supply the resource group name to use")]
        $ResourceGroupName,
        [Parameter(Mandatory=$true, Position=3,HelpMessage="Supply a location for the resource group")]
        $Location,
        [Parameter(Mandatory=$true, Position=4,HelpMessage="Supply the storage account name to use")]
        $StorageAccountName,
        [Parameter(Mandatory=$true, Position=5,HelpMessage="Supply the vault name")]
        $VaultName,
        $SkuName = 'Standard_LRS',
        $TableName = 'keylinks',
        $PartitionKey = 'Private'
        )
        begin {
            $VPreference = $VerbosePreference
            try {
                Write-Verbose "Logging in as $($Credential.UserName) to $SubscriptionID"
                Login-AzureRmAccount -Credential $Credential -SubscriptionId $SubscriptionID -ErrorAction stop | Out-Null
            }
            catch {
                Write-Warning -Message $_.Exception.Message
                continue
            }
            $CurrentSubscription = Get-AzureRmContext
            Write-Verbose "Current Subscription ID: $($CurrentSubscription.Subscription.SubscriptionId)"
        }
        process {

            try {
                # Next command loads the Azure module. Pausing Verbose
                $ResourceGroup = Get-AzureRmResourceGroup $ResourceGroupName -ErrorAction stop -Verbose SilentlyContinue
                Write-Verbose "Found Resource Group: $($ResourceGroup.ResourceGroupName)"
            }
            catch {
                try {
                    New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location | Out-Null
                    Write-Verbose -Message "$ResourceGroupName has been created"
                }
                catch {
                    Write-Warning -Message $_.Exception.Message
                    continue
                }
            }
            try {
                $StorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction Stop
                Write-Verbose "Found Storage Account: $($StorageAccount.StorageAccountName)"
            }
            catch {
                try {
                    $StorageAccount = New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -SkuName $SkuName  -Location $Location -ErrorAction Stop
                    Write-Verbose "$StorageAccountName has been created in $ResourceGroupName"
                }
                catch {
                    Write-Warning -Message $_.Exception.Message
                    continue
                    }
            }
            try {
                $KeyVault = Get-AzureRmKeyVault -ResourceGroupName $ResourceGroupName -VaultName $VaultName -ErrorAction Stop
                Write-Verbose "Found Key Vault: $($KeyVault.VaultName)"
            }
            catch {
                try {
                    New-AzureRmKeyVault -ResourceGroupName $ResourceGroupName -VaultName $VaultName -Location $Location -ErrorAction Stop | Out-Null
                    Write-Verbose "$VaultName has been created in $ResourceGroupName"
                }
                catch {
                    Write-Warning -Message $_.Exception.Message
                    continue                        
                }
            }
           
            try {
                $Table = Get-AzureStorageTable -Name $TableName -Context $StorageAccount.Context -ErrorAction Stop
                Write-Verbose -Message "Found table: $($Table.Name)"
            }
            catch {
                try {
                    New-AzureStorageTable -Name $TableName -Context $StorageAccount.Context -ErrorAction Stop | Out-Null
                    Write-Verbose -Message "$TableName has been created in $StorageAccountName"
                }
                catch {
                    Write-Warning -Message $_.Exception.Message
                    continue
                }
            }
        }
        end {

        }
}