#! /bin/lua

os.execute("zig build")

local test = io.popen("echo 'load_sound co /home/eggbert/programs/lua/beepboop.nvim/chestopen.wav' | ./zig-out/bin/boopbeep-x86-linux")
