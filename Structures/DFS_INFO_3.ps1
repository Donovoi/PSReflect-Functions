$DFS_INFO_3 = struct $Module DFS_INFO_3 @{
    EntryPath        = field 0 String -MarshalAs @('LPWStr')
    Comment          = field 1 String -MarshalAs @('LPWStr')
    State            = field 2 UInt32
    NumberOfStorages = field 3 UInt32
    Storage          = field 4 IntPtr
}