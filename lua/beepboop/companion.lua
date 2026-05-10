---Used to interface with the companion binary
---@module 'companion'

---@class Companion
---@field handle? uv.uv_process_t Libuv process handling the companion binary 
---@field pid? integer The PID of the companion binary
---@field stdin uv.uv_pipe_t? Pipe to companion binary stdin
---@field stderr uv.uv_pipe_t? Pipe to companion binary stderr
local M = {}

local utils = require("beepboop.utils")


---Initialize the companion binary
---@param self Companion
---@param config Config
M.initialize = function(self, config)
	self.stdin = vim.uv.new_pipe(false)
	self.stderr = vim.uv.new_pipe(false)

	-- Start the companion binary
	local binary = config.binary_path
	local handle, pid_or_err = vim.uv.spawn(binary,
		{
			stdio = {
				self.stdin,
				nil,
				self.stderr
			},
			detached = true
		},
		function (_, _)
		end
	)

	if not handle or not handle:is_active() then
		error("[beepboop] Starting companion failed: " .. pid_or_err --[[@as string]])
	end

	self.handle = handle
	self.pid = pid_or_err --[[@as integer]]

	self.stderr:read_start(function(_, chunk)
		-- vim.print(chunk)
	end)

	self:set_volume(config.volume)
	self:set_mute(config.mute)

	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = "beepboop_core",
		callback = function (_)
			self:send_command("quit")
		end
	})
end

---@param config Config
local download_binary = function(config)
	if vim.fn.executable("curl") == 0 then
		error("[beepboop] curl is required to download the companion binary")
	end

	local latest_tag = "test"
	local bin_name = "boopbeep-" .. utils.get_arch() .. "-" .. utils.get_os()

	if utils.get_os() == "windows" then
		bin_name = bin_name .. ".exe"
	end

	local download_url = string.format(
		"https://github.com/EggbertFluffle/boopbeep/releases/download/%s/%s",
		latest_tag, bin_name
	)

	local bin_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "beepboop", "bin")
	if not vim.fn.mkdir(bin_dir, "p") then
		error("[beepboop] Unable to make bin directory for binary download")
	end

	if vim.fn.executable(vim.fs.joinpath(bin_dir, bin_name)) == 0 then
		print(string.format("[beepboop] Downloading %s...", download_url))
		local curl_res = vim.system({ "curl", "-L", "-o", vim.fs.joinpath(bin_dir, bin_name), download_url }):wait()
		if curl_res.code ~= 0 then
			error(string.format("[beepboop] Failed to download binary: %s", curl_res.stderr))
		end

		-- Make it executable
		local chmod_res= vim.system({ "chmod", "+x", vim.fs.joinpath(bin_dir, bin_name)}):wait()
		if chmod_res.code ~= 0 then
			error("[beepboop] Failed to make binary executable: " .. chmod_res.stderr)
		end
	end

	config.binary_path = vim.fs.joinpath(bin_dir, bin_name)
end

---@param config Config
local build_binary = function (config)
	if vim.fn.executable("zig") == 0 then
		error("[beepboop] Trying to build companion, could not find zig")
	end

	if vim.fn.executable("git") == 0 then
		error("[beepboop] Trying to build companion, could not find git")
	end

	local zig_version_result = vim.system({ "zig", "version" }):wait()
	if zig_version_result.code ~= 0 then
		error("[beepboop] Could not find zig version: " .. zig_version_result.stderr)
	end
	local zig_version = vim.trim(zig_version_result.stdout)

	if zig_version ~= "0.16.0" then
		error("[beepboop] Zig version mismatch for build. Require 0.16.0, found " .. zig_version)
	end

	local beepboop_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "beepboop", "")
	if not vim.fn.mkdir(beepboop_dir, "p") then
		error("[beepboop] Unable to make source directory for binary")
	end

	local build_dir = vim.fs.joinpath(beepboop_dir, "boopbeep")

	-- Clone repository if it doesn't exist
	if vim.fn.isdirectory(build_dir) == 0 then
		local remote_url = "https://github.com/EggbertFluffle/boopbeep"

		print(string.format("[beepboop] Cloning %s...", remote_url))

		local result = vim.system({
			"git",
			"clone",
			"-c",
			"credential.helper=", -- Fail if no credentials
			remote_url,
			build_dir
		}):wait()

		if result.code ~= 0 then
			error(string.format("[beepboop] git clone failed: \n%s", result.stderr))
		end
	end

	local bin_path = vim.fs.joinpath(build_dir, "zig-out", "bin", "boopbeep")

	-- Build repository using zig if it isn't built
	if not vim.uv.fs_stat(bin_path) then
		print("[beepboop] Building boopbeep to " .. build_dir .. "...")
		local result = vim.system({ "zig", "build" }, { cwd = build_dir }):wait()
		if result.code ~= 0 then
			error(string.format("[beepboop] zig build failed: %s", result.stderr))
		end
	end

	config.binary_path = bin_path
end

---@param config Config
M.validate = function (config)
	if vim.fn.executable(config.binary_path) == 0 then
		if config.get_binary_method == "download" then
			download_binary(config)
		elseif config.get_binary_method == "build" then
			build_binary(config)
		elseif config.get_binary_method == "none" then
			if config.binary_path == "" or vim.fn.executable(config.binary_path) == 0 then
				error(string.format("[beepboop] No binary get method, and invalid path provided: %s", config.binary_path))
			end
		end
	end
end

---@param self Companion
---@param command string|string[] Command to send to companion binary
M.send_command = function (self, command)
	if type(command) == "table" then
		command = table.concat(command --[[@as string[] ]], " ")
	end

	self.stdin:write(command --[[@as string]] .. "\n")
end

---@param self Companion
---@param trigger_name string Name of sound trigger
M.play_sound = function (self, trigger_name)
	self:send_command({ "play_sound", trigger_name })
end

---@param self Companion
---@param volume integer
M.set_volume = function (self, volume)
	self:send_command({ "master_volume", tostring(volume) })
end

---@param self Companion
---@param mute boolean
M.set_mute = function (self, mute)
	if mute then
		self:send_command("mute")
	else
		self:send_command("unmute")
	end
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
