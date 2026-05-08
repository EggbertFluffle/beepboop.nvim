const std = @import("std");
const ma = @import("c.zig").ma;

const Utils = @import("Utils.zig");

pub fn oomPanic() noreturn {
  std.log.err("Out of memory error, exiting with 1", .{});
  std.process.exit(1);
}

const Trigger = @This();

sounds: std.ArrayList(std.ArrayList(*ma.ma_sound)) = undefined,

pub fn init(allocator: std.mem.Allocator) *Trigger {
    errdefer oomPanic();

    const self = try allocator.create(Trigger);
    self.sounds = try std.ArrayList(std.ArrayList(*ma.ma_sound)).initCapacity(allocator, 16); 
    return self;
}

pub fn deinit(self: *Trigger, allocator: std.mem.Allocator) void {
    for(self.sounds.items) |sound| {
        allocator.free(sound);
    }
    allocator.free(self);
}

pub fn set_volume(self: *Trigger, volume: f32) void {
    for (self.sounds.items) |sound| {
        for(sound.items) |s| {
            ma.ma_sound_set_volume(s, volume);
        }
    }
}

pub fn load_sound(
    self: *Trigger,
    file_path: []const u8,
    max_sounds: u32,
    engine: *ma.ma_engine,
    stderr: *std.Io.Writer,
    allocator: std.mem.Allocator
) void {
    errdefer oomPanic();

    var sound = try std.ArrayList(*ma.ma_sound).initCapacity(allocator, 4);

    // File path should be checked already with the lua plugin
    const c_file_path = try std.fmt.allocPrintSentinel(allocator, "{s}", .{file_path}, 0);

    for(0..max_sounds) |_| {
        const audio: *ma.ma_sound = try allocator.create(ma.ma_sound);

        std.debug.print("file_path: '{s}'", .{c_file_path});
        const result = ma.ma_sound_init_from_file(engine, c_file_path, 0, null, null, audio);

        if(result != ma.MA_SUCCESS) {
            _ = try stderr.write(Utils.ma_get_error(result));
            return;
        }

        try sound.append(allocator, audio);
    }

    try self.sounds.append(allocator, sound);
}

pub fn play_sound(self: *const Trigger, rand: *const std.Random, stderr: *std.Io.Writer) void {
    const rand_index: usize = rand.intRangeLessThan(usize, 0, self.sounds.items.len) ;
    const sound: std.ArrayList(*ma.ma_sound) = self.sounds.items[rand_index];

    std.debug.print("Playing sound deeper\n", .{});

    for(sound.items) |s| {
        const sound_c_ptr: [*c]ma.ma_sound = @ptrCast(s);

        if(ma.ma_sound_is_playing(sound_c_ptr) == ma.MA_FALSE) {
            std.debug.print("Playing sound deepest\n", .{});
            if(ma.ma_sound_start(sound_c_ptr) != ma.MA_SUCCESS) {
                stderr.print("Failed to play sound\n", .{}) catch {};
            } else {
                break;
            }
        }
    }
}

pub fn is_playing(self: *const Trigger) bool {
    for(self.sounds.items) |sound| {
        for(sound.items) |s| {
            const sound_c_ptr: [*c]ma.ma_sound = @ptrCast(s);

            if(ma.ma_sound_is_playing(sound_c_ptr) == ma.MA_TRUE) {
                return true;
            }
        }
    }

    return false;
}
