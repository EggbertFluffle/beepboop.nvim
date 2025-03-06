---Used to interface with the companion binary
---@module 'Companion'

---@class Companion
---@field handle uv.uv_process_t Libuv process handling the companion binary 
---@field pid integer The PID of the companion binary
---@field stdin uv.uv_pipe_t|nil Pipe to companion binary stdin
---@field stderr uv.uv_pipe_t|nil Pipe to companion binary stderr
---@field initialize fun(companion: Companion, config: Config) Start the companion binary
---@field cleanup fun(companion: Companion) Cleaup companion binary and related resources
---@field load_sound_files fun(companion: Companion, config: Config) Load the sound files spesified in config sound_map
---@field play_sound fun(companion: Companion, trigger_name: string) Send the binary a trigger to play a sound from
local M = {}

---@param companion Companion
---@param config Config
---@return nil
M.initialize = function(companion, config)
	companion.stdin = vim.uv.new_pipe(false)
	M.stderr = vim.uv.new_pipe(false)

	companion.handle, companion.pid = vim.uv.spawn(config.binary_path, {
			stdio = { companion.stdin , nil, companion.stderr },
			detached = true
		},
		function (_, _)
			companion:cleanup()
		end
	)

	vim.api.nvim_create_autocmd("ExitPre", {
		group = "beepboop",
		callback = function (_)
			companion:play_sound("chestopen")
			companion:cleanup()
		end
	})
end

M.load_sound_files = function(companion, config)
	assert(companion.handle:is_active(), "Companion binary handle is not active!\n")

	for _, sound_map in ipairs(config.sound_maps) do
		for _, file_name in ipairs(sound_map.sounds) do
			local command = string.format(
				"load_sound %s %s\n",
				sound_map.trigger_name,
				config.sound_directory .. file_name)
			M.stdin:write(command)
		end
	end
end

M.play_sound = function (companion, trigger_name)
	local command = "play_sound " .. trigger_name .. "\n"
	companion.stdin:write(command)
end

M.cleanup = function (companion)
	companion.stdin:write("quit\n")
end

return M
