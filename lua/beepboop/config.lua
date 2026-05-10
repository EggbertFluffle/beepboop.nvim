---Used to validate configuration
local M = {}

local theme = require("beepboop.theme")

local utils = require("beepboop.utils")

---@class Config
---@field mute boolean
---@field binary_path string Path to boopbeep companion binary
---@field theme_directory string Where to look for and to download remote themes
---@field volume integer Master volume of BeepBoop
---@field theme string|Theme URL or file path to a theme directory containing a theme.json
---@field get_binary_method "none"|"build"|"download" How to get the binary if it doesn't exist
M.default_config = {
	mute = false,
	binary_path = "",
	theme_directory = vim.fs.joinpath(vim.fn.stdpath("data"), "beepboop", "themes"),
	volume = 100,
	get_binary_method = "none",
}

---Validate and correct any tolerable errors in the config
---@param config Config
M.validate = function (config)
	if config.theme == nil then
		error("[beepboop] No theme provided")
	end

	vim.validate({
		{ config.mute, "boolean" },
		{ config.binary_path, "string" },
		{ config.theme_directory, "string" },
		{ config.volume, "number" },
		{ config.theme, { "table", "string" } },
		{ config.get_binary_method, "string" }
	})

	theme.validate(config)
end

return M
