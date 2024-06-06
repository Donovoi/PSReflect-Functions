function Collect-ShareInfo
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [String]
        $DomainName
    )

    # Replace contoso.com with the Active Directory Domain's FQDN (contoso.com) or NetBIOS domain name (FABRIKAM)
    Write-Verbose -Message "Enumerating DFS Shares"
    Write-Verbose -Message "This requires the caller belong to the Domain Users group"
    Get-DfsShare -DomainName $DomainName | ConvertTo-Json -Compress | Out-File -FilePath .\dfs-db-shares.json

    # Generates a list of computers in the domain
    # This can be replaced if there is a different preferred way of referencing "target systems"
    Write-Verbose -Message "Enumerating Domain Computers"
    $Computers = ([adsisearcher]“objectcategory=computer”).FindAll().Properties.dnshostname
 
    # Enumerates traditional SMB File Shares on all domain computers
    # Information Level 502 is necessary to collect security descriptors for the shares
    # Results will be output to a file called "shares.json" on the Desktop of the current user (this can be changed)
    Write-Verbose -Message "Enumerating Traditional Shares"
    Write-Verbose -Message "This requires the caller belong to the Administrators or Power Users groups"
    NetShareEnum -ComputerName $Computers -Level 502 | ConvertTo-Json -Compress | Out-File .\shares.json
}
