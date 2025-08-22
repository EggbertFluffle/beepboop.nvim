---Used to load, find, and validate themes
---@module 'theme'

local utils = require("beepboop.utils")
local path_seperator = utils.path_seperator

local M = {}

---@class Theme
---@field sound_maps SoundMap[] Sound maps for the theme
---@field sound_directory string Directory to source sound files from
---@field max_sounds? integer The max number of sounds that can be played at once
---@field cooldown? integer The cooldown after an audio cue before it can play again, 0 indicated none
local default_theme = {
	sound_directory = vim.fn.stdpath("config") .. path_seperator .. "sounds" .. path_seperator,
	max_sounds = 15,
	cooldown = 0
}

---@class KeyMap
---@field mode string
---@field key_chord string
---@field blocking? boolean
local key_map = {}

---@class SoundMap
---@field auto_command? string
---@field trigger_name? string
---@field key_map? KeyMap
---@field sounds? string[]
---@field sound? string
---@field volume? integer
local sound_maps = {}

---@param theme Theme
local validate_sound_maps = function (theme)
	local trigger_count = 0

	for _, sound_map in ipairs(theme.sound_maps) do
		vim.validate({
			{ sound_map.auto_command, { "string", "nil" } },
			{ sound_map.trigger_name, { "string", "nil" } },
			{ sound_map.key_map, { "table", "nil" } },
			{ sound_map.sounds, { "table", "nil" } },
			{ sound_map.sound, { "string", "nil" } },
			{ sound_map.volume, { "number", "nil", } }
		})

		sound_map.volume = sound_map.volume or 100

		if sound_map.trigger_name == nil then
			sound_map.trigger_name = string.format("trigger%d", trigger_count)
			trigger_count = trigger_count + 1
		end

		sound_map.sounds = sound_map.sounds or {}
		if sound_map.sound then
			table.insert(sound_map.sounds, sound_map.sound)
			sound_map.sound = nil
		end

		for _, sound in ipairs(sound_map.sounds) do
			local sound_path = theme.sound_directory .. sound
			assert(vim.fn.filereadable(sound_path) == 1, "Sound file \"%s\" either doesn't exist or is not readable")
		end

		if sound_maps.key_map then
			vim.validate({
				{ key_map.mode, "string" },
				{ key_map.key_chord, "string" },
				{ key_map.blocking, { "boolean", "nil" } } })

			if key_map.blocking == nil then
				key_map.blocking = false
			end
		end
	end
end

---@param theme_directory string
---@return Theme
local load_local_theme = function (theme_directory)
	assert(
		vim.fn.filereadable(theme_directory .. "theme.json") == 1,
		string.format("File theme.json not found found or readable in path \"%s\"", theme_directory))

	return utils.read_json(theme_directory .. "theme.json")
end

---@param url string
---@param themes_directory string
---@return Theme
local load_remote_theme = function (url, themes_directory)
	-- Look for theme if it already exists
	local folder = utils.folder_from_remote_repo(url)

	if vim.fn.isdirectory(themes_directory .. folder) == 0 then
		local output = vim.fn.system(string.format("git clone %s %s", url, themes_directory .. folder))

		if vim.v.shell_error ~= 0 then
			error(string.format("Clone of %s could not be completed: %s", url, output))
		end
	end

	-- TODO: Check for updates via git fetch or smth

	return load_local_theme(themes_directory .. folder .. path_seperator)
end

---@param config Config
M.validate = function (config)
	if type(config.theme) == "string" then -- Is a path or url and must be validated
		local theme_uri = config.theme --[[@as string]]

		if vim.fn.isdirectory(theme_uri) == 1 then

			config.theme = load_local_theme(theme_uri .. path_seperator)
			config.theme.sound_directory = theme_uri .. string.format("%ssounds%s", path_seperator, path_seperator)
		elseif string.find(theme_uri, "[a-z]*://[^ >,;]*") ~= nil then -- Should be a url otherwise
			-- TODO: Implement remote themes
			config.theme = load_remote_theme(theme_uri, config.theme_directory)
		else
			error(string.format("Theme %s is neither a valid directory or url", theme_uri))
		end
	end

	vim.validate({
		{ config.theme, "table" },
		{ config.theme.sound_maps, "table" } })
	config.theme = vim.tbl_deep_extend("force", default_theme, config.theme)

	assert(
		vim.fn.isdirectory(config.theme.sound_directory) == 1,
		string.format("Sound directory \"%s\" is not a directory or is not readable", config.theme.sound_directory))

	local last_seperator = string.sub(config.theme.sound_directory, -1)
	if last_seperator ~= path_seperator then
		config.theme.sound_directory = config.theme.sound_directory .. path_seperator
	end

	validate_sound_maps(config.theme --[[@as Theme]])
end

return M
