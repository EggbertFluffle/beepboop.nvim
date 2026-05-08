const std = @import("std");
const ma = @import("c.zig").ma;

pub const Utils = @This();

pub fn ma_get_error(result: ma.ma_result) []const u8 {
    return switch (result) {
        ma.MA_INVALID_ARGS => "Error: Invalid arguments\n",
        ma.MA_INVALID_OPERATION => "Error: Invalid operation\n",
        ma.MA_OUT_OF_MEMORY => "Error: Out of memory\n",
        ma.MA_IO_ERROR => "Error: I/O error\n",
        ma.MA_ACCESS_DENIED => "Error: Access denied\n",
        ma.MA_DOES_NOT_EXIST => "Error: Resource does not exist\n",
        ma.MA_ALREADY_EXISTS => "Error: Resource already exists\n",
        ma.MA_TOO_MANY_OPEN_FILES => "Error: Too many open files\n",
        ma.MA_INVALID_FILE => "Error: Invalid file\n",
        ma.MA_TOO_BIG => "Error: Too big\n",
        ma.MA_PATH_TOO_LONG => "Error: Path too long\n",
        ma.MA_NAME_TOO_LONG => "Error: Name too long\n",
        ma.MA_NOT_DIRECTORY => "Error: Not a directory\n",
        ma.MA_IS_DIRECTORY => "Error: Is a directory\n",
        ma.MA_DIRECTORY_NOT_EMPTY => "Error: Directory not empty\n",
        ma.MA_AT_END => "Error: End of file\n",
        ma.MA_NO_SPACE => "Error: No space\n",
        ma.MA_BUSY => "Error: Device or resource busy\n",
        ma.MA_DEVICE_NOT_INITIALIZED => "Error: Device not initialized\n",
        ma.MA_DEVICE_ALREADY_INITIALIZED => "Error: Device already initialized\n",
        ma.MA_DEVICE_NOT_STARTED => "Error: Device not started\n",
        ma.MA_DEVICE_TYPE_NOT_SUPPORTED => "Error: Device type not supported\n",
        else => "Unknown error\n"
    };
}
