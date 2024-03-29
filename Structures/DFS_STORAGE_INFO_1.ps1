$DFS_STORAGE_INFO_1 = struct $Module DFS_STORAGE_INFO_1 @{
    State          = field 0 UInt64
    ServerName     = field 1 String -MarshalAs @('LPWStr')
    ShareName      = field 2 String -MarshalAs @('LPWStr')
    TargetPriority = field 3 IntPtr
}