---Used to interface with the companion binary
---@module 'companion'

---@class Companion
---@field handle uv.uv_process_t Libuv process handling the companion binary 
---@field pid integer The PID of the companion binary
---@field stdin uv.uv_pipe_t|nil Pipe to companion binary stdin
---@field stderr uv.uv_pipe_t|nil Pipe to companion binary stderr
local M = {}

local utils = require("beepboop.utils")

---Load validated sound files from config into companion
---@param self Companion
---@param theme Theme 
local load_sound_files = function(self, theme)
	assert(self.handle:is_active(), "Companion binary handle is not active!\n")

	for _, sound_map in ipairs(theme.sound_maps) do
		for _, file_name in ipairs(sound_map.sounds) do
			local command = string.format(
				"load_sound %s %s\n",
				sound_map.trigger_name,
				theme.sound_directory .. file_name)
			M.stdin:write(command)
		end

		local command = string.format(
			"trigger_volume %s %d\n",
			sound_map.trigger_name,
			128 * (sound_map.volume / 100)
		)
		M.stdin:write(command)
	end
end

---Intialize the companion binary
---@param self Companion
---@param config Config
M.initialize = function(self, config)
	self.stdin = vim.uv.new_pipe(false)
	self.stderr = vim.uv.new_pipe(false)

	-- Start the companion binary
	local binary = vim.fs.joinpath(config.binary_path, config.binary_name)
	local handle, pid_or_err = vim.uv.spawn(binary,
		{
			stdio = {
				self.stdin,
				nil,
				self.stderr
			},
			detached = true
		},
		function (code, signal)
			vim.print("exit code: " .. code)
			vim.print("exit signal: " .. signal)
		end
	)

	if not handle then
		error("[beepboop] Starting companion failed: " .. pid_or_err --[[@as string]])
	end

	self.handle = handle
	self.pid = pid_or_err --[[@as integer]]

	self.stderr:read_start(function(_, chunk)
		-- vim.print(chunk, 0)
	end)

	assert(self.handle and self.handle:is_active(), "Companion binary could not be started!")

	load_sound_files(self, config.theme --[[@as Theme]])
	self:set_volume(config.volume)

	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = "beepboop_core",
		callback = function (_)
			self:send_command("quit")
		end
	})
end

---@param config Config
local download_binary = function (config)
	vim.print("how are we getting here")
	vim.print("Attempting to download binary")
	vim.print("well get there lol")
end

---@param config Config
local build_binary = function (config)
	if vim.fn.executable("zig") == 0 then
		error("[beepboop] Trying to build companion, could not find zig")
	end

	if vim.fn.executable("git") == 0 then
		error("[beepboop] Trying to build companion, could not find git")
	end

	local zig_version_cmd, errmsg = vim.fn.system({"zig", "version"})
	if not zig_version_cmd then
		error("[beepboop] Could not find zig version: " .. errmsg)
	end
	local zig_version = zig_version_cmd:read("*l")
	zig_version_cmd:close()

	if zig_version ~= "0.16.0" then
		error("[beepboop] Zig version mismatch for build. Require 0.16.0, found " .. zig_version)
	end

	local beepboop_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "beepboop", "")
	local ok = vim.fn.mkdir(beepboop_dir, "p")
	if not ok then
		error("[beepboop] Unable to make source directory for binary")
	end

	local build_dir = vim.fs.joinpath(beepboop_dir, "boopbeep")

	-- Clone repository if it doesn't exist
	if vim.fn.isdirectory(build_dir) == 0 then
		local remote_url = "https://github.com/EggbertFluffle/boopbeep"

		print(string.format("[beepboop] Cloning %s...", remote_url))

		local result = vim.system({ "git", "clone", remote_url, build_dir }):wait()
		if result.code ~= 0 then
			error(string.format("[beepboop] git clone failed: %s", result.stderr))
		end
	end

	local path = vim.fs.joinpath(build_dir, "zig-out", "bin")
	local name = "boopbeep"

	-- Build repository using zig if it isn't built
	if not vim.fn.fs_stat(vim.fs.joinpath(path, name)) then
		print("[beepboop] Building boopbeep to " .. build_dir .. "...")
		local result = vim.system({ "zig", "build" }, { cwd = build_dir }):wait()
		if result.code ~= 0 then
			error(string.format("[beepboop] zig build failed: %s", result.stderr))
		end
	end

	config.binary_path = path
	config.binary_name = name
end

---@param config Config
M.validate = function (config)
	if config.binary_name == nil then
		local full_name = "boopbeep-" .. utils.get_arch() .. "-" .. utils.get_os()
		if vim.fn.executable(vim.fs.joinpath(config.binary_path, full_name)) == 0 then
			config.binary_name = full_name
		elseif vim.fn.executable(vim.fs.joinpath(config.binary_path, "beepboop")) == 0 then
			config.binary_name = "beepboop"
		end
	end

	if vim.fn.executable(vim.fs.joinpath(config.binary_path, config.binary_name)) == 0 then
		if config.get_binary_method == "download" then
			download_binary(config)
		elseif config.get_binary_method == "build" then
			build_binary(config)
		elseif config.get_binary_method == "none" then
			error("[beepboop] Companion not found. Get companion method nil")
		end
	end
end

---@param self Companion
---@param command string Command to send to companion binary
M.send_command = function (self, command)
	self.stdin:write(command .. "\n")
end

---@param self Companion
---@param trigger_name string Name of sound trigger
M.play_sound = function (self, trigger_name)
	self:send_command("play_sound " .. trigger_name)
end

---@param self Companion
---@param volume integer
M.set_volume = function (self, volume)
	local command = string.format("set_master_volume %d", volume)
	self:send_command(command)
end

---@param self Companion
M.mute = function(self)
	self:send_command("mute")
end

---@param self Companion
M.unmute = function(self)
	self:send_command("unmute")
end

---@param self Companion
M.toggle_mute = function(self)
	self:send_command("toggle_mute")
end

---Cleanup companion binary and related resources
---@param self Companion
M.cleanup = function (self)
	self:send_command("quit")
end

return M
