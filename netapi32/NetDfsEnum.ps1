function NetDfsEnum {
    <#
    .SYNOPSIS

    Enumerates the Distributed File System (DFS) namespaces hosted on a server or DFS links of a namespace hosted by a server.

    .DESCRIPTION

    This function will execute the NetShareEnum Win32API call to query
    a given host for open shares. This is a replacement for "net share \\hostname".

    .PARAMETER ComputerName

    Specifies the hostname to query for shares (also accepts IP addresses).
    Defaults to 'localhost'.

    .PARAMETER Level

    Specifies the level of information to query from NetShareEnum.
    Default of 1. Affects the result structure returned.

    .NOTES

    Author: Jared Atkinson (@jaredcatkinson)
    License: BSD 3-Clause  
    Required Dependencies: PSReflect, DFS_INFO_1, DFS_INFO_2, DFS_INFO_3, DFS_INFO_5, DFS_VOLUME_STATE
    Optional Dependencies: None

    (func netapi32 NetDfsEnum ([Int]) @(
        [String],                 # [in]      LPWSTR  DfsName,
        [Int32],                  # [in]      DWORD   Level,
        [Int32],                  # [in]      DWORD   PrefMaxLen,
        [IntPtr].MakeByRefType(), # [out]     LPBYTE  *Buffer,
        [Int32].MakeByRefType(),  # [out]     LPDWORD EntriesRead,
        [Int32].MakeByRefType()   # [in, out] LPDWORD ResumeHandle
    ) -EntryPoint NetDfsEnum)

    .LINK

    https://learn.microsoft.com/en-us/windows/win32/api/lmdfs/nf-lmdfs-netdfsenum

    .EXAMPLE
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [ValidateNotNullOrEmpty()]
        [String]
        $DfsName,

        [ValidateSet(1, 2, 3, 5, 6, 8, 9)]
        [String]
        $Level = 1
    )

    BEGIN {}

    PROCESS {

        $Buffer = [IntPtr]::Zero
        $EntriesRead = 0
        $TotalRead = 0
        $ResumeHandle = 0

        # get the raw share information
        $Result = $Netapi32::NetDfsEnum($DfsName, $Level, -1, [ref]$Buffer, [ref]$EntriesRead, [ref]$ResumeHandle)

        # locate the offset of the initial intPtr
        $Offset = $Buffer.ToInt64()

        # work out how much to increment the pointer by finding out the size of the structure
        $Increment = Switch ($Level) {
            1   { $DFS_INFO_1::GetSize() }
            2   { $DFS_INFO_2::GetSize() }
            3   { $DFS_INFO_3::GetSize() }
            5   { $DFS_INFO_5::GetSize() }
            6   { $DFS_INFO_6::GetSize() }
            7   { $DFS_INFO_7::GetSize() }
            8   { $DFS_INFO_8::GetSize() }
            9   { $DFS_INFO_9::GetSize() }
            100 { $DFS_INFO_100::GetSize() }
            101 { $DFS_INFO_101::GetSize() }
            102 { $DFS_INFO_102::GetSize() }
            150 { $DFS_INFO_150::GetSize() }
        }

        # 0 = success
        if (($Result -eq 0) -and ($Offset -gt 0)) {

            # parse all the result structures
            for ($i = 0; ($i -lt $EntriesRead); $i++) {
                # create a new int ptr at the given offset and cast the pointer as our result structure
                $NewIntPtr = New-Object System.Intptr -ArgumentList $Offset
                
                $obj = New-Object -TypeName psobject
                $obj | Add-Member -MemberType NoteProperty -Name DfsName -Value $DfsName
                
                # grab the appropriate result structure
                Switch ($Level) {
                    1
                    {
                        $DfsInfo = $NewIntPtr -as $DFS_INFO_1
                            
                        $obj | Add-Member -MemberType NoteProperty -Name EntryPath -Value $DfsInfo.EntryPath
                    }
                    2
                    {
                        $DfsInfo = $NewIntPtr -as $DFS_INFO_2
                            
                        $obj | Add-Member -MemberType NoteProperty -Name EntryPath -Value $DfsInfo.EntryPath
                        $obj | Add-Member -MemberType NoteProperty -Name Comment -Value $DfsInfo.Comment
                        $obj | Add-Member -MemberType NoteProperty -Name State -Value ([DFS_VOLUME_STATE]$DfsInfo.State)
                        $obj | Add-Member -MemberType NoteProperty -Name NumberOfStorages -Value $DfsInfo.NumberOfStorages
                    }
                    3
                    {
                        $DfsInfo = $NewIntPtr -as $DFS_INFO_3
                            
                        $obj | Add-Member -MemberType NoteProperty -Name EntryPath -Value $DfsInfo.EntryPath
                        $obj | Add-Member -MemberType NoteProperty -Name Comment -Value $DfsInfo.Comment
                        $obj | Add-Member -MemberType NoteProperty -Name State -Value ([DFS_VOLUME_STATE]$DfsInfo.State)
                        $obj | Add-Member -MemberType NoteProperty -Name NumberOfStorages -Value $DfsInfo.NumberOfStorages

                        $StorageOffset = $DfsInfo.Storage.ToInt64()
                        $StorageIncrement = $DFS_STORAGE_INFO::GetSize()
                        $storageList = New-Object -TypeName System.Collections.ArrayList

                        for($j = 1; $j -le $DfsInfo.NumberOfStorages; $j++)
                        {
                            $StoragePtr = New-Object -TypeName System.IntPtr -ArgumentList $StorageOffset
                           
                            $Storage = $StoragePtr -as $DFS_STORAGE_INFO

                            $storageObj = New-Object -TypeName psobject
                            $storageObj | Add-Member -MemberType NoteProperty -Name State -Value ([DFS_STORAGE_STATE]$Storage.State)
                            $storageObj | Add-Member -MemberType NoteProperty -Name ServerName -Value $Storage.ServerName
                            $storageObj | Add-Member -MemberType NoteProperty -Name ShareName -Value $Storage.ShareName

                            $storageList.Add($storageObj) | Out-Null

                            $StorageOffset += $StorageIncrement
                        }

                        $obj | Add-Member -MemberType NoteProperty -Name Storage -Value $storageList.ToArray()
                    }
                    5
                    {
                        $DfsInfo = $NewIntPtr -as $DFS_INFO_5
                            
                        $obj | Add-Member -MemberType NoteProperty -Name EntryPath -Value $DfsInfo.EntryPath
                        $obj | Add-Member -MemberType NoteProperty -Name Comment -Value $DfsInfo.Comment
                        $obj | Add-Member -MemberType NoteProperty -Name State -Value ([DFS_VOLUME_STATE]$DfsInfo.State)
                        $obj | Add-Member -MemberType NoteProperty -Name Timeout -Value $DfsInfo.Timeout
                        $obj | Add-Member -MemberType NoteProperty -Name Guid -Value $DfsInfo.Guid
                        $obj | Add-Member -MemberType NoteProperty -Name PropertyFlags -Value $DfsInfo.PropertyFlags
                        $obj | Add-Member -MemberType NoteProperty -Name MetadataSize -Value $DfsInfo.MetadataSize
                        $obj | Add-Member -MemberType NoteProperty -Name NumberOfStorages -Value $DfsInfo.NumberOfStorages
                    }
                    6
                    {
                        $DfsInfo = $NewIntPtr -as $DFS_INFO_6
                            
                        $obj | Add-Member -MemberType NoteProperty -Name EntryPath -Value $DfsInfo.EntryPath
                        $obj | Add-Member -MemberType NoteProperty -Name Comment -Value $DfsInfo.Comment
                        $obj | Add-Member -MemberType NoteProperty -Name State -Value ([DFS_VOLUME_STATE]$DfsInfo.State)
                        $obj | Add-Member -MemberType NoteProperty -Name Timeout -Value $DfsInfo.Timeout
                        $obj | Add-Member -MemberType NoteProperty -Name Guid -Value $DfsInfo.Guid
                        $obj | Add-Member -MemberType NoteProperty -Name PropertyFlags -Value $DfsInfo.PropertyFlags
                        $obj | Add-Member -MemberType NoteProperty -Name MetadataSize -Value $DfsInfo.MetadataSize
                        $obj | Add-Member -MemberType NoteProperty -Name NumberOfStorages -Value $DfsInfo.NumberOfStorages

                        $StorageOffset = $DfsInfo.Storage.ToInt64()
                        $StorageIncrement = $DFS_STORAGE_INFO_1::GetSize()
                        $storageList = New-Object -TypeName System.Collections.ArrayList

                        for($j = 1; $j -le $DfsInfo.NumberOfStorages; $j++)
                        {
                            $StoragePtr = New-Object -TypeName System.IntPtr -ArgumentList $StorageOffset
                           
                            $Storage = $StoragePtr -as $DFS_STORAGE_INFO_1

                            $storageObj = New-Object -TypeName psobject
                            $storageObj | Add-Member -MemberType NoteProperty -Name State -Value ([DFS_STORAGE_STATE]$Storage.State)
                            $storageObj | Add-Member -MemberType NoteProperty -Name ServerName -Value $Storage.ServerName
                            $storageObj | Add-Member -MemberType NoteProperty -Name ShareName -Value $Storage.ShareName

                            $storageList.Add($storageObj) | Out-Null

                            $StorageOffset += $StorageIncrement
                        }

                        $obj | Add-Member -MemberType NoteProperty -Name Storage -Value $storageList.ToArray()
                    }
                    8
                    {
                        $DfsInfo = $NewIntPtr -as $DFS_INFO_8

                        $obj | Add-Member -MemberType NoteProperty -Name EntryPath -Value $DfsInfo.EntryPath
                        $obj | Add-Member -MemberType NoteProperty -Name Comment -Value $DfsInfo.Comment
                        $obj | Add-Member -MemberType NoteProperty -Name State -Value ([DFS_VOLUME_STATE]$DfsInfo.State)
                        $obj | Add-Member -MemberType NoteProperty -Name Timeout -Value $DfsInfo.Timeout
                        $obj | Add-Member -MemberType NoteProperty -Name Guid -Value $DfsInfo.Guid
                        $obj | Add-Member -MemberType NoteProperty -Name PropertyFlags -Value $DfsInfo.PropertyFlags
                        $obj | Add-Member -MemberType NoteProperty -Name MetadataSize -Value $DfsInfo.MetadataSize
                        $obj | Add-Member -MemberType NoteProperty -Name SecurityDescriptorLength -Value $DfsInfo.SecurityDescriptorLength
                        $obj | Add-Member -MemberType NoteProperty -Name NumberOfStorages -Value $DfsInfo.NumberOfStorages

                        if(IsValidSecurityDescriptor -SecurityDescriptor $DfsInfo.pSecurityDescriptor)
                        {
                            $obj | Add-Member -MemberType NoteProperty -Name SecurityDescriptor -Value (ConvertSecurityDescriptorToStringSecurityDescriptor -SecurityDescriptor $DfsInfo.pSecurityDescriptor)
                        }
                        else
                        {
                            $obj | Add-Member -MemberType NoteProperty -Name SecurityDescriptor -Value $null
                        }

                        $obj | Add-Member -MemberType NoteProperty -Name NumberOfStorages -Value $DfsInfo.NumberOfStorages
                    }
                    9
                    {
                        $DfsInfo = $NewIntPtr -as $DFS_INFO_9

                        $obj | Add-Member -MemberType NoteProperty -Name EntryPath -Value $DfsInfo.EntryPath
                        $obj | Add-Member -MemberType NoteProperty -Name Comment -Value $DfsInfo.Comment
                        $obj | Add-Member -MemberType NoteProperty -Name State -Value ([DFS_VOLUME_STATE]$DfsInfo.State)
                        $obj | Add-Member -MemberType NoteProperty -Name Timeout -Value $DfsInfo.Timeout
                        $obj | Add-Member -MemberType NoteProperty -Name Guid -Value $DfsInfo.Guid
                        $obj | Add-Member -MemberType NoteProperty -Name PropertyFlags -Value $DfsInfo.PropertyFlags
                        $obj | Add-Member -MemberType NoteProperty -Name MetadataSize -Value $DfsInfo.MetadataSize
                        $obj | Add-Member -MemberType NoteProperty -Name SecurityDescriptorLength -Value $DfsInfo.SecurityDescriptorLength

                        if(IsValidSecurityDescriptor -SecurityDescriptor $DfsInfo.pSecurityDescriptor)
                        {
                            $obj | Add-Member -MemberType NoteProperty -Name SecurityDescriptor -Value (ConvertSecurityDescriptorToStringSecurityDescriptor -SecurityDescriptor $DfsInfo.pSecurityDescriptor)
                        }
                        else
                        {
                            $obj | Add-Member -MemberType NoteProperty -Name SecurityDescriptor -Value $null
                        }

                        $obj | Add-Member -MemberType NoteProperty -Name NumberOfStorages -Value $DfsInfo.NumberOfStorages

                        $StorageOffset = $DfsInfo.Storage.ToInt64()
                        $StorageIncrement = $DFS_STORAGE_INFO_1::GetSize()
                        $storageList = New-Object -TypeName System.Collections.ArrayList
                        
                        for($j = 1; $j -le $DfsInfo.NumberOfStorages; $j++)
                        {
                            $StoragePtr = New-Object -TypeName System.IntPtr -ArgumentList $StorageOffset
                           
                            $Storage = $StoragePtr -as $DFS_STORAGE_INFO_1

                            $storageObj = New-Object -TypeName psobject
                            $storageObj | Add-Member -MemberType NoteProperty -Name State -Value ([DFS_STORAGE_STATE]$Storage.State)
                            $storageObj | Add-Member -MemberType NoteProperty -Name ServerName -Value $Storage.ServerName
                            $storageObj | Add-Member -MemberType NoteProperty -Name ShareName -Value $Storage.ShareName

                            $storageList.Add($storageObj) | Out-Null

                            $StorageOffset += $StorageIncrement
                        }

                        $obj | Add-Member -MemberType NoteProperty -Name Storage -Value $storageList.ToArray()
                    }
                }

                Write-Output $obj

                # return all the sections of the structure - have to do it this way for V2
                $Offset = $NewIntPtr.ToInt64()
                $Offset += $Increment
            }

            # free up the result buffer
            NetApiBufferFree -Buffer $Buffer
        }
        else {
            Write-Verbose "[NetDfsEnum] Error: $(([ComponentModel.Win32Exception] $Result).Message)"
        }
    }
}