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
	vim.print("executing " .. config.binary_path .. config.binary_name)
	self.handle, self.pid = vim.uv.spawn(config.binary_path .. config.binary_name,
		{
			stdio = { self.stdin , nil, self.stderr },
			detached = true
		}, function (code, signal)
			vim.print("exit code: " .. code)
			vim.print("exit signal: " .. signal)
		end)

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
	vim.print("Attempting to download binary")
	vim.print("well get there lol")
end

---@param config Config
local build_binary = function (config) 
	vim.print("Attempting to build binary")
	vim.print("well get there lol")
end

---@param config Config
M.validate = function (config)
	if vim.fn.executable(config.binary_path .. config.binary_name) == 0 then
		download_binary(config)
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
	vim.print("This is a test")
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

---Cleaup companion binary and related resources
---@param self Companion
M.cleanup = function (self)
	self:send_command("quit")
end

return M
