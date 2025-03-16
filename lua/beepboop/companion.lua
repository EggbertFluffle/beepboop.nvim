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
			"set_sound_volume %s %d\n",
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

	self.handle, self.pid = vim.uv.spawn(config.binary_path, {
			stdio = { self.stdin , nil, self.stderr },
			detached = true
		},
		function (_, _)
			self:cleanup()
		end)

	assert(self.handle and self.handle:is_active(), "Companion binary could not be started!")

	load_sound_files(self, config.theme --[[@as Theme]])
	self:set_volume(config.volume)

	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = "beepboop_core",
		callback = function (_)
			self:cleanup()
		end
	})
end

---@param config Config
local download_binary = function (config)
	
end

---@param config Config
M.validate = function (config)
	if vim.fn.executable(config.binary_path) == 0 then
		if vim.fn.executable("boopbeep") == 1 then
			config.binary_path = "boopbeep"
		else
			download_binary(config)
		end
	end
end

---@param self Companion
---@param trigger_name string Name of sound trigger
M.play_sound = function (self, trigger_name)
	local command = "play_sound " .. trigger_name .. "\n"
	self.stdin:write(command)
end

---@param self Companion
---@param volume integer
M.set_volume = function (self, volume)
	local command = string.format("set_master_volume %d\n", volume)
	self.stdin:write(command)
end

---Cleaup companion binary and related resources
---@param self Companion
M.cleanup = function (self)
	self.stdin:write("quit\n")
end

return M
