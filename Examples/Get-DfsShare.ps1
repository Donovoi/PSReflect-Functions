function Get-DfsShare
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Server = $env:COMPUTERNAME,

        [Parameter()]
        [ValidateSet(1, 2, 3, 4, 5, 6, 8, 9)]
        [String]
        $Level = 1
    )

    foreach($root in (NetDfsEnum -DfsName $Server -Level 300))
    {
        NetDfsEnum -DfsName $root.DfsName -Level $Level
    }
}