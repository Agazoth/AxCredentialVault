function Connect-AzureCredentialVault {
    <#
    .SYNOPSIS
    Connects to your Azure Credential Vault
    
    .DESCRIPTION
    Connects to your Azure Credential Vault and sets up the commandlets in the module with the parameters supplied. Once you run this command, the other cmdlets in the module have the settings they need to handle the credentials.
    
    .PARAMETER SubscriptionID
    The Subscription ID of the subscription you keep your vault in. You can find the subscription ID by running Get-AzureSubscription
    
    .PARAMETER Credential
    You need to supply valid credentials for the subscription. This is the only credentials you ever need to remember
    
    .PARAMETER ResourceGroupName
    Name of the resource group you keep the Key Vault in
    
    .PARAMETER StorageAccountName
    Name of the Storage Account for the Key Vault
    
    .PARAMETER VaultName
    The name of your Key Vault
    
    .EXAMPLE
    $Credential = Get-Credential
    Connect-AzureCredentialVault -SubscriptionID dbf3f17f-2635-4a36-80f8-0c3b6ff0b715
         -Credential $Credential
         -ResourceGroupName MyRG
         -StorageAccountName MySA
         -VaultName MyVault

    .EXAMPLE
    Connect-AzureCredentialVault -SubscriptionID dbf3f17f-2635-4a36-80f8-0c3b6ff0b715
         -ResourceGroupName MyRG
         -StorageAccountName MySA
         -VaultName MyVault
    
    cmdlet Connect-AzureCredentialVault at command pipeline position 1
    Supply values for the following parameters:
    User: MyUserName@contoso.com
    Password for user MyUserName@contoso.com: ************

    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0,HelpMessage="Supply SubscriptionID")]
        [guid]$SubscriptionID,
        [Parameter(Mandatory=$true, Position=1,HelpMessage="Supply valid credentials for the subscription")]
        [PSCredential]$Credential,
        [Parameter(Mandatory=$true, Position=2,HelpMessage="Supply the resource group name to use")]
        $ResourceGroupName,
        [Parameter(Mandatory=$true, Position=3,HelpMessage="Supply the storage account name to use")]
        $StorageAccountName,
        [Parameter(Mandatory=$true, Position=4,HelpMessage="Supply the vault name")]
        $VaultName,
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
        try {
            # Next command loads the Azure module. Pausing Verbose
            $VerbosePreference = 'SilentlyContinue'
            $ResourceGroup = Get-AzureRmResourceGroup $ResourceGroupName -ErrorAction stop
            $VerbosePreference = $VPreference
            Write-Verbose "Found Resource Group: $($ResourceGroup.ResourceGroupName)"
        }
        catch {
            Write-Warning -Message $_.Exception.Message
            continue
        }
        try {
            $StorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -ErrorAction Stop | Where-Object {$_.StorageAccountName -eq $StorageAccountName}
            Write-Verbose "Found Storage Account: $($StorageAccount.StorageAccountName)"
        }
        catch {
            Write-Warning -Message $_.Exception.Message
            continue
        }
        try {
            $KeyVault = Get-AzureRmKeyVault -ResourceGroupName $ResourceGroupName -VaultName $VaultName -ErrorAction Stop
            Write-Verbose "Found Key Vault: $($KeyVault.VaultName)"
        }
        catch {
            Write-Warning -Message $_.Exception.Message
            continue
        }
       
        try {
            $Table = Get-AzureStorageTable -Name $TableName -Context $StorageAccount.Context
            Write-Verbose "Found table: $($Table.Name)"
        }
        catch {
            Write-Warning -Message $_.Exception.Message
            continue
        }
        
    }
    
    process {
        $Cmdlets = 'Get-AzureCredential','Set-AzureCredential','Remove-AzureCredential','Set-AzureCertificate','Get-AzureCertificate'
        $PSParameters = 'ResourceGroupName','StorageAccountName','VaultName','TableName','PartitionKey'
        Foreach ($Cmdlet in $Cmdlets)
        {
            foreach ($ParameterName in $PSParameters)
            {
                $Value = Get-Variable $ParameterName | Select-Object -expand value
                Write-Verbose "Setting $ParameterName to $Value on $Cmdlet"
                $Global:PSDefaultParameterValues["$Cmdlet : $ParameterName"] = $Value
            }
        }
        $Global:VaultSA = $StorageAccount
    }
    
    end {
    }
}