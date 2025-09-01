// Written by Harrison DiAmbrosio
// hdiambrosio@gmail.com
// https://eggbert.xyz

const std = @import("std");

pub const ma = @cImport({
    @cInclude("miniaudio.h");
});

// System globals
const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();
const stderr = std.io.getStdErr().writer();

const MAX_SOUNDS_DEFAULT: u32 = 15;

const Trigger = struct {
    sounds: std.ArrayList(std.ArrayList(*ma.ma_sound)) = undefined,

    pub fn init(self: *Trigger, allocator: std.mem.Allocator) void {
        self.sounds = std.ArrayList(std.ArrayList(*ma.ma_sound)).init(allocator);
    }

    pub fn deinit(self: *Trigger, allocator: std.mem.Allocator) void {
        for(self.sounds.items) |sound| {
            allocator.free(sound);
        }
    }

    pub fn load_sound(self: *Trigger, file_path: []const u8, max_sounds: u32, engine: *ma.ma_engine, allocator: std.mem.Allocator) !void {
        // Create sound arraylist
        var sound = std.ArrayList(*ma.ma_sound).init(allocator);

        // File path should be checked already with the lua plugin
        const c_file_path = try std.fmt.allocPrintZ(allocator, "{s}", .{file_path});

        for(0..max_sounds) |_| {
            const audio: *ma.ma_sound = try allocator.create(ma.ma_sound);

            const result = ma.ma_sound_init_from_file(engine, c_file_path, 0, null, null, audio);

            if(result != ma.MA_SUCCESS) {
                _ = stderr.write(ma_get_error(result)) catch {};
                return;
            }

            try sound.append(audio);
        }

        try self.sounds.append(sound);
    }

    pub fn play_sound(self: *const Trigger, rand: *const std.Random) void {
        const rand_index: usize = rand.intRangeLessThan(usize, 0, self.sounds.items.len) ;
        const sound: std.ArrayList(*ma.ma_sound) = self.sounds.items[rand_index];

        for(sound.items) |s| {
            const sound_c_ptr: [*c]ma.ma_sound = @ptrCast(s);
            
            if(ma.ma_sound_is_playing(sound_c_ptr) == ma.MA_FALSE) {
                if(ma.ma_sound_start(sound_c_ptr) != ma.MA_SUCCESS) {
                    stderr.print("Failed to play sound\n", .{}) catch {};
                } else {
                    break;
                }
            }
        }
    }

    pub fn is_playing(self: *const Trigger) bool {
        for(self.sounds) |sound| {
            for(sound.items) |s| {
                const sound_c_ptr: [*c]ma.ma_sound = @ptrCast(s);

                if(ma.ma_sound_is_playing(sound_c_ptr) == ma.MA_TRUE) {
                    return true;
                }
            }
        }

        return false;
    }
};

pub fn main() void {
    var quit: bool = false;
    var mute: bool = false;

    // Create the pseudo random number generator
    var prng = std.Random.DefaultPrng.init(@as(u64, @intCast(std.time.microTimestamp())));
    const rand = prng.random();

    // Create the allocator for the program
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // Create the audio engine and it's configuration
    var engine: ma.ma_engine = undefined;
    var engine_config: ma.ma_engine_config = ma.ma_engine_config_init();
    engine_config.channels = 32;

    if (0 != ma.ma_engine_init(&engine_config, &engine)) {
        stderr.print("Failed to initialize miniaudio engine\n", .{}) catch {};
        std.process.exit(1);
    }

    var sound_map: std.StringHashMap(Trigger) = std.StringHashMap(Trigger).init(allocator);

    // Or if a sound is still playing
    while (!quit) {
        var input_buffer: [512]u8 = [_]u8{0} ** 512;
        const input = stdin.readUntilDelimiterOrEof(input_buffer[0..], '\n') catch {
            stderr.print("Failed to read argument list", .{}) catch {};
            continue;
        };

        if (input == null) {
            stderr.print("Failed to read argument list", .{}) catch {};
            continue;
        }

        const delimiter = [1]u8{' '};
        var args = std.mem.tokenizeSequence(u8, input.?, delimiter[0..]);
        const command = args.next();

        if(command == null) {
            stderr.print("Incorrect use of \"load_sound\": usage $ load_sound <trigger_name> <file_path>", .{}) catch {};
            continue;
        }

        if(std.mem.eql(u8, command.?, "load_sound")) {
            const trigger_name = args.next();
            const file_path = args.next();
            const max_sounds_arg = args.next();
            var max_sounds: u32 = MAX_SOUNDS_DEFAULT;

            // Probably a better way to validate input
            if(trigger_name == null or file_path == null) {
                stderr.print("Incorrect use of \"load_sound\": usage $ load_sound <trigger_name> <file_path>", .{}) catch {};
                continue;
            }

            if(max_sounds_arg != null) {
                max_sounds = std.fmt.parseInt(u32, max_sounds_arg.?, 10) catch MAX_SOUNDS_DEFAULT;
            }

            load_sound(trigger_name.?, file_path.?, max_sounds, &sound_map, &engine, allocator);
        } else if (std.mem.eql(u8, command.?, "play_sound")) {
            const trigger_name = args.next();

            if(trigger_name == null) {
                stderr.print("Incorrect use of \"load_sound\": usage $ load_sound <trigger_name> <file_path>", .{}) catch {};
                continue;
            }

            if(true) {
                play_sound(trigger_name.?, &sound_map, &rand);
            }
        } else if (std.mem.eql(u8, command.?, "mute")) {
            mute = true;
        } else if (std.mem.eql(u8, command.?, "unmute")) {
            mute = false;
        } else if (std.mem.eql(u8, command.?, "toggle_mute")) {
            mute = !mute;
        } else if (std.mem.eql(u8, command.?, "quit")) {
            quit = true;
        }

        // IMPORTANT
        // Use this to reduce the performance impact
        // Use this to reduce the performance impact
        // Use this to reduce the performance impact
        // Use this to reduce the performance impact
        // Use this to reduce the performance impact
        // look into better solution though
        // std.time.sleep(1 * std.time.ns_per_s);
    }

    const triggers = sound_map.iterator();
    var next = triggers.next();

    while(next.? != null) {
        while(next.?.value_ptr.is_playing()) {
            // Sleep for 1s
            std.Thread.sleep(1_000_000_000);
        }
        next = triggers.next();
    }

    std.process.exit(0);
}

pub fn load_sound(trigger_name: []const u8, file_path: []const u8, max_sounds: u32, sound_map: *std.StringHashMap(Trigger), engine: *ma.ma_engine, allocator: std.mem.Allocator) void {
    const sound = sound_map.getPtr(trigger_name) orelse blk: {
        var trigger = Trigger{};
        trigger.init(allocator);
        sound_map.put(trigger_name, trigger) catch {
            stderr.print("Allocator error", .{}) catch {};
        };
        break :blk sound_map.getPtr(trigger_name); 
    };

    sound.?.load_sound(file_path, max_sounds, engine, allocator) catch {};

    // Take in a max sounds
}

pub fn play_sound(trigger_name: []const u8, sound_map: *std.StringHashMap(Trigger), rand: *const std.Random) void {
    const trigger = sound_map.get(trigger_name);
    if(trigger != null) {
        trigger.?.play_sound(rand);
    }
}

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
