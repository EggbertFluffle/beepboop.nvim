// Written by Harrison DiAmbrosio
// hdiambrosio@gmail.com
// https://eggbert.xyz

const std = @import("std");
const Trigger = @import("Trigger.zig");
const ma = @import("c.zig").ma;

pub fn oomPanic() noreturn {
  std.log.err("Out of memory error, exiting with 1", .{});
  std.process.exit(1);
}

var stdin_reader: std.Io.File.Reader = undefined;
var stdin_buffer: [512]u8 = undefined;
var stdin: *std.Io.Reader = undefined;

var stderr_writer: std.Io.File.Writer = undefined;
var stderr_buffer: [512]u8 = undefined;
var stderr: *std.Io.Writer = undefined;

const MAX_SOUNDS_DEFAULT: u32 = 15;
const NO_INPUT_SLEEP_TIME_MS: i64 = 100;

pub fn main(init: std.process.Init) void {
    defer oomPanic();

    const allocator = init.gpa;
    const io = init.io;

    var quit: bool = false;
    var mute: bool = false;

    // Initialize readers and writters for stderr and stdin
    stdin_reader = std.Io.File.stdin().reader(init.io, &stdin_buffer);    
    stdin = &stdin_reader.interface;

    stderr_writer = std.Io.File.stderr().writer(init.io, &stderr_buffer);
    stderr = &stderr_writer.interface;

    // Create the pseudo random number generator
    var prng = blk: {
        const timestamp = std.Io.Timestamp.now(io, .real);
        break :blk std.Random.DefaultPrng.init(@intCast(timestamp.toMilliseconds()));
    };
    const rand = prng.random();


    // Create the audio engine and it's configuration
    var engine: ma.ma_engine = undefined;
    var engine_config: ma.ma_engine_config = ma.ma_engine_config_init();
    engine_config.channels = 32;

    if (0 != ma.ma_engine_init(&engine_config, &engine)) {
        stderr.print("Failed to initialize miniaudio engine\n", .{}) catch {};
        std.process.exit(1);
    }

    var sound_map: std.StringHashMap(*Trigger) = std.StringHashMap(*Trigger).init(allocator);

    // Or if a sound is still playing
    while (!quit) {
        const input = stdin.takeDelimiterExclusive('\n') catch {
            io.sleep(.fromMilliseconds(NO_INPUT_SLEEP_TIME_MS), .real) catch {};
            continue;
        };

        // Discard the trailing \n
        _ = stdin.discard(.limited(1)) catch unreachable;

        var args = std.mem.tokenizeSequence(u8, input, &.{' '});
        const command = args.next();

        if(command == null) {
            stderr.print("No command provided, try \"load_sound\" or \"play_sound\"\n", .{}) catch {};
            continue;
        }

        if(std.mem.eql(u8, command.?, "load_sound")) {
            const trigger_name = args.next();
            const file_path = args.next();
            const max_sounds_arg = args.next();
            var max_sounds: u32 = MAX_SOUNDS_DEFAULT;

            // Probably a better way to validate input
            if(trigger_name == null or file_path == null) {
                _ = stderr.write("Incorrect use of \"load_sound\": usage $ load_sound <trigger_name> <file_path>") catch {};
                continue;
            }

            if(max_sounds_arg) |msa| {
                max_sounds = std.fmt.parseInt(u32, msa, 10) catch MAX_SOUNDS_DEFAULT;
            }

            load_sound(trigger_name.?, file_path.?, max_sounds, &sound_map, &engine, allocator);
        } else if (std.mem.eql(u8, command.?, "play_sound")) {
            const trigger_name = args.next();

            if(trigger_name == null) {
                _ = stderr.write("Incorrect use of \"play_sound\": usage $ play_sound <trigger_name>") catch { };
                continue;
            }

            if(!mute) {
                play_sound(trigger_name.?, &sound_map, &rand);
            }
        } else if (std.mem.eql(u8, command.?, "master_volume")) {
            const vol_arg = args.next();

            if(vol_arg == null) {
                _ = stderr.write("Incorrect use of \"master_volume\": usage $ master_volume <volume 1-100>") catch { };
                continue;
            }
            
            var volume: f32 = std.fmt.parseFloat(f32, vol_arg.?) catch 1.0;
            volume = if (volume > 1.0) 1.0 else (if (volume < 0.0) 0.0 else volume);

            if(ma.ma_engine_set_volume(&engine, volume) != ma.MA_SUCCESS) {
                _ = stderr.write("Volume unable to be set") catch { };
                continue;
            }
        } else if (std.mem.eql(u8, command.?, "trigger_volume")) {
            const trigger_name = args.next();
            const vol_arg = args.next();

            if(trigger_name == null or vol_arg == null) {
                _ = stderr.write("Incorrect use of \"trigger_volume\": usage $ sound_volume <trigger_name> <volume 1-100>") catch { };
                continue;
            }
            
            var volume: f32 = std.fmt.parseFloat(f32, vol_arg.?) catch 1.0;
            volume = if (volume > 1.0) 1.0 else (if (volume < 0.0) 0.0 else volume);

            var trigger = sound_map.get(trigger_name.?);
            if(trigger == null) {
                stderr.print("Sound \"{s}\" does not exist as a loaded sound", .{trigger_name.?}) catch { };
            }

            trigger.?.set_volume(volume);
        } else if (std.mem.eql(u8, command.?, "mute")) {
            _ = stderr.write("Muting") catch { };
            mute = true;
        } else if (std.mem.eql(u8, command.?, "unmute")) {
            _ = stderr.write("Unmuting") catch { };
            mute = false;
        } else if (std.mem.eql(u8, command.?, "toggle_mute")) {
            _ = stderr.write("Toggling mute") catch { };
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

    std.process.exit(0);
}

pub fn load_sound(
    trigger_name: []const u8, 
    file_path: []const u8, 
    max_sounds: u32,
    sound_map: *std.StringHashMap(*Trigger),
    engine: *ma.ma_engine,
    allocator: std.mem.Allocator
) void {
    errdefer oomPanic();

    const sound = sound_map.get(trigger_name) orelse blk: {
        const trigger = Trigger.init(allocator);
        try sound_map.put(trigger_name, trigger);
        break :blk sound_map.get(trigger_name); 
    };

    if(sound == null) return;

    sound.?.load_sound(file_path, max_sounds, engine, stderr, allocator);
}

pub fn play_sound(
    trigger_name: []const u8,
    sound_map: *std.StringHashMap(*Trigger),
    rand: *const std.Random
) void {
    const trigger = sound_map.get(trigger_name);
    std.debug.print("trigger is {s}\n", .{trigger_name});
    if(trigger != null) {
        std.debug.print("Playing sound deep\n", .{});
        trigger.?.play_sound(rand, stderr);
    }
}

