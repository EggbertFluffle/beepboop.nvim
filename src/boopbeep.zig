// Written by Harrison DiAmbrosio
// hdiambrosio@gmail.com
// https://eggbert.xyz

const std = @import("std");

pub const ma = @cImport({
    @cInclude("miniaudio.h");
});

pub fn oomPanic() noreturn {
  std.log.err("Out of memory error, exiting with 1", .{});
  std.process.exit(1);
}

var stdin_buffer: [512]u8 = undefined;
var stdin_reader_wrapper: std.fs.File.Reader = undefined;
var stdin: *std.Io.Reader = undefined;

var stderr_buffer: [512]u8 = undefined;
var stderr_writer: std.fs.File.Writer = undefined;
var stderr: *std.Io.Writer = undefined;


const MAX_SOUNDS_DEFAULT: u32 = 15;

const Trigger = struct {
    sounds: std.ArrayList(std.ArrayList(*ma.ma_sound)) = undefined,

    pub fn init(self: *Trigger, allocator: std.mem.Allocator) void {
        // TODO: Make not a magic number
        self.sounds = std.ArrayList(std.ArrayList(*ma.ma_sound)).initCapacity(allocator, 16) catch { oomPanic(); }; 
    }

    pub fn deinit(self: *Trigger, allocator: std.mem.Allocator) void {
        for(self.sounds.items) |sound| {
            allocator.free(sound);
        }
    }

    pub fn set_volume(self: *Trigger, volume: f32) void {
        for (self.sounds.items) |sound| {
            for(sound.items) |s| {
                ma.ma_sound_set_volume(s, volume);
            }
        }
    }

    pub fn load_sound(self: *Trigger, file_path: []const u8, max_sounds: u32, engine: *ma.ma_engine, allocator: std.mem.Allocator) void {
        // Create sound arraylist
        
        errdefer oomPanic();
        
        // TODO: Remove magic number
        var sound = try std.ArrayList(*ma.ma_sound).initCapacity(allocator, 4);

        // File path should be checked already with the lua plugin
        const c_file_path = try std.fmt.allocPrintSentinel(allocator, "{s}", .{file_path}, 0);

        for(0..max_sounds) |_| {
            const audio: *ma.ma_sound = try allocator.create(ma.ma_sound);

            std.debug.print("{s}", .{c_file_path});
            const result = ma.ma_sound_init_from_file(engine, c_file_path, 0, null, null, audio);

            if(result != ma.MA_SUCCESS) {
                _ = try stderr.write(ma_get_error(result));
                return;
            }

            try sound.append(allocator, audio);
        }

        try self.sounds.append(allocator, sound);
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
};

pub fn main() void {
    var quit: bool = false;
    var mute: bool = false;

    // Initialize readers and writters for stderr and stdin
    stdin_reader_wrapper = std.fs.File.stdin().reader(&stdin_buffer);
    stdin = &stdin_reader_wrapper.interface;
    stderr_writer = std.fs.File.stderr().writer(&stderr_buffer);
    stderr = &stderr_writer.interface;

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
        const input = stdin.takeDelimiterExclusive('\n') catch {
            stderr.print("Failed to read argument list", .{}) catch {};
            continue;
        };

        const delimiter = [1]u8{' '};
        var args = std.mem.tokenizeSequence(u8, input, delimiter[0..]);
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
                _ = stderr.write("Incorrect use of \"load_sound\": usage $ load_sound <trigger_name> <file_path>") catch { oomPanic(); };
                continue;
            }

            if(max_sounds_arg != null) {
                max_sounds = std.fmt.parseInt(u32, max_sounds_arg.?, 10) catch MAX_SOUNDS_DEFAULT;
            }

            load_sound(trigger_name.?, file_path.?, max_sounds, &sound_map, &engine, allocator);
        } else if (std.mem.eql(u8, command.?, "play_sound")) {
            const trigger_name = args.next();

            if(trigger_name == null) {
                _ = stderr.write("Incorrect use of \"load_sound\": usage $ load_sound <trigger_name> <file_path>") catch { oomPanic(); };
                continue;
            }

            if(!mute) {
                play_sound(trigger_name.?, &sound_map, &rand);
            }
        } else if (std.mem.eql(u8, command.?, "master_volume")) {
            const vol_arg = args.next();

            if(vol_arg == null) {
                _ = stderr.write("Incorrect use of \"master_volume\": usage $ master_volume <volume 1-100>") catch { oomPanic(); };
                continue;
            }
            
            var volume: f32 = std.fmt.parseFloat(f32, vol_arg.?) catch 1.0;
            volume = if (volume > 1.0) 1.0 else (if (volume < 0.0) 0.0 else volume);

            if(ma.ma_engine_set_volume(&engine, volume) != ma.MA_SUCCESS) {
                _ = stderr.write("Volume unable to be set") catch { oomPanic(); };
                continue;
            }
        } else if (std.mem.eql(u8, command.?, "trigger_volume")) {
            const trigger_name = args.next();
            const vol_arg = args.next();

            if(trigger_name == null or vol_arg == null) {
                _ = stderr.write("Incorrect use of \"trigger_volume\": usage $ sound_volume <trigger_name> <volume 1-100>") catch { oomPanic(); };
                continue;
            }
            
            var volume: f32 = std.fmt.parseFloat(f32, vol_arg.?) catch 1.0;
            volume = if (volume > 1.0) 1.0 else (if (volume < 0.0) 0.0 else volume);

            var trigger = sound_map.get(trigger_name.?);
            if(trigger == null) {
                stderr.print("Sound \"{s}\" does not exist as a loaded sound", .{trigger_name.?}) catch { oomPanic(); };
            }

            trigger.?.set_volume(volume);
        } else if (std.mem.eql(u8, command.?, "mute")) {
            _ = stderr.write("Muting") catch { oomPanic(); };
            mute = true;
        } else if (std.mem.eql(u8, command.?, "unmute")) {
            _ = stderr.write("Unmuting") catch { oomPanic(); };
            mute = false;
        } else if (std.mem.eql(u8, command.?, "toggle_mute")) {
            _ = stderr.write("Toggling mute") catch { oomPanic(); };
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

    var triggers = sound_map.iterator();
    var next = triggers.next();

    while(next != null) {
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
            _ = stderr.write("Allocator error") catch { oomPanic(); };
        };
        break :blk sound_map.getPtr(trigger_name); 
    };

    sound.?.load_sound(file_path, max_sounds, engine, allocator);

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
