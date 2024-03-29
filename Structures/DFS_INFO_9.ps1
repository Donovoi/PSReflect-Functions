$DFS_INFO_9 = struct $Module DFS_INFO_9 @{
    EntryPath                = field 0 String -MarshalAs @('LPWStr')
    Comment                  = field 1 String -MarshalAs @('LPWStr')
    State                    = field 2 UInt32
    Timeout                  = field 3 UInt32
    Guid                     = field 4 Guid
    PropertyFlags            = field 5 UInt32
    MetadataSize             = field 6 UInt32
    SecurityDescriptorLength = field 7 UInt32
    pSecurityDescriptor      = field 8 IntPtr
    NumberOfStorages         = field 9 UInt32
    Storage                  = field 10 IntPtr
}