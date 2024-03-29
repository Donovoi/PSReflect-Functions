$DFS_INFO_2 = struct $Module DFS_INFO_2 @{
    EntryPath        = field 0 String -MarshalAs @('LPWStr')
    Comment          = field 1 String -MarshalAs @('LPWStr')
    State            = field 2 UInt32
    NumberOfStorages = field 3 UInt32
}