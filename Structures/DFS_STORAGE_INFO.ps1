$DFS_STORAGE_INFO = struct $Module DFS_STORAGE_INFO @{
    State      = field 0 UInt64
    ServerName = field 1 String -MarshalAs @('LPWStr')
    ShareName  = field 2 String -MarshalAs @('LPWStr')
}