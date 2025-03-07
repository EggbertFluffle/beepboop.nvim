---Used to validate configuration
---@module 'beepboop.config'
local M = {}

---@class KeyMap
---@field mode string
---@field key_chord string
---@field blocking boolean
local key_map = {}

---@class SoundMap
---@field auto_command? string
---@field trigger_name? string
---@field key_map? KeyMap
---@field sounds? string[]
---@field sound? string
local sound_maps = {}

---@class Config
---@field enabled? boolean
---@field max_sounds? number The maximum number of sounds that can play at once
---@field sound_directory? string Directory that contains all the sound files for sound_maps
---@field sound_maps? (SoundMap?)[]
---@field binary_path? string Path to boopbeep companion binary
---@field volume? integer Master volume of BeepBoop
M.default_config = {
	enabled = true,
	max_sounds = 20,
	volume = 100,
	sound_directory = vim.fn.stdpath("config") .. "/sounds/",
	sound_maps = {},
	binary_path = vim.fn.stdpath("data") .. "/beepboop/bin/boopbeep" -- TODO: Change to a default location
}

---@param config Config
M.validate_sound_maps = function (config)
	local trigger_count = 0

	for _, sound_map in ipairs(config.sound_maps) do
		if sound_map.trigger_name == nil then
			sound_map.trigger_name = string.format("main:trigger%d", trigger_count)
			trigger_count = trigger_count + 1
		end

		vim.validate({
			{ sound_map.auto_command, { "string", "nil" } },
			{ sound_map.key_map, { "table", "nil"} },
			{ sound_map.sound, { "string", "nil" } },
			{ sound_map.sounds, { "table", "nil" } },
		})

		if sound_map.key_map then
			if sound_map.key_map.blocking == nil then sound_map.key_map.blocking = false end
			vim.validate({
				{ sound_map.key_map.mode, "string" },
				{ sound_map.key_map.key_chord, "string" }
			})
		end

		--- Turn a single sound into a list
		if (not sound_map.sounds or #(sound_map.sounds) == 0) and sound_map.sound then
			sound_map.sounds = { sound_map.sound }
		elseif not sound_map.sounds then
			error(string.format("No sound files given for trigger: %s", sound_map.trigger_name))
		end

		--- Ensure all sound files exist and are readable
		for _, sound_file in ipairs(sound_map.sounds) do
			local path = config.sound_directory .. sound_file
			assert(vim.fn.filereadable(path), string.format("File %s is not readable", path))
		end
	end
end

---@param sound_file_path string
M.validate_sound_file = function (sound_file_path)
	vim.fn.filereadable(sound_file_path)
end

---Validate and correct any tolerable errors in the config
---@param config Config
M.validate_config = function (config)
	vim.validate({
		{config.binary_path, "string"},
		{config.sound_directory, "string"},
		{config.enabled, "boolean"},
		{config.max_sounds, "number"},
		{config.sound_maps, "table"}
	})

	M.validate_sound_maps(config)
end

return M
