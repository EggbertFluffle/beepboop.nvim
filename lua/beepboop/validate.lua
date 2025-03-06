---TODO: validate that that each sound map gets a trigger name
---TODO: all sound maps get a list of sounds
---Used to validate configuration and binary
---@module 'validate'

local M = {}

---@param config Config
---@return SoundMap[] Validated sound maps
M.validate_sound_maps = function (config) local trigger_count = 0
	local key_map_modes = { " ", "n", "v", "s", "x", "o", "!", "i", "l", "c", "t" }

	for i, sound_map in ipairs(config.sound_maps) do
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
			vim.validate({
				{ sound_map.key_map.mode, key_map_modes, "string" },
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

		config.sound_maps[i] = sound_map
	end

	return config
end

---@param binary_path string
M.validate_binary_install = function (binary_path)
	if not vim.fn.executable(binary_path) then
		-- TODO install binary to that or some other path
	end
end

---@param sound_file_path string
M.validate_sound_file = function (sound_file_path)
	vim.fn.filereadable(sound_file_path)
end

---Validate and correct any tolerable errors in the config
---@param config Config
---@return Config 
M.validate_config = function (config)
	vim.validate({
		{config.binary_path, "string"},
		{config.sound_directory, "string"},
		{config.enabled, "boolean"},
		{config.max_sounds, "number"},
		{config.sound_maps, "table"}
	})

	config= M.validate_sound_maps(config)

	return config
end


return M
