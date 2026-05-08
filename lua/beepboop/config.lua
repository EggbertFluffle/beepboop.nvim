---Used to validate configuration
local M = {}

local theme = require("beepboop.theme")

local utils = require("beepboop.utils")

---@class Config
---@field enabled boolean
---@field binary_path ?string Path to boopbeep companion binary
---@field theme_directory string Where to look for and to download remote themes
---@field volume integer Master volume of BeepBoop
---@field theme string|Theme URL or file path to a theme directory containing a theme.json
---@field get_binary_method "none"|"build"|"download" How to get the binary if it doesn't exist
M.default_config = {
	enabled = true,
	volume = 100,
	binary_name = nil,
	binary_path = vim.fs.joinpath(vim.fn.stdpath("data"), "beepboop", "bin"),
	theme_directory = vim.fs.joinpath(vim.fn.stdpath("data"), "beepboop", "themes")
}

---Validate and correct any tolerable errors in the config
---@param config Config
M.validate = function (config)
	vim.validate({
		{ config.binary_path, "string" },
		{ config.enabled, "boolean" },
		{ config.theme, { "table", "string" } },
		{ config.theme_directory, "string" },
		{ config.get_binary_method, "string" }
	})

	theme.validate(config)
end

return M
