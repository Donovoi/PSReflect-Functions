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
    
    try
    {
        $DfsRoot = NetDfsEnum -DfsName $Server -Level 300 -ErrorAction Stop
    }
    catch
    {
        $DfsRoot = NetDfsEnum -DfsName $Server -Level 200
    }
    finally
    {
        foreach($root in $DfsRoot)
        {
            NetDfsEnum -DfsName $root.DfsName -Level $Level
        }
    }
    
}