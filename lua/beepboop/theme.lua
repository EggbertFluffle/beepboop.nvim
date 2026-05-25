---Used to load, find, and validate themes

local utils = require("beepboop.utils")

local M = {}

---@class Theme
---@field sound_maps SoundMap[] Sound maps for the theme
---@field sound_directory string Directory to source sound files from
---@field max_sounds? integer The max number of sounds that can be played at once
---@field cooldown? integer The cooldown after an audio cue before it can play again, 0 indicated none
---@field name string
local default_theme = {
	name = "untitled",
	sound_directory = vim.fs.joinpath(vim.fn.stdpath("config"), "sounds"),
	max_sounds = 15,
	cooldown = 0
}

---@class KeyMap
---@field mode string
---@field keychord string
---@field blocking? boolean
local keymap = {}

---@class SoundMap
---@field autocommand? string
---@field trigger? string
---@field keymap? KeyMap
---@field sounds? string[]
---@field sound? string
---@field volume? integer
local sound_maps = {}

---@param theme Theme
local validate_sound_maps = function (theme)
	local trigger_count = 0

	for _, sound_map in ipairs(theme.sound_maps) do
		vim.validate({
			{ sound_map.autocommand, { "string", "nil" } },
			{ sound_map.trigger, { "string", "nil" } },
			{ sound_map.keymap, { "table", "nil" } },
			{ sound_map.sounds, { "table", "nil" } },
			{ sound_map.sound, { "string", "nil" } },
			{ sound_map.volume, { "number", "nil", } }
		})

		sound_map.volume = sound_map.volume or 100

		if sound_map.trigger == nil then
			sound_map.trigger = string.format("trigger%d", trigger_count)
			trigger_count = trigger_count + 1
		end

		sound_map.sounds = sound_map.sounds or {}
		if sound_map.sound then
			table.insert(sound_map.sounds, sound_map.sound)
			sound_map.sound = nil
		end

		for _, sound in ipairs(sound_map.sounds) do
			local sound_path = vim.fs.joinpath(theme.sound_directory, sound)
			if not vim.uv.fs_stat(sound_path) then
				error(string.format("Sound file \"%s\" either doesn't exist or is not readable", sound_path))
			end
		end

		if sound_maps.keymap then
			vim.validate({
				{ keymap.mode, "string" },
				{ keymap.keychord, "string" },
				{ keymap.blocking, { "boolean", "nil" } }
			})

			if keymap.blocking == nil then
				keymap.blocking = false
			end
		end
	end
end

---@param theme_directory string
---@return Theme
local load_local_theme = function (theme_directory)
	local theme_file = vim.fs.joinpath(theme_directory, "theme.lua")
	if not vim.uv.fs_stat(theme_file) then
		error(string.format("Cannot find file \"%s\"", theme_file))
	end

	local theme = loadfile(theme_file)()
	theme.sound_directory = vim.fs.joinpath(theme_directory, "sounds")
	return theme
end

---@param url string
---@param themes_directory string
---@return Theme
local load_remote_theme = function (url, themes_directory)
	-- Look for theme if it already exists
	local directory_name = utils.directory_name_from_remote_url(url)

	if not vim.uv.fs_stat(vim.fs.joinpath(themes_directory, directory_name)) then
		print(string.format("[beepboop] Cloning %s...", url))

		local result = vim.system({
			"git",
			"-c",
			"credential.helper=", -- Fails if not credentials
			"clone",
			url, vim.fs.joinpath(themes_directory, directory_name)
		}):wait()

		if result.code ~= 0 then
			error(string.format("[beepboop] Clone of %s could not be completed: \n%s", url, result.stderr))
		end
	end

	-- TODO: Check for updates via git fetch or smth

	return load_local_theme(vim.fs.joinpath(themes_directory, directory_name))
end

---Load validated sound files from config into companion
---@param theme Theme 
---@param companion Companion
M.load_sound_files = function(theme, companion)
	for _, sound_map in ipairs(theme.sound_maps) do
		for _, file_name in ipairs(sound_map.sounds) do
			local file_path = vim.fs.joinpath(theme.sound_directory, file_name)
			companion:send_command({ "load_sound", sound_map.trigger, file_path })
		end

		companion:send_command({ "trigger_volume", sound_map.trigger, tostring(sound_map.volume) })
	end
end

---@param config Config
M.validate = function (config)
	if type(config.theme) == "string" then -- Is a path or url and must be validated
		local theme_uri = config.theme --[[@as string]]

		if vim.uv.fs_stat(theme_uri) then
			config.theme = load_local_theme(theme_uri)
		elseif string.find(theme_uri, "[a-z]*://[^ >,;]*") ~= nil then -- Should be a url otherwise
			config.theme = load_remote_theme(theme_uri, config.theme_directory)
		else
			error(string.format("[beepboop] Theme %s is neither a valid directory or url", theme_uri))
		end
	end

	if not vim.uv.fs_stat(config.theme.sound_directory) then
		error(string.format("Sound directory \"%s\" is not a directory or is not readable", config.theme.sound_directory))
	end

	vim.validate({
		{ config.theme, "table" },
		{ config.theme.sound_maps, "table" } })
	config.theme = vim.tbl_deep_extend("force", default_theme, config.theme)

	validate_sound_maps(config.theme --[[@as Theme]])
end

return M
