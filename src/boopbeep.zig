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

var quit: bool = false;

const Trigger = struct {
    files: std.ArrayList([]const u8),
    sounds: std.ArrayList(*ma.ma_sound)
};

// var sound_map: std.StringHashMap(Trigger) = undefined;

pub fn main() void {
    
    // Create the pseudo random number generator
    const prng = std.Random.DefaultPrng.init(blk: {
        var seed = undefined;
        std.posix.getrandom(std.mem.asBytes(&seed)) catch |err| {
            _ = stderr.print("Failed to get random seed: {s}\n", .{err});
            std.process.exit(1);
        };
        break :blk seed;
    });
    const rand = prng.random();
    _ = rand;

    // Create the allocator for the program
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    _ = allocator;

    // Create the engine and it's configuration
    var engine: ma.ma_engine = undefined;
    var engine_config: ma.ma_engine_config = ma.ma_engine_config_init();
    engine_config.channels = 32;

    if (0 != ma.ma_engine_init(&engine_config, &engine)) {
        _ = stderr.print("Failed to initialize miniaudio engine\n", .{});
        std.process.exit(1);
    }

    // Or if a sound is still playing
    while (!quit) {
        const input_buffer: [256]u8 = [_]u8{0} * 256;
        stdin.readUntilDelimiterOrEof(input_buffer, '\n');

        var args: std.mem.SplitIterator = std.mem.splitSequence(u8, input_buffer, [1]u8{' '});
        const command = args.first();

        if(std.mem.eql(u8, command, "load_sound")) {
            load_sound();
        }

        // Use this to reduce the performance impact
        // look into better solution though
        std.time.sleep(1 * std.time.ns_per_s);
    }

    std.process.exit(0);
}

pub fn load_sound(trigger_name: []const u8, file_path: []const u8, sound_map: *std.StringHashMap(Trigger), allocator: *std.mem.Allocator) !void {
    _ = trigger_name;
    _ = file_path;
    _ = sound_map;
    _ = allocator;
    // Verify inputs
    // Find or insert into sound_map
    // Load the sound and populate the trigger
    // Take in a max sounds
}

// int play_sound(const std::string& trigger_name, std::unordered_map<std::string, Trigger>& sound_map,
// std::chrono::time_point<std::chrono::steady_clock>& last_master_time) {
pub fn play_sound(trigger_name: []const u8, file_path: []const u8, sound_map: *std.StringHashMap(Trigger), allocator: *std.mem.Allocator) !void {
    _ = trigger_name;
    _ = file_path;
    _ = sound_map;
    _ = allocator;
}

// pub fn set_master_volume(volume: f32, sound_map: *std.StringHashMap(Trigger)) !void {}
// pub fn set_sound_volume(trigger_name: []const u8, volume: f32, sound_map: *std.StringHashMap(Trigger)) !void {}

// var sound: ma.ma_sound = undefined;
// if (ma.MA_SUCCESS != ma.ma_sound_init_from_file(&engine, "./src/chestopen.wav", 0, null, null, &sound)) {
//     _ = stderr.print("Failed to initialize miniaudio sound\n", .{});
//     std.process.exit(1);
//     return;
// }
// defer ma.ma_sound_uninit(&sound);
//
// ma.ma_sound_is_playing(&sound);
//
// if (ma.MA_SUCCESS != ma.ma_sound_start(&sound)) {
//     _ = stderr.write("Failed to start miniaudio sound\n");
//     std.process.exit(1);
//     _ = stdout.write("This happened after the process exit");
//     return;
// }

