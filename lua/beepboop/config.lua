---Used to validate configuration
---@module 'config'
local M = {}

local theme = require("beepboop.theme")

local utils = require("beepboop.utils")
local path_seperator = utils.path_seperator

---@class Config
---@field enabled boolean
---@field binary_path string Path to boopbeep companion binary
---@field theme_directory string Where to look for and to download remote themes
---@field volume integer Master volume of BeepBoop
---@field theme string|Theme URL or file path to a theme directory containing a theme.json
M.default_config = {
	enabled = true,
	volume = 100,
	binary_path = vim.fn.stdpath("data") .. string.format("%sbeepboop%sbin%sboopbeep", path_seperator, path_seperator, path_seperator),
	theme_directory = vim.fn.stdpath("data") .. string.format("%sbeepboop%sthemes%s", path_seperator, path_seperator, path_seperator),
}

---Validate and correct any tolerable errors in the config
---@param config Config
M.validate = function (config)
	vim.validate({
		{ config.binary_path, "string" },
		{ config.enabled, "boolean" },
		{ config.theme, { "table", "string" } },
		{ config.theme_directory, "string" }
	})

	theme.validate(config)
end

return M
