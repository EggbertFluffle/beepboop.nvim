---Used to interface with the companion binary
---@module 'Companion'

---@class Companion
---@field initialize fun(companion: Companion, config: Config)
---@field load_sound_files fun(companion: Companion, config: Config)
---@field play_sound fun(companion: Companion, trigger_name: string)
---@field job_id integer
---@field on_stdout fun(channel_id: integer, data: string[], stream_name: string)
---@field on_stderr fun(channel_id: integer, data: string[], stream_name: string)
---@field on_exit fun(job_id: integer, exit_code: integer, event_type: string)
local M = {}

M.on_stdout = function (_, data, _)
	-- vim.print(data)
end

M.on_stderr = function (_, data, _)
	vim.print(data)
end

---@param companion Companion
---@param config Config
---@return nil
M.initialize = function(companion, config)
	companion.job_id = vim.fn.jobstart({config.binary_path}, { on_stdout = companion.on_stdout,
		on_stderr = companion.on_stderr,
		on_exit = companion.on_exit
	})
end

M.load_sound_files = function(companion, config)
	assert(companion.job_id, "[BEEPBOOP] Companion binary has not been started!")

	for _, sound_map in ipairs(config.sound_map) do
		for _, file_name in ipairs(sound_map.sounds) do
			local command = "load_sound " ..
				sound_map.trigger_name ..
				" " ..
				config.sound_directory ..
				file_name ..
				"\n";
			vim.fn.chansend(companion.job_id, command)
		end
	end
end

M.play_sound = function (companion, trigger_name)
	vim.fn.chansend(companion.job_id,
		"play_sound " ..
		trigger_name ..
		"\n")
end

M.on_exit = function (job_id, exit_code, event_type)
	vim.fn.jobstop(job_id)
end

return M
